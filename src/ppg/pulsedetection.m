function [nD, threshold] = pulsedetection(dppg, fs, varargin)
% PULSEDETECTION Pulse detection in LPD-filtered PPG signals using adaptive thresholding.
%
%   ND = PULSEDETECTION(DPPG, FS) detects pulse maximum upslopes ND in PPG derivative
%   (DPPG) using an adaptive threshold algorithm. DPPG is the LPD-filtered PPG
%   signal (column vector) and FS is the sampling rate in Hz.
%
%   The algorithm uses adaptive thresholding with refractory periods and
%   beat pattern analysis to handle irregular rhythms. It processes long
%   signals in segments for computational efficiency and includes correction
%   mechanisms for missed or false detections based on pulse-to-pulse
%   interval regularity.
%
%   ND = PULSEDETECTION(..., 'Name', Value) specifies additional parameters
%   using name-value pairs:
%     'alphaAmp'      - Multiplier for previous amplitude of detected maximum
%                       when updating the threshold (default: 0.2)
%     'refractPeriod' - Refractory period for threshold in seconds
%                       (default: 0.15)
%     'tauRR'         - Fraction of estimated RR interval where threshold reaches
%                       its minimum value (default: 1.0). Larger values create
%                       steeper threshold slopes
%
%   [ND, THRESHOLD] = PULSEDETECTION(...) also returns the computed
%   time-varying THRESHOLD.
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
%     % Detect pulses with default parameters
%     [nD, threshold] = pulsedetection(signalFiltered, fs);
%
%     % Detect pulses with custom parameters
%     [nD2, threshold2] = pulsedetection(signalFiltered, fs, ...
%         'alphaAmp', 0.3, 'refractPeriod', 0.2);
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
%     title('PPG Pulse Detection with Adaptive Threshold');
%     legend('Filtered PPG', 'Threshold', 'Detected Pulses');
%
%     % Calculate heart rate
%     heartRate = 60 ./ diff(nD);
%     fprintf('Detected %d pulses\n', length(nD));
%     fprintf('Mean heart rate: %.1f bpm\n', mean(heartRate));
%
%   See also LPDFILTER, PULSEDELINEATION, FINDPEAKS
%
%   Status: Alpha


% Check number of input and output arguments
narginchk(2, 10);
nargoutchk(0, 2);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'pulsedetection';
addRequired(parser, 'dppg', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'alphaAmp', 0.2, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'refractPeriod', 150e-03, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'tauRR', 1, @(x) isnumeric(x) && isscalar(x) && x > 0);

parse(parser, dppg, fs, varargin{:});

dppg = parser.Results.dppg;
fs = parser.Results.fs;
alphaAmp = parser.Results.alphaAmp;
refractPeriod = parser.Results.refractPeriod;
tauRR = parser.Results.tauRR;

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

    % Detect peaks in the LPD signal by adaptive thresholding
    [nDSegment, thresholdSegment] = adaptiveThreshold(segment(:), fs,...
        'alphaAmp', alphaAmp, 'refractPeriod', refractPeriod, 'tauRR', tauRR);

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

% Arrange Outputs (nD in seconds and NaNs removed from threshold)
nD = (unique(nD)-1)/fs;
threshold(signalLength+1:end) = [];

end