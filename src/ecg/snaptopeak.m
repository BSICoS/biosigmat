function refinedDetections = snaptopeak(ecg, detections, varargin)
% SNAPTOPEAK Refine QRS detections by snapping to local maxima
%
%   snaptopeak(ECG, DETECTIONS) Refines QRS detection positions by moving
%              each detection to the nearest local maximum within a search
%              window around the original detection. This improves the
%              precision of R-wave peak localization.
%
%   REFINEDDETECTIONS = snaptopeak(ECG, DETECTIONS)
%       REFINEDDETECTIONS is a column vector containing the refined detection
%       positions in samples, snapped to local maxima.
%
%   snaptopeak(..., 'Name', Value) specifies optional parameters using
%       name-value pair arguments:
%       - 'WindowSize': Search window size around each detection in samples.
%                      Default: 20 samples
%
% Inputs:
%   ECG        - Single-lead ECG signal (numeric vector)
%   DETECTIONS - Initial detection positions in samples (numeric vector)
%
% Output:
%   REFINEDDETECTIONS - Refined detection positions in samples (column vector)

% Input argument validation
narginchk(2, inf);
nargoutchk(0, 1);

% Parse input arguments
parser = inputParser;
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
