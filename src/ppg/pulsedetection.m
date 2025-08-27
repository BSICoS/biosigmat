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
%   See also LPDFILTER, PULSEDELINEATION, FINDPEAKS
%
%   Status: Beta


% Check number of input and output arguments
narginchk(2, 18);
nargoutchk(0, 2);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'pulsedetection';
addRequired(parser, 'dppg', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'Method', 'adaptive', @(x) ismember(lower(x), {'adaptive'}));

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
tAdd = 5*fs;

% Process all segments
[nD, threshold] = processSegments(segments, nSegments, segmentLength, tAdd, fs, method, algorithmParams);

% Remove duplicates and refine nD positions
nD = unique(nD);
if ~isempty(nD)
    t = (0:length(dppg)-1)/fs;
    [~, nD] = refinepeaks(dppg, nD, t, Method="NLS");
end

% Remove NaNs from threshold
threshold(signalLength+1:end) = [];
end


%% EXTRACTALGORITHMPARAMS
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


%% PROCESSSEGMENTS
function [nD, threshold] = processSegments(segments, nSegments, segmentLength, tAdd, fs, method, algorithmParams)
% PROCESSSEGMENTS Process signal segments with boundary handling for pulse detection
%
%   [ND, THRESHOLD] = PROCESSSEGMENTS(SEGMENTS, NSEGMENTS, SEGMENTLENGTH, TADD, FS, METHOD, ALGORITHMPARAMS)
%   processes each segment with boundary extensions to minimize edge effects,
%   applies the detection algorithm, and combines results while removing overlaps.

nD = [];
threshold = [];

for iSegments = 1:nSegments
    % Get extended segment
    segment = getExtendedSegment(segments, iSegments, nSegments, tAdd);

    % Create time vector for the segment
    tSegment = (0:length(segment)-1)/fs;

    % Detect peaks in the LPD signal using the selected algorithm
    [nDSegment, thresholdSegment] = detectionAlgorithm(segment(:), fs, method, algorithmParams);

    % Trim results to original segment boundaries
    [nDSegment, thresholdSegment] = trimToOriginalBoundaries(nDSegment, thresholdSegment, ...
        tSegment, fs, iSegments, nSegments, tAdd, segmentLength);

    % Accumulate results with proper indexing
    nD = [nD; nDSegment(:) + segmentLength*(iSegments-1)]; %#ok<*AGROW>
    threshold = [threshold; thresholdSegment(:)];
end
end


%% GETEXTENDEDSEGMENT
function segment = getExtendedSegment(segments, iSegments, nSegments, tAdd)
% GETEXTENDEDSEGMENT Get segment extended with boundary samples
%
%   SEGMENT = GETEXTENDEDSEGMENT(SEGMENTS, ISEGMENTS, NSEGMENTS, TADD)
%   returns a segment extended with TADD samples from adjacent segments
%   to reduce boundary artifacts during processing.

if nSegments == 1
    segment = segments;
    return;
end

switch iSegments
    case 1
        % First segment: extend end only
        segment = [segments(:, 1); segments(1:tAdd, 2)];
    case nSegments
        % Last segment: extend beginning only
        segment = [segments(end-(tAdd)+1:end, end-1); segments(:, end)];
    otherwise
        % Middle segment: extend both ends
        segment = [segments(end-(tAdd)+1:end, iSegments-1);...
            segments(:, iSegments);
            segments(1:tAdd, iSegments+1)];
end
end


%% DETECTIONALGORITHM
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


%% TRIMTOORIGINALBOUNDARIES
function [nDSegment, thresholdSegment] = trimToOriginalBoundaries(nDSegment, thresholdSegment, ...
    tSegment, fs, iSegments, nSegments, tAdd, segmentLength)
% TRIMTOORIGINALBOUNDARIES Remove boundary extensions from processing results
%
%   [NDSEGMENT, THRESHOLDSEGMENT] = TRIMTOORIGINALBOUNDARIES(...)
%   removes the boundary extensions that were added for processing,
%   returning results that correspond to the original segment boundaries.

if nSegments == 1
    return; % No trimming needed for single segment
end

switch iSegments
    case 1
        % First segment: remove end extension
        nDSegment = nDSegment(nDSegment <= segmentLength);
        thresholdSegment = thresholdSegment(tSegment*fs < segmentLength);
    case nSegments
        % Last segment: remove beginning extension
        nDSegment = nDSegment(nDSegment > tAdd) - tAdd;
        thresholdSegment = thresholdSegment(tSegment*fs >= tAdd);
    otherwise
        % Middle segment: remove both extensions
        nDSegment = nDSegment(nDSegment >= tAdd & nDSegment < segmentLength + tAdd) - tAdd;

        validTime = tSegment*fs >= tAdd & tSegment*fs < segmentLength + tAdd;
        thresholdSegment = thresholdSegment(validTime);
end
end