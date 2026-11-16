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
%     .resetAfter    - Seconds without a detection before reinitializing (Inf disables)
%
%   Returns ND (detected pulse indices) and THRESHOLD (time-varying threshold).
%
%   This function assumes inputs are already validated by the calling function.
%
%   See also PULSEDETECTION


% Algorithm constants
initialHREstimate = 80; % bpm
minPeaksForRREstimation = 4;
nRREstimation = 3;
nAmplitudeEstimation = 3;
searchBlockLength = 4096;

% Prepare input signal
dppg = dppg(:);
signalLength = length(dppg);
refractPeriodSamples = round(params.refractPeriod * fs);
resetSamples = ceil(params.resetAfter * fs);

% Initialize threshold using initial signal window
initialRRSamples = round(60/initialHREstimate * fs);
[profile, firstSignalIndex] = initializeThreshold(dppg, fs, params.alphaAmp, ...
    initialRRSamples, 1, searchBlockLength);
threshold = nan(size(dppg));
thresholdWriteStart = 1;
currentRRSamples = initialRRSamples;
resetIndex = Inf;
if ~isempty(firstSignalIndex)
    resetIndex = firstSignalIndex + resetSamples;
end

% Initialize pulse detection variables
nD = [];
historyStart = 1;

% Main pulse detection loop
currentIndex = 1;
while true
    searchEnd = min(signalLength, resetIndex - 1);

    % Find next threshold crossing (signal rises above threshold)
    upCrossing = findCrossing(dppg, profile, currentIndex, searchEnd, ...
        searchBlockLength, true);

    % Find where signal drops back below threshold
    downCrossing = [];
    if ~isempty(upCrossing)
        downCrossing = findCrossing(dppg, profile, upCrossing, searchEnd, ...
            searchBlockLength, false);
    end

    if isempty(upCrossing) || isempty(downCrossing)
        if resetIndex > signalLength
            % No more complete upward crossings - end detection
            break;
        end

        % Reinitialize only when the caller has enabled the inactivity limit.
        nextSignalIndex = findAvailableSample(dppg, resetIndex, searchBlockLength);
        if isempty(nextSignalIndex)
            break;
        end
        threshold(thresholdWriteStart:nextSignalIndex-1) = ...
            thresholdValues(profile, thresholdWriteStart:nextSignalIndex-1);
        [profile, firstSignalIndex] = initializeThreshold(dppg, fs, params.alphaAmp, ...
            initialRRSamples, nextSignalIndex, searchBlockLength);
        thresholdWriteStart = nextSignalIndex;
        currentRRSamples = initialRRSamples;
        historyStart = length(nD) + 1;
        currentIndex = nextSignalIndex;
        resetIndex = firstSignalIndex + resetSamples;
        continue;
    end

    % Find peak within the crossing region, including its preceding neighbor
    peakSearchStart = max(1, upCrossing - 1);
    [~, relativePeakIndex] = localmax(dppg(peakSearchStart:downCrossing));

    if isnan(relativePeakIndex)
        % No peak found - move to next index
        currentIndex = downCrossing + 1;
        continue;
    end

    % Find peak index
    peakIndex = peakSearchStart + relativePeakIndex - 1;

    % Calculate peak amplitude using adaptive estimation
    numHistoryPulses = length(nD) - historyStart + 1;
    if numHistoryPulses <= minPeaksForRREstimation
        currentAmplitude = max(dppg(upCrossing:downCrossing));
    else
        % Use median of recent peaks for more robust estimation
        recentPeaks = dppg(nD(end-nAmplitudeEstimation:end));
        currentPeak = max(dppg(upCrossing:downCrossing));
        currentAmplitude = median([recentPeaks; currentPeak]);
    end

    % Store detected pulse
    nD = [nD, peakIndex]; %#ok<AGROW>
    numHistoryPulses = length(nD) - historyStart + 1;
    resetIndex = peakIndex + resetSamples;

    % Update RR interval estimate based on detected pulses
    if numHistoryPulses >= (nRREstimation + 1)
        % Use median of recent RR intervals for robust estimation
        recentRRIntervals = diff(nD(end-nRREstimation:end));
        currentRRSamples = round(median(recentRRIntervals));
    elseif numHistoryPulses >= 2
        % Use mean when insufficient data for robust median
        currentRRSamples = round(mean(diff(nD(historyStart:end))));
    end

    % Set refractory period after pulse detection
    refractoryEnd = min(peakIndex + refractPeriodSamples, signalLength);
    currentIndex = refractoryEnd;

    % Finalize the preceding threshold without filling the entire future signal
    threshold(thresholdWriteStart:peakIndex-1) = ...
        thresholdValues(profile, thresholdWriteStart:peakIndex-1);

    % Set threshold to peak amplitude during refractory period
    threshold(peakIndex:refractoryEnd) = currentAmplitude;

    % Calculate threshold fall-off parameters
    fallThreshold = currentAmplitude * params.alphaAmp;

    % Apply amplitude-based correction if we have sufficient pulse history
    if numHistoryPulses >= (nAmplitudeEstimation + 1)
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
    profile.decayStart = refractoryEnd;
    profile.amplitude = currentAmplitude;
    profile.slope = (currentAmplitude - fallThreshold) / fallDuration;
    profile.floorStart = refractoryEnd + fallDuration + 1;
    profile.floorValue = fallThreshold;
    thresholdWriteStart = refractoryEnd;
end

% Complete the final threshold profile
threshold(thresholdWriteStart:end) = ...
    thresholdValues(profile, thresholdWriteStart:signalLength);

% Remove any duplicate indices and sort
nD = unique(nD);

end


function [profile, firstSignalIndex] = initializeThreshold(dppg, fs, alphaAmp, initialRRSamples, startIndex, blockLength)
% Initialize the same amplitude estimate and linear decay used by the detector.
initialWindowDuration = 10; % seconds
amplitudeMultiplier = 3;
signalLength = length(dppg);

firstSignalIndex = findAvailableSample(dppg, startIndex, blockLength);
initWindowEnd = min(firstSignalIndex + round(initialWindowDuration * fs), signalLength);
initialWindow = dppg(firstSignalIndex:initWindowEnd);
initialThreshold = amplitudeMultiplier * mean(initialWindow(initialWindow >= 0), 'omitnan');

profile.decayStart = startIndex;
profile.amplitude = initialThreshold;
profile.slope = initialThreshold * (1 - alphaAmp) / initialRRSamples;
profile.floorValue = alphaAmp * initialThreshold;
profile.floorStart = signalLength + 1;
if startIndex + initialRRSamples < signalLength
    profile.floorStart = startIndex + initialRRSamples;
end
end


function values = thresholdValues(profile, indices)
% Evaluate only the requested part of the current threshold profile.
indices = indices(:);
values = profile.amplitude - profile.slope * (indices - profile.decayStart);
values(indices >= profile.floorStart) = profile.floorValue;
end


function crossing = findCrossing(dppg, profile, startIndex, endIndex, blockLength, upward)
% Search to the end if needed, using bounded temporary arrays and no resets.
crossing = [];
for blockStart = startIndex:blockLength:endIndex
    indices = blockStart:min(blockStart + blockLength - 1, endIndex);
    values = thresholdValues(profile, indices);
    if upward
        relativeIndex = find(dppg(indices) > values, 1, 'first');
    else
        relativeIndex = find(dppg(indices) < values, 1, 'first');
    end
    if ~isempty(relativeIndex)
        crossing = blockStart + relativeIndex - 1;
        return;
    end
end
end


function index = findAvailableSample(dppg, startIndex, blockLength)
% Skip missing samples without allocating a mask for the entire remaining signal.
index = [];
for blockStart = startIndex:blockLength:length(dppg)
    blockEnd = min(blockStart + blockLength - 1, length(dppg));
    relativeIndex = find(~isnan(dppg(blockStart:blockEnd)), 1, 'first');
    if ~isempty(relativeIndex)
        index = blockStart + relativeIndex - 1;
        return;
    end
end
end
