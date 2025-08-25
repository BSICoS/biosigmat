function [nD, threshold] = adaptiveThreshold(dppg, fs, params)
% ADAPTIVETHRESHOLD Core implementation of adaptive thresholding algorithm.
%
%   [ND, THRESHOLD] = ADAPTIVETHRESHOLD(DPPG, FS, PARAMS) implements the
%   adaptive thresholding algorithm for pulse detection in PPG derivative signals.
%   This is a private function called by PULSEDETECTION.
%
%   DPPG is the derivative PPG signal (column vector), FS is the sampling rate
%   in Hz, and PARAMS is a struct containing algorithm parameters:
%     .alphaAmp      - Multiplier for previous amplitude when updating threshold
%     .refractPeriod - Refractory period in seconds
%     .tauRR         - Fraction of RR interval where threshold reaches minimum
%
%   Returns ND (detected pulse indices) and THRESHOLD (time-varying threshold).
%
%   This function assumes inputs are already validated by the calling function.
%
%   See also PULSEDETECTION

% Algorithm constants
initialWindowDuration = 10; % seconds
initialHREstimate = 80; % bpm
amplitudeMultiplier = 3;
minPeaksForRREstimation = 4;
nRREstimation = 3;
nAmplitudeEstimation = 3;

% Prepare input signal
dppg = dppg(:);
signalLength = length(dppg);
refractPeriodSamples = round(params.refractPeriod * fs);

% Initialize threshold using initial signal window
initWindowStart = find(~isnan(dppg), 1, 'first');
initWindowEnd = initWindowStart + round(initialWindowDuration * fs);
initWindowEnd = min(initWindowEnd, signalLength);
initialWindow = dppg(initWindowStart:initWindowEnd);

% Calculate initial RR interval estimate (samples) and threshold
initialRRSamples = round(60/initialHREstimate * fs);
threshold = nan(size(dppg));
initialThreshold = amplitudeMultiplier * mean(initialWindow(initialWindow >= 0), 'omitnan');

% Set up initial threshold profile
timeIndices = 1:signalLength;
currentRRSamples = initialRRSamples;

if (1 + currentRRSamples) < signalLength
    % Linear decay from initial threshold to alpha*threshold over first RR interval
    decayIndices = 1:(currentRRSamples + 1);
    threshold(decayIndices) = initialThreshold - (initialThreshold * (1 - params.alphaAmp) / currentRRSamples) * (decayIndices - 1);
    threshold((currentRRSamples + 1):end) = params.alphaAmp * initialThreshold;
else
    % Signal shorter than one RR interval - use linear decay for entire signal
    threshold(:) = initialThreshold - (initialThreshold * (1 - params.alphaAmp) / currentRRSamples) * (timeIndices - 1);
end

% Initialize pulse detection variables
nD = [];
% Main pulse detection loop
currentIndex = 1;
while true
    % Find next threshold crossing (signal rises above threshold)
    searchStart = currentIndex;
    relativeUpCrossing = find(dppg(searchStart:end) > threshold(searchStart:end), 1, 'first');

    if isempty(relativeUpCrossing)
        % No more upward crossings - end detection
        break;
    end
    upCrossing = searchStart + relativeUpCrossing - 1;

    % Find where signal drops back below threshold
    relativeDownCrossing = find(dppg(upCrossing:end) < threshold(upCrossing:end), 1, 'first');

    if isempty(relativeDownCrossing)
        % No downward crossing found - end detection
        break;
    end
    downCrossing = upCrossing + relativeDownCrossing - 1;

    % Find peak within the crossing region
    [~, relativePeakIndex] = max(dppg(upCrossing:downCrossing));
    peakIndex = upCrossing + relativePeakIndex - 1;

    % Calculate peak amplitude using adaptive estimation
    if length(nD) <= minPeaksForRREstimation
        currentAmplitude = max(dppg(upCrossing:downCrossing));
    else
        % Use median of recent peaks for more robust estimation
        recentPeaks = dppg(nD(end-nAmplitudeEstimation:end));
        currentPeak = max(dppg(upCrossing:downCrossing));
        currentAmplitude = median([recentPeaks; currentPeak]);
    end

    % Store detected pulse
    nD = [nD, peakIndex]; %#ok<AGROW>
    numDetectedPulses = length(nD);

    % Update RR interval estimate based on detected pulses
    if numDetectedPulses >= (nRREstimation + 1)
        % Use median of recent RR intervals for robust estimation
        recentRRIntervals = diff(nD(end-nRREstimation:end));
        currentRRSamples = round(median(recentRRIntervals));
    elseif numDetectedPulses >= 2
        % Use mean when insufficient data for robust median
        currentRRSamples = round(mean(diff(nD)));
    end

    % Set refractory period after pulse detection
    refractoryEnd = min(peakIndex + refractPeriodSamples, signalLength);
    currentIndex = refractoryEnd;

    % Set threshold to peak amplitude during refractory period
    threshold(peakIndex:refractoryEnd) = currentAmplitude;

    % Calculate threshold fall-off parameters
    fallThreshold = currentAmplitude * params.alphaAmp;

    % Apply amplitude-based correction if we have sufficient pulse history
    if numDetectedPulses >= (nAmplitudeEstimation + 1)
        recentAmplitudes = dppg(nD(end-nAmplitudeEstimation:end-1));
        estimatedAmplitude = median(recentAmplitudes);

        % Correct for amplitude outliers (peaks that are too high)
        if currentAmplitude >= (2 * estimatedAmplitude)
            fallThreshold = params.alphaAmp * estimatedAmplitude;
            currentAmplitude = estimatedAmplitude;
        end
    end

    % Calculate threshold decay profile after refractory period
    fallDuration = round(params.tauRR * currentRRSamples);
    fallEndIndex = refractoryEnd + fallDuration;

    if fallEndIndex < signalLength
        % Linear decay from current amplitude to fall threshold
        decayIndices = refractoryEnd:fallEndIndex;
        decayProfile = currentAmplitude - (currentAmplitude - fallThreshold) / fallDuration * (decayIndices - refractoryEnd);
        threshold(decayIndices) = decayProfile;
        threshold((fallEndIndex + 1):end) = fallThreshold;
    else
        % Decay extends beyond signal - apply to remaining samples
        decayIndices = refractoryEnd:signalLength;
        decayProfile = currentAmplitude - (currentAmplitude - fallThreshold) / fallDuration * (decayIndices - refractoryEnd);
        threshold(decayIndices) = decayProfile;
    end

end

% Remove any duplicate indices and sort
nD = unique(nD);

end
