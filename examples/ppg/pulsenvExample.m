% PULSENVEXAMPLE Example demonstrating envelope estimation in PPG signals.
%
% This example demonstrates how to estimate lower and upper envelopes of a
% photoplethysmographic (PPG) signal using the pulsenv function.
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
[lowerEnvelope, upperEnvelope] = pulsenv(ppg, fs, tD);

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
title('PPG Envelope Estimation with pulsenv');
legend('Location', 'best');

%% Optional MaxGap on a PPG with two artificial gaps
% Remove observed samples after detection. The shaded intervals mark
% missing PPG. MaxGap is measured separately between successive basal
% points and between successive apex points.
maxGap = 2;
gaps = [tD(6)-.22, tD(6)+.24; tD(12)-.22, tD(15)+.24];
missingPPG = ppg;
for k = 1:size(gaps,1)
    missingPPG(t >= gaps(k,1) & t <= gaps(k,2)) = NaN;
end
[tA, tB] = pulsedel(missingPPG, fs, tD);
[lowerEnvelope, upperEnvelope] = pulsenv(missingPPG, fs, 'tA', tA, 'tB', tB, ...
    'MaxGap', maxGap);

figure('Position', [100 100 1000 370]);
hold on;
colors = [0.08 0.43 0.53; 0.68 0.27 0.12];
plot(t, missingPPG, 'Color', [0.38 0.41 0.43], 'DisplayName', 'PPG');
plot(t, lowerEnvelope, 'Color', colors(1,:), 'LineWidth', 1.7, 'DisplayName', 'Lower envelope');
plot(t, upperEnvelope, 'Color', colors(2,:), 'LineWidth', 1.7, 'DisplayName', 'Upper envelope');
basal = 1+round(tB(isfinite(tB))*fs);
apex = 1+round(tA(isfinite(tA))*fs);
scatter(t(basal), missingPPG(basal), 14, colors(1,:), 'filled', 'HandleVisibility', 'off');
scatter(t(apex), missingPPG(apex), 14, colors(2,:), 'filled', 'HandleVisibility', 'off');
xlim([tD(3)-.16, tD(19)+.4]);
limits = ylim;
labels = {'Short gap (interpolated)', 'Long gap (no interpolation)'};
for k = 1:size(gaps,1)
    x = gaps(k,[1 2 2 1]);
    shade = patch(x, limits([1 1 2 2]), [0.70 0.65 0.56], 'FaceAlpha', .21, ...
        'EdgeColor', 'none', 'HandleVisibility', 'off');
    uistack(shade,'bottom');
    text(mean(gaps(k,:)), limits(2), labels{k}, 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', 'FontSize', 9);
end
ylim([limits(1), limits(2)+.1*diff(limits)]);
xlabel('Time (s)');
ylabel('PPG (a.u.)');
title('PPG envelopes with MaxGap = 2 s');
legend('Location', 'southoutside', 'Orientation', 'horizontal', 'Box', 'off');
