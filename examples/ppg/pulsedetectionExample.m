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
[nD, threshold] = pulsedetection(signalFiltered, fs);

%% Plot results
fprintf('\nPlotting results...\n');

figure;

ax(1) = subplot(2,1,1); hold on; box on;legend;
plot(t, signal, 'k','LineWidth',1,'DisplayName','Original PPG');
plot(nD(~isnan(nD)), signal(1+round(nD(~isnan(nD))*fs)), 'o','LineWidth',1,'color',[0.47,0.67,0.19],'MarkerFaceColor',[0.47,0.67,0.19],'DisplayName','n_D');
title('PPG Detection');
xlabel('Time (s)');
ylabel('Amplitude');

ax(2) = subplot(2,1,2); hold on; box on;legend;
plot(t, signalFiltered, 'k','LineWidth',1,'DisplayName','LPD-Filtered PPG');
plot(t, threshold ,'LineWidth',1,'DisplayName','Adaptive Threshold');
plot(nD(~isnan(nD)), signalFiltered(1+round(nD(~isnan(nD))*fs)), 'o','LineWidth',1,'color',[0.47,0.67,0.19],'MarkerFaceColor',[0.47,0.67,0.19],'DisplayName','n_D' );
xline(0,'k:','HandleVisibility','off');
xlabel('Time (s)');
ylabel('Amplitude');

linkaxes(ax, 'x');
set(ax,'XminorGrid','on','YminorGrid','on','xminortick','on','yminortick','on');
zoom on