% SLOPERANGEEXAMPLE Example demonstrating ECG-derived respiration using slope range method
%
% This example shows how to:
%   - Load ECG signals and R-peak timing data
%   - Preprocess ECG signal with bandpass filtering
%   - Calculate ECG derivative for slope analysis
%   - Apply the sloperange function to extract respiratory signal
%   - Visualize the results with multiple subplots
%
% The example uses fixture data from CSV files containing:
%   - ECG signal sampled at 256 Hz
%   - Pre-calculated R-peak timing in seconds

% Add required paths for source code and fixtures
addpath(fullfile('..', '..', 'src', 'ecg'));
addpath(fullfile('..', '..', 'src', 'tools'));
addpath(fullfile('..', '..', 'fixtures', 'ecg'));

% Define path to fixture data
fixturesPath = fullfile(pwd, '..', '..', 'fixtures', 'ecg');

% Load ECG signals and R-peak timing data from CSV files
signalsData = readtable(fullfile(fixturesPath, 'edr_signals.csv'));
peaksData = readtable(fullfile(fixturesPath, 'ecg_tk.csv'));

% Sampling frequency for the CSV data
fs = 256;

% Extract signals from loaded data
ecg = signalsData.ecg;
tk = peaksData.tk;  % Pre-calculated R-peaks in seconds
nk = round(tk * fs) + 1;  % Convert to sample indices

% Ensure ECG is a column vector
ecg = ecg(:);

% Calculate the first derivative of the ECG signal
decg = diff(ecg);
decg = [decg(1); decg];  % Pad to maintain original length

% Apply sloperange function to extract EDR signal
[edr, upslopes, downslopes, upslopeMaxPosition, downslopeMinPosition] = sloperange(decg, tk, fs);


%% Create visualization of results
figure;
t = (0:length(decg) - 1) / fs;

% Plot 1: ECG signal with detected R-peaks
ax(1) = subplot(311);
plot(t, ecg);
hold on;
plot(tk, ecg(nk), 'o');
axis tight;
ylabel('ECG');
title('Beat detection');

% Plot 2: ECG derivative with upslope and downslope intervals
ax(2) = subplot(312);
plot(t, decg);
hold on;
plot(t, upslopes, 'linewidth', 3);
plot(t, downslopes, '--', 'linewidth', 3);
plot(t(upslopeMaxPosition), upslopes(upslopeMaxPosition), 'v');
plot(t(downslopeMinPosition), downslopes(downslopeMinPosition), '^');
axis tight;
ylabel('1st der ECG');
title('Intervals for upslope (black) and downslope (magenta)');

% Plot 3: Extracted EDR signal
ax(3) = subplot(313);
plot(tk, edr);
axis tight;
title('Slope range');
xlabel('time (s)');

% Link axes for synchronized zooming and enable interactive slider
linkaxes(ax, 'x');
slider;
