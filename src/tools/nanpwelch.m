function varargout = nanpwelch(x, window, noverlap, nfft, fs, varargin)
% NANPWELCH Compute Welch periodogram when signal has NaN segments.
%
%   PXX = NANPWELCH(X, WINDOW, NOVERLAP, NFFT, FS) computes the Welch power
%   spectral density estimate for signals containing NaN values. X is the input
%   signal (vector or matrix), WINDOW is the window for segmentation (scalar length
%   or window vector), NOVERLAP is the number of overlapped samples, NFFT is the
%   number of DFT points, and FS is the sample rate in Hz. It trims NaN values
%   at the beginning and end of the signal and splits the signal at large gaps.
%   The power spectral density is computed for each valid segment and averaged
%   across all segments. PXX is the power spectral density estimate.
%
%   PXX = NANPWELCH(..., MAXGAP) interpolates small gaps (≤ MAXGAP) before
%   computing the PSD. If MAXGAP is empty or not provided, no interpolation is performed.
%
%   [PXX, F] = NANPWELCH(...) also returns the frequency vector F in Hz.
%
%   [PXX, F, PXXSEGMENTS] = NANPWELCH(...) returns additional output:
%     PXXSEGMENTS - Power spectral density for each segment
%                   For vector input: matrix where each column contains the PSD of one segment
%                   For matrix input: cell array where PXXSEGMENTS{i} contains the PSD segments for signal i
%
%   Example:
%     % Compute Welch PSD for a signal with NaN gaps
%     fs = 1000;
%     t = 0:1/fs:1;
%     signal = sin(2*pi*50*t)' + 0.1*randn(length(t),1);
%     signal(100:150) = NaN;  % Add NaN gap
%
%     % Compute PSD with gap interpolation
%     [pxx, f] = nanpwelch(signal, 256, 128, 512, fs, 10);
%
%   See also PWELCH, PERIODOGRAM, TRIMNANS, INTERPGAP


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
fAll = [];
pxxSegmentsAllCells = cell(numSignals, 1);

% Process each signal and accumulate results
for signalIdx = 1:numSignals
    currentSignal = x(:, signalIdx);

    % Trim NaN values at the beginning and end of the signal
    trimmedSignal = trimnans(currentSignal);

    % Early return if all values are NaN
    if isempty(trimmedSignal)
        pxx = [];
        f = [];
        pxxSegments = [];

        % Update frequency vector and accumulate results
        fAll = updateFrequencyVector(fAll, f);
        pxxAll = [pxxAll, pxx]; %#ok<*AGROW>
        pxxSegmentsAllCells{signalIdx} = pxxSegments;
        continue;
    end

    % Early return if signal is too short after trimming
    if length(trimmedSignal) < windowLength
        warning('nanpwelch:signalTooShort', ...
            'Signal after trimming NaN values (%d samples) is shorter than window length (%d samples). Cannot compute PSD.', ...
            length(trimmedSignal), windowLength);
        pxx = [];
        f = [];
        pxxSegments = [];

        % Update frequency vector and accumulate results
        fAll = updateFrequencyVector(fAll, f);
        pxxAll = [pxxAll, pxx];
        pxxSegmentsAllCells{signalIdx} = pxxSegments;
        continue;
    end

    % Find NaN gaps in the trimmed signal
    nanIndices = isnan(trimmedSignal);

    % Handle signal without NaN gaps
    if ~any(nanIndices)
        slicedSignal = slicesignal(trimmedSignal, windowLength, noverlap, fs);
        if isscalar(window)
            [pxxSegments, f] = periodogram(slicedSignal, [], nfft, fs);
        else
            [pxxSegments, f] = periodogram(slicedSignal, window, nfft, fs);
        end

        % Average power across all segments
        pxx = mean(pxxSegments, 2);

        % Update frequency vector and accumulate results
        fAll = updateFrequencyVector(fAll, f);
        pxxAll = [pxxAll, pxx];
        pxxSegmentsAllCells{signalIdx} = pxxSegments;
        continue;
    end

    % If maxgap is specified, interpolate small gaps
    if ~isempty(maxgap)
        interpolatedSignal = interpgap(trimmedSignal, maxgap);
    end

    % Find continuous segments of valid data after interpolation
    validIndices = ~isnan(interpolatedSignal);
    segmentChanges = diff([0; validIndices; 0]);
    segmentStarts = find(segmentChanges > 0);
    segmentEnds = find(segmentChanges < 0) - 1;

    % Compute Welch periodogram for each valid segment
    pxxSegments = [];
    numValidSegments = 0;

    for i = 1:length(segmentStarts)
        segment = interpolatedSignal(segmentStarts(i):segmentEnds(i));
        segmentLength = length(segment);

        % Check if segment is long enough for analysis
        if segmentLength >= windowLength
            % Compute Welch periodogram
            slicedSegment = slicesignal(segment, windowLength, noverlap, fs);
            if isscalar(window)
                [pxxSegments(:, numValidSegments+1:numValidSegments+size(slicedSegment, 2)), f] = ...
                    periodogram(slicedSegment, [], nfft, fs);
            else
                [pxxSegments(:, numValidSegments+1:numValidSegments+size(slicedSegment, 2)), f] = ...
                    periodogram(slicedSegment, window, nfft, fs);
            end
            numValidSegments = numValidSegments + size(slicedSegment, 2);
        end
    end

    % Early return if no valid segments found
    if numValidSegments == 0
        warning('nanpwelch:noValidSegments', ...
            'All signal segments are shorter than window length (%d samples). Cannot compute PSD.', windowLength);
        pxx = [];
        f = [];
        pxxSegments = [];

        % Update frequency vector and accumulate results
        fAll = updateFrequencyVector(fAll, f);
        pxxAll = [pxxAll, pxx];
        pxxSegmentsAllCells{signalIdx} = pxxSegments;
        continue;
    end

    % Average power across all valid segments
    pxx = mean(pxxSegments, 2);

    % Update frequency vector and accumulate PSD results
    fAll = updateFrequencyVector(fAll, f);
    pxxAll = [pxxAll, pxx];

    % Store segment results in cell array
    pxxSegmentsAllCells{signalIdx} = pxxSegments;
end

if nargout > 2
    if numSignals == 1
        % For single signal, return matrix
        pxxSegmentsAll = pxxSegmentsAllCells{1};
    else
        % For multiple signals, return cell
        pxxSegmentsAll = pxxSegmentsAllCells;
    end
else
    pxxSegmentsAll = [];
end

varargout = {pxxAll, fAll, pxxSegmentsAll};

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