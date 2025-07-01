function [pxx, f, pxxSegments] = nanpwelch(x, window, noverlap, nfft, fs, maxGapLength)
% NANPWELCH Compute Welch periodogram when signal has NaN segments
%
% This function computes the Welch power spectral density estimate for signals
% containing NaN values. It trims NaN values at the beginning and end of the
% signal, interpolates small gaps (≤ maxGapLength), and splits the signal at
% large gaps (> maxGapLength). The power spectral density is computed for each
% valid segment and averaged across all segments.
%
% Inputs:
%   x - Input signal (numeric vector)
%   window - Window for segmentation (scalar window length or window vector)
%   noverlap - Number of overlapped samples (scalar)
%   nfft - Number of DFT points (scalar)
%   fs - Sample rate in Hz (scalar)
%   maxGapLength - Maximum gap length in samples to interpolate (scalar, optional)
%                  If empty or not provided, no interpolation is performed
%
% Outputs:
%   pxx - Power spectral density estimate (column vector)
%   f - Frequency axis in Hz (column vector, optional)
%   pxxSegments - Power spectral density for each segment (matrix, optional)
%                 Each column contains the PSD of one processed segment

% Argument validation
narginchk(5, 6);
nargoutchk(0, 3);

% Parse input arguments
parser = inputParser;
parser.FunctionName = 'nanpwelch';
addRequired(parser, 'x', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'window', @(x) isnumeric(x) && (isscalar(x) || isvector(x)) && ~isempty(x));
addRequired(parser, 'noverlap', @(x) isnumeric(x) && isscalar(x) && x >= 0);
addRequired(parser, 'nfft', @(x) isnumeric(x) && isscalar(x) && x > 0);
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);
addOptional(parser, 'maxGapLength', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 0));

parse(parser, x, window, noverlap, nfft, fs, maxGapLength);

% Additional validation: window size vs signal length
if isscalar(window)
    windowLength = window;
else
    windowLength = length(window);
end
if windowLength > length(x)
    error('nanpwelch:windowTooLarge', ...
        'Window length (%d) cannot be larger than signal length (%d)', windowLength, length(x));
end

x = parser.Results.x;
window = parser.Results.window;
noverlap = parser.Results.noverlap;
nfft = parser.Results.nfft;
fs = parser.Results.fs;
maxGapLength = parser.Results.maxGapLength;

% Ensure column vectors
x = x(:);
window = window(:);

% Determine window length
if isscalar(window)
    windowLength = window;
else
    windowLength = length(window);
end

% Trim NaN values at the beginning and end of the signal
firstValidIndex = find(~isnan(x), 1, 'first');
lastValidIndex = find(~isnan(x), 1, 'last');

if isempty(firstValidIndex)
    % All values are NaN - return NaN result
    pxx = NaN(ceil(nfft / 2), 1);
    if nargout > 1
        [~, f] = pwelch(ones(windowLength, 1), window, noverlap, nfft, fs);
    end
    if nargout > 2
        pxxSegments = [];
    end
    return;
end

% Trim the signal
x = x(firstValidIndex:lastValidIndex);

% Validate trimmed signal length against window
if length(x) < windowLength
    warning('nanpwelch:signalTooShort', ...
        'Signal after trimming NaN values (%d samples) is shorter than window length (%d samples). Cannot compute PSD.', ...
        length(x), windowLength);
    pxx = [];
    if nargout > 1
        f = [];
    end
    if nargout > 2
        pxxSegments = [];
    end
    return;
end

% Find NaN gaps in the trimmed signal
nanIndices = isnan(x);
if ~any(nanIndices)
    % No NaN values - process entire trimmed signal
    [b, a] = butter(4, 0.04 * 2 / fs, 'high');
    filteredSignal = filtfilt(b, a, x);
    if nargout > 1
        [pxx, f] = pwelch(filteredSignal, window, noverlap, nfft, fs);
    else
        pxx = pwelch(filteredSignal, window, noverlap, nfft, fs);
    end
    if nargout > 2
        pxxSegments = pxx;  % Single segment case
    end
    return;
end

% Process signal with NaN gaps
processedSignal = x;

% If maxGapLength is specified, interpolate small gaps
if ~isempty(maxGapLength)
    % Find NaN sequences
    nanSeqStarts = find(diff([0; nanIndices]) > 0);
    nanSeqEnds = find(diff([nanIndices; 0]) < 0);

    % Interpolate gaps that are ≤ maxGapLength
    for i = 1:length(nanSeqStarts)
        gapLength = nanSeqEnds(i) - nanSeqStarts(i) + 1;
        if gapLength <= maxGapLength
            % Get indices for interpolation (including boundary points)
            startIdx = max(1, nanSeqStarts(i) - 1);
            endIdx = min(length(processedSignal), nanSeqEnds(i) + 1);

            % Find valid data points around the gap
            validIndices = ~isnan(processedSignal(startIdx:endIdx));
            if sum(validIndices) >= 2
                % Interpolate using spline method
                validData = processedSignal(startIdx:endIdx);
                sampleIndices = 1:length(validData);
                interpolatedData = interp1(sampleIndices(validIndices), ...
                    validData(validIndices), sampleIndices, 'spline');
                processedSignal(startIdx:endIdx) = interpolatedData;
            end
        end
    end
end

% Find continuous segments of valid data after interpolation
validIndices = ~isnan(processedSignal);
segmentChanges = diff([0; validIndices; 0]);
segmentStarts = find(segmentChanges > 0);
segmentEnds = find(segmentChanges < 0) - 1;

% Compute Welch periodogram for each valid segment
pxxSegments = [];
numValidSegments = 0;

for i = 1:length(segmentStarts)
    segment = processedSignal(segmentStarts(i):segmentEnds(i));
    segmentLength = length(segment);

    % Check if segment is long enough for analysis
    if segmentLength >= windowLength
        % Compute Welch periodogram
        numValidSegments = numValidSegments + 1;
        if nargout > 1
            [pxxSegments(:, numValidSegments), f] = pwelch(segment, window, ...
                noverlap, nfft, fs); %#ok<*AGROW>
        else
            pxxSegments(:, numValidSegments) = pwelch(segment, window, ...
                noverlap, nfft, fs);
        end
    end
end

% Average power across all valid segments
if numValidSegments > 0
    pxx = mean(pxxSegments, 2);
    % Keep pxxSegments for third output if requested
else
    % No valid segments - return empty result and warn
    warning('nanpwelch:noValidSegments', ...
        'All signal segments are shorter than window length (%d samples). Cannot compute PSD.', windowLength);
    pxx = [];
    if nargout > 1
        f = [];
    end
    if nargout > 2
        pxxSegments = [];
    end
end

end
