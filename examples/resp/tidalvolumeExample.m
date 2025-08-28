% Add source paths
addpath('../../src/resp');
addpath('../../src/tools');

% Load respiration signal from fixtures
respData = readtable('../../fixtures/ecg/edr_signals.csv');
resp = respData.resp;
fs = 256;
t = (0:length(resp)-1) / fs;

% Detrend
respDetrended = detrend(resp);

% Remove high-frequency noise
[b, a] = butter(4, 1 / (fs/2), 'low');
respFiltered = filtfilt(b, a, respDetrended);

% Extract tidal volume
[tdvol, upper, lower] = tidalvolume(respFiltered, 1.5*fs);


%% Plot results
figure;

ax(1) = subplot(211);
plot(t, respFiltered, 'k','LineWidth',1); hold on
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