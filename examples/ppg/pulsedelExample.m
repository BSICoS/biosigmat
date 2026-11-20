% PULSEDELEXAMPLE Example demonstrating pulse delineation in PPG signals.
%
% Detect pulses and delineate the apex, basal point, mid-amplitude point
% and onset of each pulse. Both methods use the same delay-aligned
% derivative. The onset is marked separately from the basal minimum.


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
tD = pulsedet(dppg, fs);

% Run pulse delineation using the same derivative as the detector
fprintf('\nRunning pulse delineation...\n');
[tA, tB, tM, tO] = pulsedel(ppg, fs, tD, dppg);


%% Plot results
fprintf('\nPlotting results...\n');

figure;

ax(1) = subplot(2,1,1); hold on; box on;legend;
plot(t, ppg, 'k','LineWidth',1,'DisplayName','Original PPG');
plot(tD(~isnan(tD)), ppg(1+round(tD(~isnan(tD))*fs)), 'o','LineWidth',1,'color',[0.47,0.67,0.19],'MarkerFaceColor',[0.47,0.67,0.19],'DisplayName','t_D');
plot(tA(~isnan(tA)), ppg(1+round(tA(~isnan(tA))*fs)), 'v','LineWidth',1,'color',[0.00,0.45,0.74],'MarkerFaceColor',[0.00,0.45,0.74],'DisplayName','t_A');
plot(tB(~isnan(tB)), ppg(1+round(tB(~isnan(tB))*fs)), '^','LineWidth',1,'color',[0.00,0.45,0.74],'MarkerFaceColor',[0.00,0.45,0.74],'DisplayName','t_B');
plot(tM(~isnan(tM)), ppg(1+round(tM(~isnan(tM))*fs)), 's','LineWidth',1,'color',[0.85,0.33,0.10],'MarkerFaceColor',[0.85,0.33,0.10],'DisplayName','t_M');
plot(tO(~isnan(tO)), ppg(1+round(tO(~isnan(tO))*fs)), 'd','LineWidth',1,'color',[0.49,0.18,0.56],'MarkerFaceColor',[0.49,0.18,0.56],'DisplayName','t_O');
title('PPG Delineation');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

ax(2) = subplot(2,1,2); hold on; box on;legend;
plot(t, dppg, 'k','LineWidth',1,'DisplayName','LPD-Filtered PPG');
plot(tD(~isnan(tD)), dppg(1+round(tD(~isnan(tD))*fs)), 'o','LineWidth',1,'color',[0.47,0.67,0.19],'MarkerFaceColor',[0.47,0.67,0.19],'DisplayName','t_D' );
plot(tA(~isnan(tA)), dppg(1+round(tA(~isnan(tA))*fs)), 'v','LineWidth',1,'color',[0.00,0.45,0.74],'MarkerFaceColor',[0.00,0.45,0.74],'DisplayName','t_A');
plot(tB(~isnan(tB)), dppg(1+round(tB(~isnan(tB))*fs)), '^','LineWidth',1,'color',[0.00,0.45,0.74],'MarkerFaceColor',[0.00,0.45,0.74],'DisplayName','t_B');
plot(tM(~isnan(tM)), dppg(1+round(tM(~isnan(tM))*fs)), 's','LineWidth',1,'color',[0.85,0.33,0.10],'MarkerFaceColor',[0.85,0.33,0.10],'DisplayName','t_M');
plot(tO(~isnan(tO)), dppg(1+round(tO(~isnan(tO))*fs)), 'd','LineWidth',1,'color',[0.49,0.18,0.56],'MarkerFaceColor',[0.49,0.18,0.56],'DisplayName','t_O');
xline(0,'k:','HandleVisibility','off');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

linkaxes(ax, 'x');
zoom on