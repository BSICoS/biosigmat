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
%   the same length as DETECTIONS. NaN values in ECG act as hard segment
%   boundaries, and NaN detections produce NaN outputs at the same positions.
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
addRequired(parser, 'ecg', @(x) isnumeric(x) && ~ischar(x) && isvector(x) && numel(x) >= 2 && all(~isinf(x(:))));
addRequired(parser, 'detections', @(x) isnumeric(x) && ~ischar(x) && (isempty(x) || isvector(x)) && all(~isinf(x(:))));
addParameter(parser, 'WindowSize', 20, @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0);

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

finiteDetections = detections(~isnan(detections));

% Validate finite detection positions are within ECG signal bounds
if any(finiteDetections < 1) || any(finiteDetections > length(ecg))
    error('Detection positions must be within ECG signal bounds (1 to %d)', length(ecg));
end

% Initialize output
refinedDetections = NaN(size(detections));

finiteEcg = isfinite(ecg);
finiteTransitions = diff([false; finiteEcg; false]);
finiteSegmentStarts = find(finiteTransitions == 1);
finiteSegmentEnds = find(finiteTransitions == -1) - 1;

% Process each detection
for i = 1:length(detections)
    currentDetection = detections(i);

    if isnan(currentDetection)
        continue;
    end

    detectionSample = round(currentDetection);
    if isnan(ecg(detectionSample))
        continue;
    end

    segmentIndex = find( ...
        finiteSegmentStarts <= detectionSample & ...
        finiteSegmentEnds >= detectionSample, 1);

    % This should only happen for invalid finite values, already rejected.
    if isempty(segmentIndex)
        continue;
    end

    segmentStart = finiteSegmentStarts(segmentIndex);
    segmentEnd = finiteSegmentEnds(segmentIndex);

    % Define search window boundaries without crossing NaN gaps
    windowStart = max([1, segmentStart, detectionSample - windowSize]);
    windowEnd = min([length(ecg), segmentEnd, detectionSample + windowSize]);

    % Extract signal window
    windowSignal = ecg(windowStart:windowEnd);

    % Find local maximum within the window
    [~, localIdx] = max(windowSignal);

    % Convert local index back to global ECG index
    refinedDetections(i) = windowStart + localIdx - 1;
end

end
