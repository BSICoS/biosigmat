function [pxx, f] = nanpwelch(x, window, noverlap, nfft, fs, minDistance)
% NANPWELCH Compute Welch periodogram when signal has NaN segments
%
% This function computes the Welch power spectral density estimate for signals
% containing NaN values. It identifies continuous segments of valid data,
% optionally merges segments that are close together, interpolates missing
% values within segments, and averages the power spectral density across all
% valid segments.
%
% Inputs:
%   x - Input signal (numeric vector)
%   window - Window for segmentation (scalar window length or window vector)
%   noverlap - Number of overlapped samples (scalar)
%   nfft - Number of DFT points (scalar)
%   fs - Sample rate in Hz (scalar)
%   minDistance - Minimum distance between segments in samples (scalar, optional)
%
% Outputs:
%   pxx - Power spectral density estimate (column vector)
%   f - Frequency axis in Hz (column vector, optional)

% Argument validation
narginchk(5, 6);
nargoutchk(0, 2);

% Parse input arguments
parser = inputParser;
parser.FunctionName = 'nanpwelch';
addRequired(parser, 'x', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'window', @(x) isnumeric(x) && (isscalar(x) || isvector(x)) && ~isempty(x));
addRequired(parser, 'noverlap', @(x) isnumeric(x) && isscalar(x) && x >= 0);
addRequired(parser, 'nfft', @(x) isnumeric(x) && isscalar(x) && x > 0);
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);
addOptional(parser, 'minDistance', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 0));
parse(parser, x, window, noverlap, nfft, fs, minDistance);

x = parser.Results.x;
window = parser.Results.window;
noverlap = parser.Results.noverlap;
nfft = parser.Results.nfft;
fs = parser.Results.fs;
minDistance = parser.Results.minDistance;

% Ensure column vectors
x = x(:);
window = window(:);

% Determine window length
if isscalar(window)
    windowLength = window;
else
    windowLength = length(window);
end

% Find beginning and end indices of valid data segments
if ~isnan(x(1))
    segmentBeginIndices = [1; find(diff(~isnan(x)) > 0) + 1];
else
    segmentBeginIndices = find(diff(~isnan(x)) > 0) + 1;
end

if ~isnan(x(end))
    segmentEndIndices = [find(diff(~isnan(x)) < 0); length(x)];
else
    segmentEndIndices = find(diff(~isnan(x)) < 0);
end

% Process signal segments
[b, a] = butter(4, 0.04 * 2 / fs, 'high');
pxxSegments = [];
if ~isempty(segmentBeginIndices) || sum(isnan(x)) == length(x)
    % Merge segments if distance between them is less than minimum distance (only if specified)
    if ~isempty(minDistance) && length(segmentBeginIndices) > 1
        distanceBetweenSegments = segmentBeginIndices(2:end) - segmentEndIndices(1:end-1);
        mergeSegments = find(distanceBetweenSegments < minDistance);
        segmentBeginIndices(mergeSegments + 1) = [];
        segmentEndIndices(mergeSegments) = [];
    end

    numSegments = length(segmentBeginIndices);

    % Compute Welch periodogram for each segment
    for segmentIdx = 1:numSegments
        segment = x(segmentBeginIndices(segmentIdx):segmentEndIndices(segmentIdx));
        segmentLength = length(segment);

        % Check if segment is long enough and has valid data
        if segmentLength >= windowLength && sum(~isnan(segment)) >= windowLength
            % Interpolate missing values within the segment if needed
            if any(isnan(segment))
                validIndices = ~isnan(segment);
                sampleIndices = 1:segmentLength;
                interpolatedSegment = interp1(sampleIndices(validIndices), ...
                    segment(validIndices), sampleIndices, 'spline');
            else
                interpolatedSegment = segment;
            end

            % Apply high-pass filter
            filteredSegment = filtfilt(b, a, interpolatedSegment);

            % Compute Welch periodogram
            if nargout > 1
                [pxxSegments(:, segmentIdx), f] = pwelch(filteredSegment, window, ...
                    noverlap, nfft, fs); %#ok<*AGROW>
            else
                pxxSegments(:, segmentIdx) = pwelch(filteredSegment, window, ...
                    noverlap, nfft, fs);
            end
        else
            % Segment too short - fill with NaN
            pxxSegments(:, segmentIdx) = NaN(ceil(nfft / 2), 1);
        end
    end

    % Average power across all valid segments
    if ~isempty(pxxSegments) && any(sum(~isnan(pxxSegments), 1))
        pxx = mean(pxxSegments, 2, 'omitnan');
    else
        % All segments too short - return NaN result with proper frequency vector
        pxx = NaN(ceil(nfft / 2), 1);
        if nargout > 1
            [~, f] = pwelch(ones(length(x), 1), window, noverlap, nfft, fs);
        end
    end

else
    % No NaN segments - process entire signal
    filteredSignal = filtfilt(b, a, x);
    if nargout > 1
        [pxx, f] = pwelch(filteredSignal, window, noverlap, nfft, fs);
    else
        pxx = pwelch(filteredSignal, window, noverlap, nfft, fs);
    end
end

end
