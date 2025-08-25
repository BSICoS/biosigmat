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

% Pulse detection
nD = pulsedetection(signalFiltered, fs);

% Set up pulse delineation parameters
Setup = struct();

% Pulse detection input
Setup.nD = nD;

% Peak delineation windows
Setup.wdw_nA = 250e-3;              % Window for onset detection (s)
Setup.wdw_nB = 150e-3;              % Window for offset detection (s)

fprintf('\nPulse delineation parameters:\n');
fprintf('  Window for onset detection: %.0f ms\n', Setup.wdw_nA * 1000);
fprintf('  Window for offset detection: %.0f ms\n', Setup.wdw_nB * 1000);

% Run pulse delineation on filtered signal
fprintf('\nRunning pulse delineation...\n');
[nA, nB, nM] = pulsedelineation(signalFiltered, fs, Setup);

%% Plot results
fprintf('\nPlotting results...\n');

figure;

ax(1) = subplot(2,1,1); hold on; box on;legend;
plot(t, signal, 'k','LineWidth',1,'DisplayName','Original PPG');
plot(nD(~isnan(nD)), signal(1+round(nD(~isnan(nD))*fs)), 'o','LineWidth',1,'color',[0.47,0.67,0.19],'MarkerFaceColor',[0.47,0.67,0.19],'DisplayName','n_D');
plot(nA(~isnan(nA)), signal(1+round(nA(~isnan(nA))*fs)), 'v','LineWidth',1,'color',[0.00,0.45,0.74],'MarkerFaceColor',[0.00,0.45,0.74],'DisplayName','n_A');
plot(nB(~isnan(nB)), signal(1+round(nB(~isnan(nB))*fs)), '^','LineWidth',1,'color',[0.00,0.45,0.74],'MarkerFaceColor',[0.00,0.45,0.74],'DisplayName','n_B');
title('PPG Delineation');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

ax(2) = subplot(2,1,2); hold on; box on;legend;
plot(t, signalFiltered, 'k','LineWidth',1,'DisplayName','LPD-Filtered PPG');
plot(t, threshold ,'LineWidth',1,'DisplayName','Adaptive Threshold');
plot(nD(~isnan(nD)), signalFiltered(1+round(nD(~isnan(nD))*fs)), 'o','LineWidth',1,'color',[0.47,0.67,0.19],'MarkerFaceColor',[0.47,0.67,0.19],'DisplayName','n_D' );
plot(nA(~isnan(nA)), signalFiltered(1+round(nA(~isnan(nA))*fs)), 'v','LineWidth',1,'color',[0.00,0.45,0.74],'MarkerFaceColor',[0.00,0.45,0.74],'DisplayName','n_A');
plot(nB(~isnan(nB)), signalFiltered(1+round(nB(~isnan(nB))*fs)), '^','LineWidth',1,'color',[0.00,0.45,0.74],'MarkerFaceColor',[0.00,0.45,0.74],'DisplayName','n_B');
xline(0,'k:','HandleVisibility','off');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

linkaxes(ax, 'x');
zoom on