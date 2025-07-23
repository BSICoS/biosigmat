function varargout = nanpwelch(x, window, noverlap, nfft, fs, varargin)
% NANPWELCH Compute Welch periodogram when signal has NaN segments
%
% This function computes the Welch power spectral density estimate for signals
% containing NaN values. It trims NaN values at the beginning and end of the
% signal, interpolates small gaps (≤ maxgap), and splits the signal at
% large gaps (> maxgap). The power spectral density is computed for each
% valid segment and averaged across all segments.
%
% Inputs:
%   x - Input signal (numeric vector or matrix)
%   window - Window for segmentation (scalar window length or window vector)
%   noverlap - Number of overlapped samples (scalar)
%   nfft - Number of DFT points (scalar)
%   fs - Sample rate in Hz (scalar)
%   maxgap - Maximum gap length in samples to interpolate (scalar, optional)
%                  If empty or not provided, no interpolation is performed
%
% Outputs:
%   pxx - Power spectral density estimate
%         For vector input: column vector
%         For matrix input: matrix where each column contains the PSD of the corresponding input signal
%   f - Frequency axis in Hz (column vector, optional)
%   pxxSegments - Power spectral density for each segment (optional)
%                 For vector input: matrix where each column contains the PSD of one processed segment
%                 For matrix input: cell array where pxxSegments{i} contains the PSD segments for signal i

% Argument validation
narginchk(5, 6);
nargoutchk(0, 3);

% Parse input arguments
parser = inputParser;
parser.FunctionName = 'nanpwelch';
addRequired(parser, 'x', @(x) isnumeric(x) && ~isempty(x) && (isvector(x) || ismatrix(x)));
addRequired(parser, 'window', @(x) isnumeric(x) && (isscalar(x) || isvector(x)) && ~isempty(x));
addRequired(parser, 'noverlap', @(x) isnumeric(x) && isscalar(x) && x >= 0);
addRequired(parser, 'nfft', @(x) isnumeric(x) && isscalar(x) && x > 0);
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);
addOptional(parser, 'maxgap', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 0));

parse(parser, x, window, noverlap, nfft, fs, varargin{:});

% Additional validation: window size vs signal length
windowLength = getWindowLength(parser.Results.window);
if windowLength > size(x, 1)
    error('nanpwelch:windowTooLarge', ...
        'Window length (%d) cannot be larger than signal length (%d)', windowLength, size(x, 1));
end

x = parser.Results.x;
window = parser.Results.window;
noverlap = parser.Results.noverlap;
nfft = parser.Results.nfft;
fs = parser.Results.fs;
maxgap = parser.Results.maxgap;

window = window(:);
if isvector(x)
    x = x(:);
end

numSignals = size(x, 2);

% Pre-allocate results for efficiency
pxxAll = [];
f = [];
pxxSegmentsCells = cell(numSignals, 1);

% Process each signal and accumulate results
for signalIdx = 1:numSignals
    currentSignal = x(:, signalIdx);

    % Trim NaN values at the beginning and end of the signal
    trimmedSignal = trimnans(currentSignal);

    % Early return if all values are NaN
    if isempty(trimmedSignal)
        pxxSingle = [];
        fSingle = [];
        pxxSegmentsSingle = [];
        % Update frequency vector and accumulate results
        f = updateFrequencyVector(f, fSingle);
        pxxAll = [pxxAll, pxxSingle];
        pxxSegmentsCells{signalIdx} = pxxSegmentsSingle;
        continue;
    end

    % Early return if signal is too short after trimming
    if length(trimmedSignal) < windowLength
        warning('nanpwelch:signalTooShort', ...
            'Signal after trimming NaN values (%d samples) is shorter than window length (%d samples). Cannot compute PSD.', ...
            length(trimmedSignal), windowLength);
        pxxSingle = [];
        fSingle = [];
        pxxSegmentsSingle = [];
        % Update frequency vector and accumulate results
        f = updateFrequencyVector(f, fSingle);
        pxxAll = [pxxAll, pxxSingle];
        pxxSegmentsCells{signalIdx} = pxxSegmentsSingle;
        continue;
    end

    % Find NaN gaps in the trimmed signal
    nanIndices = isnan(trimmedSignal);

    % Handle signal without NaN gaps
    if ~any(nanIndices)
        [pxxSingle, fSingle] = pwelch(trimmedSignal, window, noverlap, nfft, fs);
        pxxSegmentsSingle = pxxSingle;  % Single segment case
        % Update frequency vector and accumulate results
        f = updateFrequencyVector(f, fSingle);
        pxxAll = [pxxAll, pxxSingle];
        pxxSegmentsCells{signalIdx} = pxxSegmentsSingle;
        continue;
    end

    % Process signal with NaN gaps
    processedSignal = trimmedSignal;

    % If maxgap is specified, interpolate small gaps
    if ~isempty(maxgap)
        % Find NaN sequences
        nanSeqStarts = find(diff([0; nanIndices]) > 0);
        nanSeqEnds = find(diff([nanIndices; 0]) < 0);

        % Interpolate gaps that are ≤ maxgap
        for i = 1:length(nanSeqStarts)
            gapLength = nanSeqEnds(i) - nanSeqStarts(i) + 1;
            if gapLength <= maxgap
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
    pxxSegmentsSingle = [];
    numValidSegments = 0;

    for i = 1:length(segmentStarts)
        segment = processedSignal(segmentStarts(i):segmentEnds(i));
        segmentLength = length(segment);

        % Check if segment is long enough for analysis
        if segmentLength >= windowLength
            % Compute Welch periodogram
            numValidSegments = numValidSegments + 1;
            [pxxSegmentsSingle(:, numValidSegments), fSingle] = pwelch(segment, window, ...
                noverlap, nfft, fs); %#ok<*AGROW>
        end
    end

    % Early return if no valid segments found
    if numValidSegments == 0
        warning('nanpwelch:noValidSegments', ...
            'All signal segments are shorter than window length (%d samples). Cannot compute PSD.', windowLength);
        pxxSingle = [];
        fSingle = [];
        pxxSegmentsSingle = [];
        % Update frequency vector and accumulate results
        f = updateFrequencyVector(f, fSingle);
        pxxAll = [pxxAll, pxxSingle];
        pxxSegmentsCells{signalIdx} = pxxSegmentsSingle;
        continue;
    end

    % Average power across all valid segments
    pxxSingle = mean(pxxSegmentsSingle, 2);

    % Update frequency vector and accumulate PSD results
    f = updateFrequencyVector(f, fSingle);
    pxxAll = [pxxAll, pxxSingle];

    % Store segment results in cell array
    pxxSegmentsCells{signalIdx} = pxxSegmentsSingle;
end

if nargout > 2
    if numSignals == 1
        % For single signal, return matrix
        pxxSegmentsAll = pxxSegmentsCells{1};
    else
        % For multiple signals, return cell
        pxxSegmentsAll = pxxSegmentsCells;
    end
else
    pxxSegmentsAll = [];
end

varargout = {pxxAll, f, pxxSegmentsAll};

end

function f = updateFrequencyVector(f, fSingle)
if isempty(f) && ~isempty(fSingle)
    f = fSingle;
end
end

function windowLength = getWindowLength(window)
if isscalar(window)
    windowLength = window;
else
    windowLength = length(window);
end
end