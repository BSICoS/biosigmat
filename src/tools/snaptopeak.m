function refinedDetections = snaptopeak(ecg, detections, varargin)
% SNAPTOPEAK Refine QRS detections by snapping to local maxima.
%
%   REFINEDDETECTIONS = SNAPTOPEAK(ECG, DETECTIONS) refines QRS detection
%   positions by moving each detection in DETECTIONS to the nearest local
%   maximum within a search window around the original detection. ECG is
%   the single-lead ECG signal and DETECTIONS contains the initial detection
%   positions in samples. This improves the precision of R-wave peak
%   localization by ensuring detections align with actual signal peaks.
%   Returns REFINEDDETECTIONS as a column vector of refined positions with
%   the same length as DETECTIONS.
%
%   REFINEDDETECTIONS = SNAPTOPEAK(..., 'WindowSize', WINDOWSIZE)
%   specifies the search window size WINDOWSIZE in samples around each
%   detection. Default window size is 20 samples.
%
%   The function searches for the maximum value within the specified window
%   around each detection and moves the detection to that location. This is
%   particularly useful after initial QRS detection to ensure precise
%   alignment with R-wave peaks.
%
%   Example:
%     % Load ECG data and perform initial detection
%     load('ecg_sample.mat', 'ecg', 'fs');
%
%     % Perform initial QRS detection (using pantompkins or similar)
%     initialDetections = pantompkins(ecg, fs);
%
%     % Refine detections by snapping to local maxima
%     refinedDetections = snaptopeak(ecg, initialDetections);
%
%     % Use larger search window
%     refinedDetections2 = snaptopeak(ecg, initialDetections, 'WindowSize', 30);
%
%   See also PANTOMPKINS, FINDPEAKS, MAX


% Argument validation
narginchk(2, inf);
nargoutchk(0, 1);

% Parse input arguments
parser = inputParser;
parser.FunctionName = 'snaptopeak';
addRequired(parser, 'ecg', @(x) isnumeric(x) && ~ischar(x) && isvector(x) && ~isscalar(x) && ~isempty(x));
addRequired(parser, 'detections', @(x) isnumeric(x) && ~ischar(x));
addParameter(parser, 'WindowSize', 20, @(x) isnumeric(x) && isscalar(x) && x > 0);

parse(parser, ecg, detections, varargin{:});

ecg = parser.Results.ecg;
detections = parser.Results.detections;
windowSize = round(parser.Results.WindowSize);

% Handle empty input
if isempty(detections)
    refinedDetections = [];
    return;
end

% Ensure column vectors
ecg = ecg(:);
detections = detections(:);

% Validate detection positions are within ECG signal bounds
if any(detections < 1) || any(detections > length(ecg))
    error('Detection positions must be within ECG signal bounds (1 to %d)', length(ecg));
end

% Initialize output
refinedDetections = zeros(size(detections));

% Process each detection
for i = 1:length(detections)
    currentDetection = detections(i);

    % Define search window boundaries
    windowStart = max(1, currentDetection - windowSize);
    windowEnd = min(length(ecg), currentDetection + windowSize);

    % Extract signal window
    windowSignal = ecg(windowStart:windowEnd);

    % Find local maximum within the window
    [~, localIdx] = max(windowSignal);

    % Convert local index back to global ECG index
    refinedDetections(i) = windowStart + localIdx - 1;
end

end
