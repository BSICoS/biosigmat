% BASELINEREMOVEEXAMPLE Example demonstrating baseline wander removal from ECG signals.
%
% This example demonstrates how to effectively remove baseline wander from real ECG
% signals using the baselineremove function. The process involves loading ECG signal
% data from a CSV file and applying baseline removal techniques to eliminate
% low-frequency artifacts that can interfere with ECG analysis. The example shows
% the comparison between original and processed signals through visualization,
% highlighting the effectiveness of the baseline removal algorithm in preserving
% the ECG morphology while eliminating unwanted baseline drift.


% Add necessary paths
addpath('../../src/ecg');
addpath('../../src/tools');
addpath('../../fixtures/ecg');

% Load ECG signal data
edrData = readmatrix('../../fixtures/ecg/edr_signals.csv');
t = edrData(:, 1);
ecg = edrData(:, 2);

% Load R-peak detection data
tkData = readmatrix('../../fixtures/ecg/ecg_tk.csv');
rPeakTimes = tkData(:, 1);
tk = tkData(:, 2);

fs = 256;

% Define fiducial points offset (PR interval: 150ms before R-peaks)
offset = round(0.15 * fs);

% Remove baseline using baselineremove function
[ecgDetrended, baseline] = baselineremove(ecg, tk, offset);

% Calculate fiducial points for plotting
fiducialPoints = tk - offset;

%% Plot results
figure;

ax(1) = subplot(2,1,1);
plot(t, ecg, 'b', 'LineWidth', 1.5);
hold on;
plot(t, baseline, 'r--', 'LineWidth', 2);
plot(rPeakTimes, ecg(tk), 'go', 'MarkerSize', 4, 'MarkerFaceColor', 'g');
plot(t(fiducialPoints), ecg(fiducialPoints), 'ko', 'MarkerSize', 4, 'MarkerFaceColor', 'k');
title('Original ECG Signal with Estimated Baseline');
xlabel('Time (s)');
ylabel('Amplitude');
legend('ECG Signal', 'Estimated Baseline', 'R-peaks', 'Fiducial Points', 'Location', 'best');
grid on;

ax(2) = subplot(2,1,2);
plot(t, ecgDetrended, 'b', 'LineWidth', 1.5);
hold on;
plot(rPeakTimes, ecgDetrended(tk), 'go', 'MarkerSize', 4, 'MarkerFaceColor', 'g');
plot(t(fiducialPoints), ecgDetrended(fiducialPoints), 'ko', 'MarkerSize', 4, 'MarkerFaceColor', 'k');
title('Baseline-Corrected ECG Signal');
xlabel('Time (s)');
ylabel('Amplitude');
legend('Corrected ECG', 'R-peaks', 'Fiducial Points', 'Location', 'best');
grid on;

linkaxes(ax, 'x');