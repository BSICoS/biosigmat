% PULSEENVELOPESEXAMPLE Example demonstrating envelope estimation in PPG signals.
%
% This example demonstrates how to estimate lower and upper envelopes of a
% photoplethysmographic (PPG) signal using the pulseenvelopes function.
% The workflow loads a sample PPG signal from fixtures, detects pulse
% maximum upslopes using pulsedet on an LPD-filtered signal, and
% then estimates both envelopes by interpolating pulse-anchored extrema.


% Add source paths
addpath('../../src/ppg');
addpath('../../src/tools');

% Load PPG signal from fixtures
ppgData = readtable('../../fixtures/ppg/ppg_signals.csv');
ppg = ppgData.sig;
t = ppgData.t;
fs = 1000;

% Use only a short segment for demonstration
ppg = ppg(1:20*fs);
t = t(1:20*fs);

% Apply LPD (Low-Pass Differentiator) filter on the PPG for pulse detection
fpLPD = 7.8;        % Pass-band frequency (Hz)
fcLPD = 8;          % Cut-off frequency (Hz)
orderLPD = 100;     % Filter order (samples)

fprintf('\nApplying LPD filter...\n');
[b, delay] = lpdfilter(fs, fcLPD, 'PassFreq', fpLPD, 'Order', orderLPD);
dppg = filter(b, 1, ppg);
dppg = [dppg(delay+1:end); zeros(delay, 1)];

% Pulse detection (times in seconds)
fprintf('Running pulse detection...\n');
tD = pulsedet(dppg, fs);

% Envelope estimation
fprintf('Estimating envelopes...\n');
[lowerEnvelope, upperEnvelope] = pulseenvelopes(ppg, fs, tD);

%% Plot results
fprintf('Plotting results...\n');

figure;
hold on; box on; grid on;
plot(t, ppg, 'k', 'LineWidth', 1, 'DisplayName', 'PPG');
plot(t, lowerEnvelope, 'b', 'LineWidth', 1.5, 'DisplayName', 'Lower envelope');
plot(t, upperEnvelope, 'r', 'LineWidth', 1.5, 'DisplayName', 'Upper envelope');

validTD = ~isnan(tD);
plot(tD(validTD), ppg(1+round(tD(validTD)*fs)), 'o', ...
    'Color', [0.47,0.67,0.19], 'MarkerFaceColor', [0.47,0.67,0.19], ...
    'DisplayName', 't_D');

xlabel('Time (s)');
ylabel('Amplitude');
title('PPG Envelope Estimation with pulseenvelopes');
legend('Location', 'best');
