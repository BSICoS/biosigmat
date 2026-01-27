function signalClean = expandnans(signal, fs, seconds)
% EXPANDNANS Expands NaN segments by a time window.
%
%   SIGNALCLEAN = EXPANDNANS(SIGNAL, FS, SECONDS) replaces samples with NaN
%   around existing NaN segments in SIGNAL. SIGNAL can be a vector or a
%   matrix; when it is a matrix, each column is treated as an independent
%   signal. FS is the sampling frequency in Hz (positive scalar). SECONDS is
%   the time window (in seconds, nonnegative scalar) to expand on each side
%   of every NaN segment.
%
%   Example:
%     % Expand NaNs by 0.5 seconds on each side
%     fs = 100;
%     t = (0:1/fs:10)';
%     signal = sin(2*pi*1*t);
%     signal(201:230) = NaN;
%     signalClean = expandnans(signal, fs, 0.5);
%
%     figure;
%     plot(t, signal, 'b'); hold on;
%     plot(t, signalClean, 'r');
%     legend('Original', 'Expanded NaNs');
%     title('EXPANDNANS example');
%
%   See also ISNAN, DIFF
%
%   Status: Beta


% Check number of input and output arguments
narginchk(3, 3);
nargoutchk(0, 1);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'expandnans';
addRequired(parser, 'signal', @(x) isnumeric(x) && ~isempty(x) && ismatrix(x));
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0);
addRequired(parser, 'seconds', @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0);
parse(parser, signal, fs, seconds);

signal = parser.Results.signal;
fs = parser.Results.fs;
seconds = parser.Results.seconds;

isVectorInput = isvector(signal);
isRowVectorInput = isrow(signal);
if isVectorInput
    signal = signal(:);
end

cleanWindow = round(fs * seconds);
signalClean = signal;

% Fast path: nothing to expand
if ~any(isnan(signalClean(:))) || cleanWindow == 0
    return;
end

% Process column-wise, preserving the input shape
for col = 1:size(signalClean, 2)
    colSignal = signalClean(:, col);

    if ~any(isnan(colSignal))
        continue;
    end

    nanIndices = isnan(colSignal);
    nanDiff = diff([false; nanIndices; false]);
    nanStart = find(nanDiff == 1);
    nanEnd = find(nanDiff == -1) - 1;
    nanSegments = [nanStart, nanEnd];

    nanSegments(:, 1) = max(1, nanSegments(:, 1) - cleanWindow);
    nanSegments(:, 2) = min(length(colSignal), nanSegments(:, 2) + cleanWindow);

    for segmentIndex = 1:size(nanSegments, 1)
        colSignal(nanSegments(segmentIndex, 1):nanSegments(segmentIndex, 2)) = NaN;
    end

    signalClean(:, col) = colSignal;
end

if isVectorInput && isRowVectorInput
    signalClean = signalClean.';
end

end