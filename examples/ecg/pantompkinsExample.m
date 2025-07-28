% PANTOMPKINSEXAMPLE Example demonstrating R-wave detection using Pan-Tompkins algorithm.
%
% This example demonstrates the implementation of the Pan-Tompkins algorithm for
% reliable R-wave detection in ECG signals. The process begins by loading ECG data
% sampled at 256 Hz from fixture files. The Pan-Tompkins algorithm is then applied
% to detect R-wave peaks through a series of filtering and processing steps including
% bandpass filtering, differentiation, squaring, and integration. The example provides
% comprehensive visualization of all intermediate processing steps, showing the
% filtered signal, squared derivative, integrated envelope, and final R-wave detection
% results, allowing users to understand each stage of the algorithm's operation.


% Add required paths for source code and fixtures
addpath(fullfile('..', '..', 'src', 'ecg'));
addpath(fullfile('..', '..', 'src', 'tools'));
addpath(fullfile('..', '..', 'fixtures', 'ecg'));

% Define path to fixture data
fixturesPath = fullfile(pwd, '..', '..', 'fixtures', 'ecg');

% Load ECG signals from CSV files
signalsData = readtable(fullfile(fixturesPath, 'edr_signals.csv'));

% Sampling frequency for the CSV data
fs = 256;

% Extract signals from loaded data
ecg = signalsData.ecg;
t = (0:length(ecg) - 1) / fs;

% Ensure ECG is a column vector
ecg = ecg(:);

% Apply the PANTOMPKINS algorithm to detect R-waves and get all intermediate signals
[tk, ecgFiltered, decg, decgEnvelope] = pantompkins(ecg, fs);


%% Create visualization of results with multiple subplots
figure;

% Subplot 1: Original ECG with detected R-waves
ax(1) = subplot(4, 1, 1);
plot(t, ecg, 'b-', 'LineWidth', 1);
hold on;
plot(tk, ecg(round(tk * fs) + 1), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
axis tight;
ylabel('ECG');
title('Original ECG Signal with Detected R-waves');
grid on;

% Subplot 2: Bandpass filtered ECG
ax(2) = subplot(4, 1, 2);
plot(t, ecgFiltered, 'g-', 'LineWidth', 1);
hold on;
plot(tk, ecgFiltered(round(tk * fs) + 1), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
axis tight;
ylabel('Filtered ECG');
title('Bandpass Filtered ECG Signal (5-15 Hz)');
grid on;

% Subplot 3: Squared derivative
ax(3) = subplot(4, 1, 3);
plot(t, decg, 'm-', 'LineWidth', 1);
axis tight;
ylabel('Squared Derivative');
title('Squared Derivative of Filtered ECG');
grid on;

% Subplot 4: Integrated envelope with detected peaks
ax(4) = subplot(4, 1, 4);
plot(t, decgEnvelope, 'r-', 'LineWidth', 1);
hold on;
% Plot detected peak locations on the envelope
peakIndices = round(tk * fs);
plot(tk, decgEnvelope(peakIndices), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 6);
axis tight;
ylabel('Envelope');
xlabel('Time (s)');
title('Integrated Envelope with Detected Peaks');
grid on;

sgtitle('Pan-Tompkins Algorithm: Signal Processing Steps');
linkaxes(ax, 'x');
slider;
