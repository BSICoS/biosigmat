% PULSEDETECTIONEXAMPLE Example demonstrating pulse detection in PPG signals.
%
% This example demonstrates how to detect individual pulses in photoplethysmographic
% (PPG) signals using the pulsedetection function. The process requires the PPG signal
% to be preprocessed with low-pass derivative (LPD) filtering before pulse detection
% can be applied. The example loads PPG signal data from fixture files, applies the
% necessary preprocessing steps, and uses the pulsedetection algorithm to identify
% pulse locations. Results are visualized showing the original PPG signal with
% detected pulse markers, demonstrating the algorithm's effectiveness in identifying
% individual cardiac cycles within the PPG waveform.


% Add source paths
addpath('../../src/ppg');
addpath('../../src/tools');

% Load PPG signal from fixtures
ppgData = readtable('../../fixtures/ppg/ppg_signals.csv');
signal = ppgData.sig;
t = ppgData.t;
fs = 1000;

% Use only the first 2 minutes of the signal for demonstration
signal = signal(1:2*60*fs);
t = t(1:2*60*fs);

% Apply high-pass filter to remove baseline drift
[b, a] = butter(4, 0.5 / (fs/2), 'high');
signal = filtfilt(b, a, signal);

% Apply LPD (Low-Pass Differentiator) filter
fpLPD = 7.8;        % Pass-band frequency (Hz)
fcLPD = 8;          % Cut-off frequency (Hz)
orderLPD = 100;     % Filter order (samples)

fprintf('\nApplying LPD filter...\n');
fprintf('  Pass-band frequency: %.1f Hz\n', fpLPD);
fprintf('  Cut-off frequency: %.1f Hz\n', fcLPD);
fprintf('  Filter order: %d samples\n', orderLPD);

% Generate LPD filter and apply it
[b, delay] = lpdfilter(fs, fcLPD, 'PassFreq', fpLPD, 'Order', orderLPD);
signalFiltered = filter(b, 1, signal);
signalFiltered = [signalFiltered(delay+1:end); zeros(delay, 1)];

% Run pulse detection on filtered signal
fprintf('\nRunning pulse detection...\n');
[tD, threshold] = pulsedetection(signalFiltered, fs);

%% Plot results
fprintf('\nPlotting results...\n');

figure;

ax(1) = subplot(2,1,1); hold on; box on;legend;
plot(t, signal, 'k','LineWidth',1,'DisplayName','Original PPG');
plot(tD(~isnan(tD)), signal(1+round(tD(~isnan(tD))*fs)), 'o','LineWidth',1,'color',[0.47,0.67,0.19],'MarkerFaceColor',[0.47,0.67,0.19],'DisplayName','t_D');
title('PPG Detection');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

ax(2) = subplot(2,1,2); hold on; box on;legend;
plot(t, signalFiltered, 'k','LineWidth',1,'DisplayName','LPD-Filtered PPG');
plot(t, threshold ,'LineWidth',1,'DisplayName','Adaptive Threshold');
plot(tD(~isnan(tD)), signalFiltered(1+round(tD(~isnan(tD))*fs)), 'o','LineWidth',1,'color',[0.47,0.67,0.19],'MarkerFaceColor',[0.47,0.67,0.19],'DisplayName','t_D' );
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

linkaxes(ax, 'x');

%% Optional feature: reinitialize after a device gain change
% ResetAfter is disabled by default (Inf): the detector keeps its adaptive
% state even during long periods without detections. Set a finite duration in
% seconds to allow reinitialization after that time without a detected pulse.
%
% One possible application is a device that changes its acquisition gain.
% If the gain decreases substantially, the previous threshold floor can remain
% above the new pulses and prevent the detector from recovering on its own.
% Here we simulate an interruption followed by a gain reduction to demonstrate
% how enabling ResetAfter can help. This is an illustrative setting, not a
% universal reset duration for all devices or recordings.
%
% The pulse morphology comes from real PPG: concatenate three fixture copies
% to obtain 15 minutes. The interruption and gain change are introduced below;
% they are not events observed in the original recording. Filter first so the
% inserted NaNs do not propagate through the preprocessing filters.
recoveryFs = fs;
recoverySignal = repmat(ppgData.sig, 3, 1);
[bRecovery, aRecovery] = butter(4, 0.5 / (recoveryFs/2), 'high');
recoverySignal = filtfilt(bRecovery, aRecovery, recoverySignal);
recoverySignal = filter(b, 1, recoverySignal);
recoverySignal = [recoverySignal(delay+1:end); zeros(delay, 1)];
recoveryTime = (0:length(recoverySignal)-1)/recoveryFs;
resetAfter = 5;

% Control: run the same recorded signal with the optional feature disabled
% and enabled, before introducing the simulated interruption and gain change.
tDOriginalWithoutReset = pulsedetection(recoverySignal, recoveryFs);
tDOriginalWithReset = pulsedetection(recoverySignal, recoveryFs, 'ResetAfter', resetAfter);

% Simulate 10 seconds of unavailable data, followed by a device gain of 0.05
% times its previous value. Scaling the filtered waveform preserves the real
% pulse shapes while isolating the amplitude change from filter transients.
gapStart = height(ppgData)/recoveryFs;
gapEnd = gapStart + 10;
amplitudeFactor = 0.05;
recoverySignal(recoveryTime >= gapStart & recoveryTime < gapEnd) = NaN;
recoverySignal(recoveryTime >= gapEnd) = amplitudeFactor*recoverySignal(recoveryTime >= gapEnd);

% Compare the identical modified input in both conditions. Without reset,
% the old threshold may remain too high. With ResetAfter = 5 s, the missing
% span has already exceeded the timeout when data returns, so the detector
% reinitializes using the available signal at its new amplitude.
[tDWithoutReset, thresholdWithoutReset] = pulsedetection(recoverySignal, recoveryFs);
[tDWithReset, thresholdWithReset] = pulsedetection(recoverySignal, recoveryFs, 'ResetAfter', resetAfter);

% Left panels show the interruption and gain change; right panels zoom into
% recovery. Each column uses matching axes for a direct comparison.
figure;
for condition = 1:2
    if condition == 1
        detectionTimes = tDWithoutReset;
        recoveryThreshold = thresholdWithoutReset;
        conditionTitle = 'Reset disabled';
    else
        detectionTimes = tDWithReset;
        recoveryThreshold = thresholdWithReset;
        conditionTitle = sprintf('ResetAfter = %g s', resetAfter);
    end
    for view = 1:2
        if view == 1
            limits = [gapStart-8, gapEnd+15];
        else
            limits = [gapEnd, gapEnd+12];
        end
        visible = recoveryTime >= limits(1) & recoveryTime <= limits(2);
        visibleDetections = detectionTimes >= limits(1) & detectionTimes <= limits(2);
        panel = (condition-1)*2 + view;
        recoveryAxes(panel) = subplot(2,2,panel); hold on; box on;
        plot(recoveryTime(visible), recoverySignal(visible), 'k', 'DisplayName', 'Recorded pulse morphology');
        plot(recoveryTime(visible), recoveryThreshold(visible), 'r', 'DisplayName', 'Adaptive threshold');
        visibleTimes = detectionTimes(visibleDetections);
        plot(visibleTimes, recoverySignal(1+round(visibleTimes*recoveryFs)), 'bo', 'DisplayName', 't_D');
        xlim(limits);
        if view == 1
            title([conditionTitle, ' - interruption and amplitude change']);
            xline(gapStart, '--', 'Simulated gap', 'HandleVisibility', 'off');
            xline(gapEnd, '--', 'Amplitude x 0.05', 'HandleVisibility', 'off');
        else
            title([conditionTitle, ' - recovery detail']);
        end
        xlabel('Time (s)'); ylabel('Amplitude (a.u.)'); grid on;
        if panel == 1, legend('Location', 'best'); end
    end
end
linkaxes(recoveryAxes([1,3]), 'xy');
linkaxes(recoveryAxes([2,4]), 'xy');
