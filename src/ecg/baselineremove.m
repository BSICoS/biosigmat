function [ecgDetrended, baseline] = baselineremove(ecg, tk, offset, varargin)
% BASELINEREMOVE Removes baseline wander from biosignals using cubic spline interpolation.
%
%   Removes baseline wander from ECG signals by interpolating between fiducial points
%   computed as (tk - offset), where tk are typically R-peak indices and offset is the number of samples
%   before each tk to use as the fiducial point (e.g., PR interval in ECG).
%   The interpolation is performed using cubic splines, and the resulting baseline estimate is subtracted.
%
%   [ecgDetrended, baseline] = BASELINEREMOVE(ecg, tk, offset) removes baseline wander
%   using fiducial points computed as (tk - offset), with default window size 5.
%
%   [ecgDetrended, baseline] = BASELINEREMOVE(ecg, tk, offset, window) allows specifying
%   the number of samples to use for estimation at each fiducial point.
%
% Inputs:
%   ecg   - Input signal to be filtered (column vector)
%   tk       - Vector containing indices of R-peaks (or other fiducial events)
%   offset   - Number of samples to subtract from each tk to obtain fiducial points
%   window   - (Optional) Number of samples to use for estimation at each fiducial point (default: 5)
%
% Outputs:
%   ecgDetrended  - ecg with baseline wander removed
%   baseline       - The estimated baseline that was removed from the ecg
%
% EXAMPLE:
%   % Remove baseline from ECG signal using R-peaks
%   [cleanEcg, baseline] = baselineremove(ecg, rpeaks, 50);
%   plot(1:length(ecg), ecg, 1:length(cleanEcg), cleanEcg);
%   legend('Original', 'Detrended');


% Check number of input and output arguments
narginchk(3, 4);
nargoutchk(0, 2);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'baselineremove';
addRequired(parser, 'ecg', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'tk', @(x) isnumeric(x) && isvector(x) && all(x > 0));
addRequired(parser, 'offset', @(x) isnumeric(x) && isscalar(x) && x >= 0 && mod(x,1) == 0);
addOptional(parser, 'window', 5, @(x) isnumeric(x) && isscalar(x) && x > 0 && mod(x,1) == 0);

parse(parser, ecg, tk, offset, varargin{:});

ecg = parser.Results.ecg(:);
tk = parser.Results.tk(:);
offset = parser.Results.offset;
window = parser.Results.window;


% Compute fiducial points as tk - offset
fiducialPoints = round(tk - offset);
fiducialPoints = fiducialPoints(fiducialPoints >= 1 & fiducialPoints <= length(ecg));
fiducialPoints = unique(fiducialPoints);

if isempty(fiducialPoints)
    warning('baselineremove:noValidFiducialPoints', 'No valid fiducial points computed. Returning original ecg.');
    ecgDetrended = ecg;
    baseline = zeros(size(ecg));
    return;
end

% Calculate mean values around each fiducial point
fiducialValues = zeros(size(fiducialPoints));
for i = 1:length(fiducialPoints)
    idx = fiducialPoints(i);
    startIdx = max(1, idx - floor(window/2));
    endIdx = min(length(ecg), idx + floor(window/2));
    fiducialValues(i) = mean(ecg(startIdx:endIdx));
end

% Create cubic spline interpolation of the baseline
xq = 1:length(ecg);
baseline = spline(fiducialPoints, fiducialValues, xq');

% Remove baseline from ecg
ecgDetrended = ecg - baseline;

end
