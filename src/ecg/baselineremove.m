function [cleanedSignal, baseline, fiducialValues] = baselineremove(signal, fiducialPoints, varargin)
% BASELINEREMOVE Removes baseline wander from biosignals using cubic spline interpolation
%
%   This function removes baseline wander from biosignals (e.g., ECG) by
%   interpolating between fiducial points that represent the isoelectric line.
%   The interpolation is performed using cubic splines, and the resulting
%   baseline estimate is subtracted from the original signal.
%
%   [cleanedSignal, baseline, fiducialValues] = baselineremove(signal, fiducialPoints) removes
%   baseline wander from the signal using the specified fiducial points.
%
%   [cleanedSignal, baseline, fiducialValues] = baselineremove(signal, fiducialPoints, Name, Value)
%   allows specifying additional options using name-value pairs.
%
% Inputs:
%   signal         - Input signal vector to be filtered (column vector)
%   fiducialPoints - Vector containing indices of fiducial points that represent
%                    the isoelectric line (e.g., PR interval in ECG)
%
% Name-Value Pair Arguments:
%   'WindowSize'   - Number of samples to use for estimation at each fiducial point.
%                    Default: 5
%
% Outputs:
%   cleanedSignal  - Signal with baseline wander removed
%   baseline       - The estimated baseline that was removed from the signal
%   fiducialValues - Signal values at the fiducial points used for interpolation
%
% Example:
%   % Remove baseline wander from an ECG signal using R-wave indices
%   fs = 250;  % Sampling frequency in Hz
%   t = (0:length(signal)-1)' / fs;  % Time vector in seconds
%   fiducialPoints = rPeaks - round(0.08*fs);  % 80 ms before R-peak (PR interval)
%   [cleanedSignal, baseline, fiducialValues] = baselineremove(signal, fiducialPoints);
%
%   % Visualize results
%   figure;
%   subplot(2,1,1); plot(t, signal, 'b', t, baseline, 'r', 'LineWidth', 2); hold on;
%   plot(t(rPeaks), signal(rPeaks), 'ro', t(fiducialPoints), signal(fiducialPoints), 'g*');
%   title('Original Signal with Baseline and Detections'); xlabel('Time (s)'); grid on;
%
%   subplot(2,1,2); plot(t, cleanedSignal, 'b'); hold on;
%   plot(t(rPeaks), cleanedSignal(rPeaks), 'ro', t(fiducialPoints), cleanedSignal(fiducialPoints), 'g*');
%   title('Baseline-Corrected Signal'); xlabel('Time (s)'); grid on;

% Check number of input and output arguments
narginchk(2, Inf);
nargoutchk(0, 3);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'baselineremove';
addRequired(parser, 'signal', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'fiducialPoints', @(x) isnumeric(x) && isvector(x) && all(x > 0));
addParameter(parser, 'WindowSize', 5, @(x) isnumeric(x) && isscalar(x) && x > 0 && mod(x,1) == 0);

parse(parser, signal, fiducialPoints, varargin{:});

signal = parser.Results.signal(:);  % Ensure column vector
fiducialPoints = parser.Results.fiducialPoints(:);  % Ensure column vector
windowSize = parser.Results.WindowSize;

% Ensure fiducial points are integers within valid range
fiducialPoints = round(fiducialPoints);
fiducialPoints = fiducialPoints(fiducialPoints >= 1 & fiducialPoints <= length(signal));

if isempty(fiducialPoints)
    warning('baselineremove:noValidFiducialPoints', 'No valid fiducial points provided. Returning original signal.');
    cleanedSignal = signal;
    baseline = zeros(size(signal));
    fiducialValues = [];
    return;
end

% Sort fiducial points in ascending order and remove duplicates
fiducialPoints = unique(fiducialPoints);
n = length(signal);
xpoints = (1:n)';

% Calculate mean values around each fiducial point
fiducialValues = signal(fiducialPoints);

for i = 1:length(fiducialPoints)
    idx = fiducialPoints(i);

    startIdx = max(1, idx - floor(windowSize/2));
    endIdx = min(length(signal), idx + floor(windowSize/2));

    fiducialValues(i) = mean(signal(startIdx:endIdx));
end

% Create cubic spline interpolation of the baseline
baseline = spline(fiducialPoints, fiducialValues, xpoints);

% Remove baseline from signal
cleanedSignal = signal - baseline;

end
