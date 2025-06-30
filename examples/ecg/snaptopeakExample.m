% SNAPTOPEAK EXAMPLE
%
% This example demonstrates the use of the SNAPTOPEAK algorithm for refining R-wave
% detection positions in ECG signals. It shows how to:
%   1. Load ECG data and apply bandpass filtering (similar to Pan-Tompkins preprocessing)
%   2. Load reference R-wave detections and add random perturbations
%   3. Use SNAPTOPEAK to refine the perturbed detections
%   4. Visualize the original ECG with perturbed and refined detections
%
% The example uses fixture data from CSV files containing:
%   - ECG signal sampled at 256 Hz
%   - Reference R-wave detection times

% Add required paths for source code and fixtures
addpath(fullfile('..', '..', 'src', 'tools'));
addpath(fullfile('..', '..', 'fixtures', 'ecg'));

% Define path to fixture data
fixturesPath = fullfile(pwd, '..', '..', 'fixtures', 'ecg');

% Load ECG signals from CSV files
fs = 256;
signalsData = readtable(fullfile(fixturesPath, 'edr_signals.csv'));
detectionsData = readtable(fullfile(fixturesPath, 'ecg_tk.csv'));
tkSamples = detectionsData.tkSamples;

% Extract signals from loaded data
ecg = signalsData.ecg;
ecg = ecg(:);

% Add random perturbations to the detections
rng(42);
maxPerturbation = 10;
perturbations = randi([-maxPerturbation, maxPerturbation], size(tkSamples));
perturbedDetections = tkSamples + perturbations;
perturbedDetections = max(1, min(length(ecg), perturbedDetections));

refinedDetections = snaptopeak(ecg, perturbedDetections, 'WindowSize', 20);


%% Create visualization comparing perturbed and refined detections
figure;

% Plot filtered ECG signal
plot(ecg, 'b-', 'LineWidth', 1, 'DisplayName', 'Filtered ECG');
hold on;

% Plot perturbed detections
plot(perturbedDetections, ecg(perturbedDetections), 'rs', 'MarkerSize', 8, ...
    'MarkerFaceColor', 'r', 'DisplayName', 'Perturbed Detections');

% Plot refined detections
plot(refinedDetections, ecg(refinedDetections), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g', ...
    'DisplayName', 'Original Detections');

% Format plot
axis tight;
xlabel('Time (s)');
ylabel('ECG');
title('SNAPTOPEAK Algorithm: Detection Refinement');
legend('Location', 'best');
grid on;

% Add slider for zooming
slider;