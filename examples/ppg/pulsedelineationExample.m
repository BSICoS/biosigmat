%% PPG Pulse Delineation Example
% This example demonstrates how to use the pulsedelineation function to
% delineate a PPG signal. The signal must be LPD-filtered before using pulsedelineation.

% Add source paths
addpath('../../src/ppg');
addpath('../../src/tools');

%% Load PPG signal from fixtures
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

%% Apply LPD (Low-Pass Differentiator) filter
% The pulseDelineation function now expects a pre-filtered signal
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

%% Set up pulse delineation parameters
Setup = struct();

% Adaptive threshold parameters
Setup.alfa = 0.2;                   % Threshold adaptation factor
Setup.refractPeriod = 150e-3;       % Refractory period (s)
Setup.thrIncidences = 1.5;          % Threshold for incidences

% Peak delineation windows
Setup.wdw_nA = 250e-3;              % Window for onset detection (s)
Setup.wdw_nB = 150e-3;              % Window for offset detection (s)

fprintf('\nPulse delineation parameters:\n');
fprintf('  Threshold adaptation factor: %.1f\n', Setup.alfa);
fprintf('  Refractory period: %.0f ms\n', Setup.refractPeriod * 1000);

%% Run pulse delineation on filtered signal
fprintf('\nRunning pulse delineation...\n');
[nD, nA, nB, nM, threshold] = pulsedelineation(signalFiltered, fs, Setup);

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

ax(2) = subplot(2,1,2); hold on; box on;legend;
plot(t, signalFiltered, 'k','LineWidth',1,'DisplayName','LPD-Filtered PPG');
plot(t, threshold ,'LineWidth',1,'DisplayName','Adaptive Threshold');
plot(nD(~isnan(nD)), signalFiltered(1+round(nD(~isnan(nD))*fs)), 'o','LineWidth',1,'color',[0.47,0.67,0.19],'MarkerFaceColor',[0.47,0.67,0.19],'DisplayName','n_D' );
plot(nA(~isnan(nA)), signalFiltered(1+round(nA(~isnan(nA))*fs)), 'v','LineWidth',1,'color',[0.00,0.45,0.74],'MarkerFaceColor',[0.00,0.45,0.74],'DisplayName','n_A');
plot(nB(~isnan(nB)), signalFiltered(1+round(nB(~isnan(nB))*fs)), '^','LineWidth',1,'color',[0.00,0.45,0.74],'MarkerFaceColor',[0.00,0.45,0.74],'DisplayName','n_B');
xline(0,'k:','HandleVisibility','off');
xlabel('Time (s)');
ylabel('Amplitude');

linkaxes(ax, 'x');
set(ax,'XminorGrid','on','YminorGrid','on','xminortick','on','yminortick','on');
zoom on