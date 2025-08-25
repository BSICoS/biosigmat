function [nD, threshold] = pulsedetection(dppg, fs, varargin)
% PULSEDETECTION Pulse detection in LPD-filtered PPG signals using configurable algorithms.
%
%   ND = PULSEDETECTION(DPPG, FS) detects pulse maximum upslopes ND in PPG derivative
%   (DPPG) using the default adaptive threshold algorithm. DPPG is the LPD-filtered PPG
%   signal (column vector) and FS is the sampling rate in Hz.
%
%   The function supports multiple detection algorithms and processes long
%   signals in segments for computational efficiency. Each algorithm includes
%   specialized mechanisms for missed or false detection correction.
%
%   ND = PULSEDETECTION(..., 'Name', Value) specifies additional parameters
%   using name-value pairs:
%     'Method'        - Detection algorithm: 'adaptive' (default)
%     'FsInterp'      - Interpolation sampling frequency for peak refinement in Hz
%                       (default: 2000)
%
%   Adaptive algorithm parameters:
%     'AdaptiveAlphaAmp'      - Multiplier for previous amplitude of detected maximum
%                               when updating the threshold (default: 0.2)
%     'AdaptiveRefractPeriod' - Refractory period for threshold in seconds
%                               (default: 0.15)
%     'AdaptiveTauRR'         - Fraction of estimated RR interval where threshold reaches
%                               its minimum value (default: 1.0). Larger values create
%                               steeper threshold slopes
%
%   [ND, THRESHOLD] = PULSEDETECTION(...) also returns the computed
%   time-varying THRESHOLD for the selected algorithm.
%
%   Example:
%     % Load PPG signal and apply LPD filtering
%     load('ppg_sample.mat', 'ppg', 'fs');
%
%     % Design and apply LPD filter
%     fcLPD = 8; fpLPD = 0.9; orderLPD = 4;
%     [b, delay] = lpdfilter(fs, fcLPD, 'PassFreq', fpLPD, 'Order', orderLPD);
%     signalFiltered = filter(b, 1, ppg);
%     signalFiltered = [signalFiltered(delay+1:end); zeros(delay, 1)];
%
%     % Detect pulses with default adaptive algorithm
%     [nD, threshold] = pulsedetection(signalFiltered, fs);
%
%     % Visualize results
%     t = (0:length(signalFiltered)-1) / fs;
%     figure;
%     plot(t, signalFiltered, 'b');
%     hold on;
%     plot(t, threshold, 'r--', 'LineWidth', 1.5);
%     plot(nD, signalFiltered(round(nD*fs)+1), 'go', 'MarkerSize', 8);
%     xlabel('Time (s)');
%     ylabel('Amplitude');
%     title('PPG Pulse Detection');
%     legend('Filtered PPG', 'Threshold', 'Detected Pulses');
%
%     % Calculate heart rate
%     heartRate = 60 ./ diff(nD);
%     fprintf('Detected %d pulses\n', length(nD));
%     fprintf('Mean heart rate: %.1f bpm\n', mean(heartRate));
%
%   See also LPDFILTER, PULSEDELINEATION, REFINEPEAKPOSITIONS, FINDPEAKS
%
%   Status: Alpha


% Check number of input and output arguments
narginchk(2, 18);
nargoutchk(0, 2);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'pulsedetection';
addRequired(parser, 'dppg', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'Method', 'adaptive', @(x) ismember(lower(x), {'adaptive'}));
addParameter(parser, 'FsInterp', 2000, @(x) isnumeric(x) && isscalar(x) && x > 0);

% TODO: Add future methods

% Adaptive algorithm parameters
addParameter(parser, 'AdaptiveAlphaAmp', 0.2, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'AdaptiveRefractPeriod', 150e-03, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'AdaptiveTauRR', 1, @(x) isnumeric(x) && isscalar(x) && x > 0);

% TODO: Future algorithm parameters

parse(parser, dppg, fs, varargin{:});

dppg = parser.Results.dppg;
fs = parser.Results.fs;
method = lower(parser.Results.Method);
fsInterp = parser.Results.FsInterp;

% Extract algorithm-specific parameters
algorithmParams = extractAlgorithmParams(parser.Results, method);

dppg = dppg(:);

% Segmentize the signals to avoid memory issues
signalLength = length(dppg);
segmentLength = 10000;

if segmentLength < signalLength
    segments = slicesignal(dppg, segmentLength, 0, 'Uselast', true);
else
    segments = dppg;
end

nSegments = size(segments, 2);
nD = [];
threshold = [];
tAdd = 5*fs;

% Go through each segment
for iSegments = 1:nSegments
    % Make the segments tAdd seconds longer on each side
    if nSegments > 1
        if iSegments == 1
            % End the segment tAdd seconds later
            segment = [segments(:, 1); segments(1:tAdd, 2)];
        elseif iSegments == nSegments
            % Start the segment tAdd seconds earlier
            segment = [segments(end-(tAdd)+1:end, end-1); segments(:, end)];
        else
            % Start the segment tAdd seconds earlier and end tAdd seconds later
            segment = [segments(end-(tAdd)+1:end, iSegments-1);...
                segments(:, iSegments); segments(1:tAdd, iSegments+1)];
        end
    else
        % Take the whole segment
        segment = segments;
    end

    time = (0:length(segment)-1)/fs;

    % Detect peaks in the LPD signal using the selected algorithm
    [nDSegment, thresholdSegment] = detectionAlgorithm(segment(:), fs, method, algorithmParams);

    % Remove added signal on both sides
    if nSegments > 1
        if iSegments == 1
            % Remove the last tAdd seconds
            nDSegment = nDSegment(nDSegment <= segmentLength);
            thresholdSegment = thresholdSegment(time*fs < segmentLength);
        elseif iSegments == nSegments
            % Remove the first tAdd seconds
            nDSegment = nDSegment(nDSegment > tAdd) - (tAdd);
            thresholdSegment = thresholdSegment(time*fs >= tAdd);
        else
            % Remove the first and last tAdd seconds
            nDSegment = nDSegment(nDSegment >= tAdd) - tAdd;
            nDSegment = nDSegment(nDSegment < segmentLength);

            thresholdSegment = thresholdSegment(time*fs >= tAdd);
            thresholdSegment = thresholdSegment(time*fs < segmentLength);
        end
    end

    % Store the signals
    nD = [nD; nDSegment(:) + segmentLength*(iSegments-1)]; %#ok<*AGROW>
    threshold = [threshold; thresholdSegment(:)];

end

% Remove duplicates and refine nD positions using interpolation for improved precision
nD = unique(nD);
if ~isempty(nD)
    % Convert indices back to time positions for refinement
    nDTimePositions = (nD - 1) / fs;

    % Refine positions using high-resolution interpolation
    refinedPositions = refinePeakPositions(dppg, fs, nDTimePositions, ...
        'FsInterp', fsInterp, 'WindowWidth', 0.030);

    % Convert refined positions back to sample indices
    nD = 1 + round(refinedPositions * fs);
end

% Arrange Outputs (nD in seconds and NaNs removed from threshold)
nD = (nD-1)/fs;
threshold(signalLength+1:end) = [];

end

function params = extractAlgorithmParams(allParams, method)
% EXTRACTALGORITHMPARAMS Extract algorithm-specific parameters from parsed inputs.
%
%   PARAMS = EXTRACTALGORITHMPARAMS(ALLPARAMS, METHOD) filters the parsed
%   parameters to include only those relevant to the specified detection method.

switch method
    case 'adaptive'
        params.alphaAmp = allParams.AdaptiveAlphaAmp;
        params.refractPeriod = allParams.AdaptiveRefractPeriod;
        params.tauRR = allParams.AdaptiveTauRR;

        % TODO: Add cases for future algorithms

    otherwise
        error('pulsedetection:unknownMethod', 'Unknown detection method: %s', method);
end
end

function [nD, threshold] = detectionAlgorithm(signal, fs, method, params)
% DETECTPULSESALGORITHM Dispatch function for pulse detection algorithms.
%
%   [ND, THRESHOLD] = DETECTPULSESALGORITHM(SIGNAL, FS, METHOD, PARAMS)
%   calls the appropriate algorithm implementation based on the specified method.

switch method
    case 'adaptive'
        [nD, threshold] = adaptiveThreshold(signal, fs, params);

        % TODO: Add cases for future algorithms

    otherwise
        error('pulsedetection:unknownMethod', 'Unknown detection method: %s', method);
end
end