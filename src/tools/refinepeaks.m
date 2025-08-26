function refined = refinepeaks(signal, fs, candidates, varargin)
% REFINEPEAKS Refines peak positions using high-resolution interpolation.
%
%   REFINED = REFINEPEAKS(SIGNAL, FS, CANDIDATES)
%   refines the positions of peaks in CANDIDATES (in seconds) by
%   interpolating SIGNAL at a higher sampling rate and searching for local
%   maxima within a refinement window. SIGNAL is the input signal (numeric vector),
%   FS is the sampling rate in Hz (positive scalar), and CANDIDATES
%   contains the initial peak positions in seconds (numeric vector).
%
%   REFINED = REFINEPEAKS(..., 'Name', Value) specifies
%   additional parameters using name-value pairs:
%     'FsInterp'        - Interpolation sampling frequency in Hz (default: 1000)
%     'WindowWidth'     - Refinement window width in seconds (default: 0.030)
%
%   Example:
%     % Refine peak positions in a synthetic signal
%     fs = 1000;
%     t = (0:1/fs:1-1/fs)';
%     signal = sin(2*pi*5*t) + 0.1*randn(size(t));
%
%     % Initial coarse peak detection
%     [~, peaks] = findpeaks(signal);
%     candidates = (peaks - 1) / fs;
%
%     % Refine positions using interpolation
%     refined = refinepeaks(signal, fs, candidates);
%
%     % Refine with custom interpolation frequency
%     refined2 = refinepeaks(signal, fs, candidates, ...
%         'FsInterp', 2000, 'WindowWidth', 0.050);
%
%     % Plot results
%     figure;
%     plot(t, signal, 'b');
%     hold on;
%     plot(candidates, signal(peaks), 'ro', 'MarkerSize', 8);
%     plot(refined, interp1(t, signal, refined), 'g^', 'MarkerSize', 8);
%     legend('Signal', 'Original Peaks', 'Refined Peaks');
%
%   See also INTERP1, FINDPEAKS

% Check number of input and output arguments
narginchk(3, 7);
nargoutchk(0, 1);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'refinepeaks';
addRequired(parser, 'signal', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);
addRequired(parser, 'candidates', @(x) isnumeric(x) && (isvector(x) || isempty(x)));
addParameter(parser, 'FsInterp', 1000, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'WindowWidth', 0.030, @(x) isnumeric(x) && isscalar(x) && x > 0);

parse(parser, signal, fs, candidates, varargin{:});

signal = parser.Results.signal;
fs = parser.Results.fs;
candidates = parser.Results.candidates;
fsInterp = parser.Results.FsInterp;
windowWidth = parser.Results.WindowWidth;

% Ensure signal is a column vector
signal = signal(:);

% Handle empty input
candidates = candidates(~isnan(candidates));
if isempty(candidates)
    refined = [];
    return;
end

% Calculate interpolation parameters
windowSamples = round(windowWidth * fsInterp);
signalLength = length(signal);
t = (0:signalLength-1) / fs;
tInterp = (0:((signalLength * fsInterp / fs)-1)) / fsInterp;

% Interpolate
signalInterp = interp1(t, signal, tInterp, 'spline');
signalInterpLength = length(signalInterp);

% Convert candidate positions to interpolated indices
candidateIndices = 1 + round(candidates * fsInterp);
refined = nan(size(candidates));

% Refine each candidate position
for candidateIndex = 1:length(candidateIndices)
    % Define search window
    searchStart = max(1, candidateIndices(candidateIndex) - windowSamples);
    searchEnd = min(signalInterpLength, candidateIndices(candidateIndex) + windowSamples);
    searchIndices = searchStart:searchEnd;

    % Find local maximum within the window
    [~, maxIndex] = max(signalInterp(searchIndices));
    refinedIndex = searchStart + maxIndex - 1;

    % Validate refined index and convert back to time
    if refinedIndex >= 1 && refinedIndex <= signalInterpLength
        refined(candidateIndex) = tInterp(refinedIndex);
    else
        % Fallback to original position if refinement fails
        refined(candidateIndex) = candidates(candidateIndex);
    end
end

end
