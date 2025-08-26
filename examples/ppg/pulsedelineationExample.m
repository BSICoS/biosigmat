% PULSEDELINEATIONEXAMPLE Example demonstrating pulse delineation in PPG signals.
%
% This example demonstrates how to perform detailed pulse delineation in
% photoplethysmographic (PPG) signals using the pulsedelineation function. The
% process requires the PPG signal to be preprocessed with low-pass derivative (LPD)
% filtering before delineation can be applied. The example loads PPG signal data
% from fixture files, applies the necessary preprocessing steps, and uses the
% pulsedelineation algorithm to identify key fiducial points within each pulse
% including onset, peak, and offset locations. Results are visualized showing
% the original PPG signal with detailed pulse delineation markers, demonstrating
% the algorithm's capability to extract morphological features from individual
% cardiac cycles.


% Add source paths
addpath('../../src/ppg');
addpath('../../src/tools');

% Load PPG signal from fixtures
ppgData = readtable('../../fixtures/ppg/ppg_signals.csv');
ppg = ppgData.sig;
t = ppgData.t;
fs = 1000;

% Use only the first 2 minutes of the signal for demonstration
ppg = ppg(1:2*60*fs);
t = t(1:2*60*fs);

% Apply high-pass filter to remove baseline drift
[b, a] = butter(4, 0.5 / (fs/2), 'high');
ppg = filtfilt(b, a, ppg);

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
dppg = filter(b, 1, ppg);
dppg = [dppg(delay+1:end); zeros(delay, 1)];

% Pulse detection
nD = pulsedetection(dppg, fs);

% Run pulse delineation on filtered signal with default parameters
fprintf('\nRunning pulse delineation...\n');
[nA, nB, nM] = pulsedelineation(ppg, fs, nD);


%% Plot results
fprintf('\nPlotting results...\n');

figure;

ax(1) = subplot(2,1,1); hold on; box on;legend;
plot(t, ppg, 'k','LineWidth',1,'DisplayName','Original PPG');
plot(nD(~isnan(nD)), ppg(1+round(nD(~isnan(nD))*fs)), 'o','LineWidth',1,'color',[0.47,0.67,0.19],'MarkerFaceColor',[0.47,0.67,0.19],'DisplayName','n_D');
plot(nA(~isnan(nA)), ppg(1+round(nA(~isnan(nA))*fs)), 'v','LineWidth',1,'color',[0.00,0.45,0.74],'MarkerFaceColor',[0.00,0.45,0.74],'DisplayName','n_A');
plot(nB(~isnan(nB)), ppg(1+round(nB(~isnan(nB))*fs)), '^','LineWidth',1,'color',[0.00,0.45,0.74],'MarkerFaceColor',[0.00,0.45,0.74],'DisplayName','n_B');
title('PPG Delineation');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

ax(2) = subplot(2,1,2); hold on; box on;legend;
plot(t, dppg, 'k','LineWidth',1,'DisplayName','LPD-Filtered PPG');
plot(nD(~isnan(nD)), dppg(1+round(nD(~isnan(nD))*fs)), 'o','LineWidth',1,'color',[0.47,0.67,0.19],'MarkerFaceColor',[0.47,0.67,0.19],'DisplayName','n_D' );
plot(nA(~isnan(nA)), dppg(1+round(nA(~isnan(nA))*fs)), 'v','LineWidth',1,'color',[0.00,0.45,0.74],'MarkerFaceColor',[0.00,0.45,0.74],'DisplayName','n_A');
plot(nB(~isnan(nB)), dppg(1+round(nB(~isnan(nB))*fs)), '^','LineWidth',1,'color',[0.00,0.45,0.74],'MarkerFaceColor',[0.00,0.45,0.74],'DisplayName','n_B');
xline(0,'k:','HandleVisibility','off');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

linkaxes(ax, 'x');
zoom on