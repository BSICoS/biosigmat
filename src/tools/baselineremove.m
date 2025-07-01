function [cleanedSignal, baseline, fiducialPoints] = baselineremove(signal, fiducialPoints, varargin)
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
%   'Method'       - Method to locate baseline estimation points.
%                    'fixed': Use the exact fiducial points provided
%                    'derivative': Refine points by finding minimal slope using filtered
%                                  derivative signal to improve isoelectric point detection
%                    Default: 'derivative'
%   'RefineWindow' - Window size (in samples) for refining fiducial points when 
%                    using 'derivative' method.
%                    Default: 10
%   'SamplingFreq' - Sampling frequency in Hz. Used for filtering the derivative signal.
%                    Required when Method is 'derivative'.
%                    Default: [] (must be provided for derivative method)
%   'FilterFreq'   - Cutoff frequency in Hz for the lowpass filter applied to derivative.
%                    Default: 15
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
%   [cleanedSignal, baseline, fiducialValues] = baselineremove(signal, fiducialPoints, 'SamplingFreq', fs);
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
addParameter(parser, 'Method', 'derivative', @(x) ischar(x) && any(strcmp(x, {'fixed', 'derivative'})));
addParameter(parser, 'RefineWindow', 10, @(x) isnumeric(x) && isscalar(x) && x > 0 && mod(x,1) == 0);
addParameter(parser, 'SamplingFreq', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x > 0));
addParameter(parser, 'FilterFreq', 45, @(x) isnumeric(x) && isscalar(x) && x > 0);

parse(parser, signal, fiducialPoints, varargin{:});

signal = parser.Results.signal(:);  % Ensure column vector
fiducialPoints = parser.Results.fiducialPoints(:);  % Ensure column vector
windowSize = parser.Results.WindowSize;
method = parser.Results.Method;
refineWindow = parser.Results.RefineWindow;
fs = parser.Results.SamplingFreq;
filterFreq = parser.Results.FilterFreq;

% Check if sampling frequency is provided when using derivative method
if strcmp(method, 'derivative') && isempty(fs)
    error('baselineremove:missingSamplingFreq', 'Sampling frequency (SamplingFreq) must be provided when using derivative method.');
end

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

% Refine fiducial points if requested
if strcmp(method, 'derivative')
    refinedPoints = zeros(size(fiducialPoints));
    
    % Use lpdfilter to calculate a filtered derivative of the signal
    [filteredDerivative, ~] = lpdfilter(signal, fs, filterFreq);

    % Get second derivative to find inflection points (where curvature changes)
    [secondDerivative, ~] = lpdfilter(filteredDerivative, fs, filterFreq/2);
    
    % Calculate signal energy as additional feature
    windowLength = round(fs/40); % ~25ms window for feature extraction
    energySignal = movvar(signal, windowLength);
    
    for i = 1:length(fiducialPoints)
        idx = fiducialPoints(i);
        
        % Define window boundaries
        startIdx = max(1, idx - refineWindow);
        endIdx = min(length(signal), idx + refineWindow);%+0.1*fs;
        
        % Extract features within the window
        windowSignal = signal(startIdx:endIdx);
        windowDerivative = filteredDerivative(startIdx:endIdx);
        window2ndDeriv = secondDerivative(startIdx:endIdx);
        windowEnergy = energySignal(startIdx:endIdx);

        % Create a composite score:
        % - Low absolute first derivative (flat segment)
        % - Low absolute second derivative (consistent slope/no inflection)
        % - Low variance (stable signal)
        % - Close to the median value in the window (avoid peaks/outliers)
        
        normDeriv = abs(windowDerivative) / max(abs(windowDerivative) + eps);
        norm2ndDeriv = abs(window2ndDeriv) / max(abs(window2ndDeriv) + eps);
        normEnergy = windowEnergy / max(windowEnergy + eps);
        distFromMedian = abs(windowSignal - median(windowSignal)) / max(abs(windowSignal - median(windowSignal)) + eps);
        
        % Combine metrics with weighted sum (lower is better)
        compositeScore = 0.4*normDeriv + 0.3*norm2ndDeriv + 0.2*normEnergy + 0.1*distFromMedian;
        
        % Find the optimal point
        [~, optIdx] = min(compositeScore);
        
        % Update the fiducial point to the refined position
        refinedPoints(i) = startIdx + optIdx - 1;
    end
    
    fiducialPoints = refinedPoints;
end

% Sort fiducial points in ascending order and remove duplicates
fiducialPoints = unique(fiducialPoints);
n = length(signal);
xpoints = (1:n)';

% Calculate mean values around each fiducial point
ypoints = signal(fiducialPoints);

for i = 1:length(fiducialPoints)
    idx = fiducialPoints(i);
    
    startIdx = max(1, idx - floor(windowSize/2));
    endIdx = min(length(signal), idx + floor(windowSize/2));
    
    ypoints(i) = mean(signal(startIdx:endIdx));
end

% Create cubic spline interpolation of the baseline
baseline = spline(fiducialPoints, ypoints, xpoints);

% Remove baseline from signal
cleanedSignal = signal - baseline;

end
