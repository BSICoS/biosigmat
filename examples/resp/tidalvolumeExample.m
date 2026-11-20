% TIDALVOLUMEEXAMPLE Example demonstrating tidal volume estimation from respiration signals.
%
% Low-pass filter a recorded respiratory signal and estimate the amplitude of
% each breath. The second figure shows how MaxGap limits interpolation.


% Add source paths
addpath('../../src/resp');
addpath('../../src/tools');

% Load respiration signal from fixtures
respData = readtable('../../fixtures/ecg/medicom_mtd_ecg_respiration.csv');
resp = respData.respiration;
fs = 256;
t = (0:length(resp)-1) / fs;

% Remove high-frequency noise
[b, a] = butter(4, 1 / (fs/2), 'low');
respFiltered = filtfilt(b, a, resp);

% Extract tidal volume
[tdvol, upper, lower] = tidalvolume(respFiltered, fs, 1);


%% Plot results
figure;

ax(1) = subplot(211);
plot(t, detrend(respFiltered), 'k','LineWidth',1); hold on
plot(t, upper, 'r','LineWidth',1);
plot(t, lower, 'b','LineWidth',1);
legend('Respiration', 'Upper Envelope', 'Lower Envelope');
title('Respiration Signal with Upper and Lower Envelopes');
axis tight;
grid on;

ax(2) = subplot(212);
plot(t, tdvol, 'k','LineWidth',1);
title('Tidal Volume');
xlabel('Time (s)');
axis tight;
grid on;

linkaxes(ax, 'x');
%% Optional MaxGap on a respiratory recording with two artificial gaps
% Remove samples after filtering. A missing interval interrupts detection.
% Each curve applies MaxGap to its own peaks, valleys or cycle midpoints.
maxGap = 15;
gaps = [26 28; 50 70];
missingResp = respFiltered;
for k = 1:size(gaps,1)
    missingResp(t >= gaps(k,1) & t <= gaps(k,2)) = NaN;
end
[volumeLimited, upper, lower] = tidalvolume(missingResp, fs, 1, 'MaxGap', maxGap);

figure('Position', [100 100 1000 510]);
ax(1) = subplot(211);
plot(t, detrend(missingResp, 'omitnan'), 'Color', [.30 .33 .35]); hold on;
plot(t, upper, 'r', 'LineWidth', 1.3);
plot(t, lower, 'b', 'LineWidth', 1.3);
legend('Respiration', 'Upper envelope', 'Lower envelope', 'Location', 'northwest', ...
    'Orientation', 'horizontal');
ylabel('Respiration (a.u.)');
title(sprintf('Respiration and envelopes with MaxGap = %g s', maxGap));
ax(2) = subplot(212);
plot(t, volumeLimited, 'Color', [.08 .43 .53], 'LineWidth', 1.8);
ylabel('Peak-to-valley amplitude (a.u.)');
xlabel('Time (s)');
labels = {'Short gap (interpolated)', 'Long gap (no interpolation)'};
for panel = 1:2
    axes(ax(panel)); hold on;
    xlim([10 88]); limits = ylim;
    for k = 1:size(gaps,1)
        shade = patch(gaps(k,[1 2 2 1]), limits([1 1 2 2]), [.70 .65 .56], ...
            'FaceAlpha', .21, 'EdgeColor', 'none', 'HandleVisibility', 'off');
        uistack(shade, 'bottom');
        if panel == 2
            text(mean(gaps(k,:)), limits(2), labels{k}, 'HorizontalAlignment','center', ...
                'VerticalAlignment','bottom', 'FontSize', 9);
        end
    end
    ylim([limits(1), limits(2) + .15*diff(limits)]);
end
linkaxes(ax, 'x');
