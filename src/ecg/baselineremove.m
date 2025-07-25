function [ecgDetrended, baseline] = baselineremove(ecg, tk, offset, varargin)
% BASELINEREMOVE Removes baseline wander from biosignals using cubic spline interpolation.
%
%   ECGDETRENDED = BASELINEREMOVE(ECG, TK, OFFSET) removes baseline wander
%   from vector ECG signal by interpolating between fiducial points computed as
%   (TK - OFFSET), where TK are typically R-peak indices and OFFSET is the
%   number of samples before each TK to use as the fiducial point (e.g., PR interval in ECG).
%   The interpolation is performed using cubic splines, and the resulting baseline estimate
%   is subtracted. Returns the detrended ECG signal ECGDETRENDED, with same size as ECG.
%
%   ECGDETRENDED = BASELINEREMOVE(..., WINDOW) allows specifying the number of
%   samples WINDOW to use for estimation at each fiducial point.
%
%   [ECGDETRENDED, BASELINE] = BASELINEREMOVE(...) returns the estimated BASELINE,
%   which is a vector of the same size as ECG.
%
%   Example:
%     % Remove baseline from ECG signal using R-peaks
%     [cleanEcg, baseline] = baselineremove(ecg, rpeaks, 50);
%     plot(1:length(ecg), ecg, 1:length(cleanEcg), cleanEcg);
%     legend('Original', 'Detrended');
%
%   See also PAMTOMPKINS
%
%   Status: Beta


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
