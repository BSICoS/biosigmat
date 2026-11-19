function [tD, threshold] = pulsedet(dppg, fs, varargin)
% PULSEDET Pulse detection in LPD-filtered PPG signals using configurable algorithms.
%
%   TD = PULSEDET(DPPG, FS) detects pulse maximum upslopes TD in PPG derivative
%   (DPPG) using the default adaptive threshold algorithm. DPPG is the LPD-filtered PPG
%   signal (column vector) and FS is the sampling rate in Hz. TD contains
%   refined detection times in seconds, with the first sample at time zero.
%
%   The adaptive state is preserved throughout the signal. Searches use
%   bounded blocks to avoid repeatedly processing the entire remaining signal.
%
%   TD = PULSEDET(..., 'Name', Value) specifies additional parameters
%   using name-value pairs:
%     'Method'        - Detection algorithm: 'adaptive' (default)
%
%   Adaptive algorithm parameters:
%     'AdaptiveAlphaAmp'      - Multiplier for previous amplitude of detected maximum
%                               when updating the threshold (default: 0.2)
%     'AdaptiveRefractPeriod' - Refractory period for threshold in seconds
%                               (default: 0.15)
%     'AdaptiveTauRR'         - Fraction of estimated RR interval where threshold reaches
%                               its minimum value after the refractory period
%                               (default: 1.0). Larger values give a longer decay
%     'ResetAfter'           - Seconds without a detection before reinitializing
%                               the adaptive state (default: Inf, no reset).
%                               NaN spans count toward this elapsed time;
%                               initialization resumes when signal is available
%
%   [TD, THRESHOLD] = PULSEDET(...) also returns the computed
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
%     [tD, threshold] = pulsedet(signalFiltered, fs);
%
%     % Visualize results
%     t = (0:length(signalFiltered)-1) / fs;
%     figure;
%     plot(t, signalFiltered, 'b');
%     hold on;
%     plot(t, threshold, 'r--', 'LineWidth', 1.5);
%     plot(tD, signalFiltered(round(tD*fs)+1), 'go', 'MarkerSize', 8);
%     xlabel('Time (s)');
%     ylabel('Amplitude');
%     title('PPG Pulse Detection');
%     legend('Filtered PPG', 'Threshold', 'Detected Pulses');
%
%     % Calculate heart rate
%     heartRate = 60 ./ diff(tD);
%     fprintf('Detected %d pulses\n', length(tD));
%     fprintf('Mean heart rate: %.1f bpm\n', mean(heartRate));
%
%   See also LPDFILTER, PULSEDEL, FINDPEAKS


% Check number of input and output arguments
narginchk(2, 18);
nargoutchk(0, 2);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'pulsedet';
addRequired(parser, 'dppg', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'Method', 'adaptive', @(x) ismember(lower(x), {'adaptive'}));

% TODO: Add future methods

% Adaptive algorithm parameters
addParameter(parser, 'AdaptiveAlphaAmp', 0.2, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'AdaptiveRefractPeriod', 150e-03, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'AdaptiveTauRR', 1, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'ResetAfter', Inf, @(x) isnumeric(x) && isreal(x) && isscalar(x) && x > 0);

% TODO: Future algorithm parameters

parse(parser, dppg, fs, varargin{:});

dppg = parser.Results.dppg;
fs = parser.Results.fs;
method = lower(parser.Results.Method);

% Extract algorithm-specific parameters
algorithmParams = extractAlgorithmParams(parser.Results, method);

dppg = dppg(:);

% Detect pulses while preserving adaptive state across search blocks
[detectionSamples, threshold] = detectionAlgorithm(dppg, fs, method, algorithmParams);

% Remove duplicates and refine detection times
detectionSamples = unique(detectionSamples);
tD = zeros(0, 1);
if ~isempty(detectionSamples)
    t = (0:length(dppg)-1)/fs;
    [~, tD] = refinepeaks(dppg, detectionSamples, t);
end

% Remove NaN values from refined detection times
tD = tD(~isnan(tD));

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
        params.resetAfter = allParams.ResetAfter;

        % TODO: Add cases for future algorithms

    otherwise
        error('pulsedet:unknownMethod', 'Unknown detection method: %s', method);
end
end


%% DETECTIONALGORITHM
function [detectionSamples, threshold] = detectionAlgorithm(signal, fs, method, params)
% DETECTPULSESALGORITHM Dispatch function for pulse detection algorithms.
%
%   [DETECTIONSAMPLES, THRESHOLD] = DETECTPULSESALGORITHM(SIGNAL, FS, METHOD, PARAMS)
%   calls the appropriate algorithm implementation based on the specified method.

switch method
    case 'adaptive'
        [detectionSamples, threshold] = adaptiveThreshold(signal, fs, params);

        % TODO: Add cases for future algorithms

    otherwise
        error('pulsedet:unknownMethod', 'Unknown detection method: %s', method);
end
end
