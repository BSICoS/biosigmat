function refinedPositions = refinePeakPositions(signal, fs, candidatePositions, varargin)
% REFINEPEAKPOSITIONS Refines peak positions using high-resolution interpolation.
%
%   REFINEDPOSITIONS = REFINEPEAKPOSITIONS(SIGNAL, FS, CANDIDATEPOSITIONS)
%   refines the positions of peaks in CANDIDATEPOSITIONS (in seconds) by
%   interpolating SIGNAL at a higher sampling rate and searching for local
%   maxima within a refinement window. SIGNAL is the input signal (numeric vector),
%   FS is the sampling rate in Hz (positive scalar), and CANDIDATEPOSITIONS
%   contains the initial peak positions in seconds (numeric vector).
%
%   REFINEDPOSITIONS = REFINEPEAKPOSITIONS(..., 'Name', Value) specifies
%   additional parameters using name-value pairs:
%     'FsInterp'        - Interpolation sampling frequency in Hz (default: 1000)
%     'WindowWidth'     - Refinement window width in seconds (default: 0.030)
%     'SearchType'      - Type of extremum to search: 'max' or 'min' (default: 'max')
%
%   Example:
%     % Refine peak positions in a synthetic signal
%     fs = 1000;
%     t = (0:1/fs:1-1/fs)';
%     signal = sin(2*pi*5*t) + 0.1*randn(size(t));
%
%     % Initial coarse peak detection
%     [~, peaks] = findpeaks(signal);
%     candidatePositions = (peaks - 1) / fs;
%
%     % Refine positions using interpolation
%     refinedPositions = refinePeakPositions(signal, fs, candidatePositions);
%
%     % Refine with custom interpolation frequency
%     refinedPositions2 = refinePeakPositions(signal, fs, candidatePositions, ...
%         'FsInterp', 2000, 'WindowWidth', 0.050);
%
%     % Plot results
%     figure;
%     plot(t, signal, 'b');
%     hold on;
%     plot(candidatePositions, signal(peaks), 'ro', 'MarkerSize', 8);
%     plot(refinedPositions, interp1(t, signal, refinedPositions), 'g^', 'MarkerSize', 8);
%     legend('Signal', 'Original Peaks', 'Refined Peaks');
%
%   See also INTERP1, FINDPEAKS

% Check number of input and output arguments
narginchk(3, 9);
nargoutchk(0, 1);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'refinePeakPositions';
addRequired(parser, 'signal', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);
addRequired(parser, 'candidatePositions', @(x) isnumeric(x) && (isvector(x) || isempty(x)));
addParameter(parser, 'FsInterp', 1000, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'WindowWidth', 0.030, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'SearchType', 'max', @(x) ismember(lower(x), {'max', 'min'}));

parse(parser, signal, fs, candidatePositions, varargin{:});

signal = parser.Results.signal;
fs = parser.Results.fs;
candidatePositions = parser.Results.candidatePositions;
fsInterp = parser.Results.FsInterp;
windowWidth = parser.Results.WindowWidth;
searchType = parser.Results.SearchType;

% Ensure signal is a column vector
signal = signal(:);

% Handle empty input
if isempty(candidatePositions)
    refinedPositions = [];
    return;
end

% Remove NaN values
candidatePositions = candidatePositions(~isnan(candidatePositions));
if isempty(candidatePositions)
    refinedPositions = [];
    return;
end

% Calculate interpolation parameters
windowSamples = round(windowWidth * fsInterp);

% Create time vectors for interpolation
t = (0:length(signal)-1) / fs;
tInterp = (0:((length(signal)*fsInterp/fs)-1)) / fsInterp;

% Interpolate signal using spline interpolation
signalInterp = interp1(t, signal, tInterp, 'spline');

% Convert candidate positions to interpolated indices
candidateIndices = 1 + round(candidatePositions * fsInterp);
refinedPositions = nan(size(candidatePositions));

% Choose the appropriate search function
if strcmpi(searchType, 'max')
    searchFunc = @max;
else
    searchFunc = @min;
end

% Refine each candidate position
for ii = 1:length(candidateIndices)
    % Define search window
    searchStart = max(1, candidateIndices(ii) - windowSamples);
    searchEnd = min(length(signalInterp), candidateIndices(ii) + windowSamples);
    searchIndices = searchStart:searchEnd;

    % Find local extremum within the window
    [~, localExtremumIdx] = searchFunc(signalInterp(searchIndices));
    refinedIdx = searchStart + localExtremumIdx - 1;

    % Validate refined index and convert back to time
    if refinedIdx >= 1 && refinedIdx <= length(signalInterp)
        refinedPositions(ii) = tInterp(refinedIdx);
    else
        % Fallback to original position if refinement fails
        refinedPositions(ii) = candidatePositions(ii);
    end
end

end
