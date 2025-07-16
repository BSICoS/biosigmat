% BASELINEREMOVE EXAMPLE
%
% This example demonstrates how to use the baselineremove function to
% remove baseline wander from real ECG signals.

% Clean workspace
clear; close all; clc;

% Add necessary paths
addpath('../../src/ecg');
addpath('../../src/tools');
addpath('../../fixtures/ecg');

%% Load real ECG data from fixtures

% Load ECG signal data
edrData = readmatrix('../../fixtures/ecg/edr_signals.csv');
t = edrData(:, 1);
ecgSignal = edrData(:, 2);

% Load R-peak detection data
tkData = readmatrix('../../fixtures/ecg/ecg_tk.csv');
rPeakTimes = tkData(:, 1);
rPeakSamples = tkData(:, 2);

fs = 256;

%% Example 1: Basic baseline removal

% Define fiducial points (PR interval: 80ms before R-peaks)
prInterval = round(0.08 * fs);  % 80ms in samples
fiducialPoints = rPeakSamples - prInterval;

% Remove baseline using baselineremove function
[ecgCorrected, baselineEstimate, fiducialValues] = baselineremove(ecgSignal, fiducialPoints);

% Plot results
figure;

ax(1) = subplot(2,1,1);
plot(t, ecgSignal, 'b', 'LineWidth', 1.5);
hold on;
plot(t, baselineEstimate, 'r--', 'LineWidth', 2);
plot(rPeakTimes, ecgSignal(rPeakSamples), 'go', 'MarkerSize', 4, 'MarkerFaceColor', 'g');
plot(t(fiducialPoints), ecgSignal(fiducialPoints), 'ko', 'MarkerSize', 4, 'MarkerFaceColor', 'k');
title('Original ECG Signal with Estimated Baseline');
xlabel('Time (s)');
ylabel('Amplitude');
legend('ECG Signal', 'Estimated Baseline', 'R-peaks', 'Fiducial Points', 'Location', 'best');
grid on;

ax(2) = subplot(2,1,2);
plot(t, ecgCorrected, 'b', 'LineWidth', 1.5);
hold on;
plot(rPeakTimes, ecgCorrected(rPeakSamples), 'go', 'MarkerSize', 4, 'MarkerFaceColor', 'g');
plot(t(fiducialPoints), ecgCorrected(fiducialPoints), 'ko', 'MarkerSize', 4, 'MarkerFaceColor', 'k');
title('Baseline-Corrected ECG Signal');
xlabel('Time (s)');
ylabel('Amplitude');
legend('Corrected ECG', 'R-peaks', 'Fiducial Points', 'Location', 'best');
grid on;

linkaxes(ax, 'x');