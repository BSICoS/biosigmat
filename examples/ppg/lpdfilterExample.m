% LPDFILTER EXAMPLE
%
% This example demonstrates the use of the LPDFILTER function for processing PPG signals.
% It shows how to:
%   - Apply the low-pass derivative filter with default and custom parameters
%   - Visualize filter characteristics: impulse response, frequency response, phase, group delay
%   - Efficiently reuse filter coefficients for processing multiple signals
%   - Handle NaN values in signals
%
% The example uses fixture data from a CSV file containing:
%   - PPG signal sampled at 1000 Hz
%   - PPG pulse annotations

%% Initialization
clear; close all;

% Add source directories to path
addpath(fullfile('..', '..', 'src', 'ppg'));
addpath(fullfile('..', '..', 'src', 'tools'));

%% Load real PPG data
% Read PPG signal and pulses
fixturesPath = fullfile(pwd, '..', '..', 'fixtures', 'ppg');
data = readtable(fullfile(fixturesPath, 'ppg_signals.csv'));
pulses = readtable(fullfile(fixturesPath, 'ppg_pulses.csv'));

% Original sampling frequency and target frequency
fs_orig = 1000;  % Original sampling frequency [Hz]
fs = 1000;         % Target sampling frequency [Hz]
duration = 30;     % Duration of the signal to be used in seconds

% Get 30 seconds of data and resample
t_orig = (0:duration*fs_orig-1)'/fs_orig;
signal_orig = data.sig(1:length(t_orig));

% Resample signal
[signal, t] = resample(signal_orig, t_orig, fs);

% Resample pulse locations
pulses = pulses(pulses.tA <= duration,:);  % Get pulses within 30s

% Add some artificial NaN values to demonstrate NaN handling
nanIdx = round([2.5, 5.0, 7.5] * fs);  % NaN at 2.5s, 5s, and 7.5s
signal(nanIdx) = NaN;

%% Apply LPD filter with different configurations

% Default configuration
[filtered1, coeff1] = lpdfilter(signal, fs);

% Custom configuration with different parameters
[filtered2, coeff2] = lpdfilter(signal, fs, ...
    'Order', 500, ...
    'PassFreq', 9, ...
    'StopFreq', 10);

%% Visualization of Signal Processing Results
figure('Name', 'PPG Signal Processing');

% Plot original signal with pulse annotations
subplot(2, 1, 1);
plot(t, signal, 'b');hold on;
validPulses = pulses.tD <= duration; 
pulseTimes = pulses.tD(validPulses);
pulseIndices = round(pulseTimes * fs) + 1;
plot(pulseTimes, signal(pulseIndices), 'ro', 'MarkerFaceColor', 'r');
title('Original PPG Signal with Detected Pulses');
ylabel('Amplitude');
grid on;
xlim([0 duration]);

% Plot filtered signals
subplot(2, 1, 2);
plot(t, filtered1); hold on; grid on;
plot(t, filtered2);
plot(pulseTimes, filtered1(pulseIndices), 'ro', 'MarkerFaceColor', 'r');
legend('LPD Filtered (Default Parameters)','LPD Filtered (Custom Parameters)');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;
xlim([0 duration]);

%% Filter Characteristics Analysis
figure('Name', 'Filter Characteristics Analysis');

% Plot impulse responses
subplot(2, 2, 1);
stem((0:length(coeff1)-1), coeff1, 'b');
hold on;
stem((0:length(coeff2)-1), coeff2, 'r');
title('Filter Coefficients');
legend('Default', 'Custom');
xlabel('Samples');
ylabel('Amplitude');
grid on;

% Plot frequency responses
subplot(2, 2, 2);
[h1,w] = freqz(coeff1, 1, 1024);
[h2,~] = freqz(coeff2, 1, 1024);
f = w*fs/(2*pi);

plot(f, abs(h1)/max(abs(h1)), 'b', ...
     f, abs(h2)/max(abs(h2)), 'r');
title('Normalized Frequency Response');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
legend('Default', 'Custom');
grid on;
xlim([0 20]);

% Plot phase responses
subplot(2, 2, 3);
plot(f, unwrap(angle(h1))/pi, 'b', ...
     f, unwrap(angle(h2))/pi, 'r');
title('Phase Response');
xlabel('Frequency (Hz)');
ylabel('Phase/\pi rad');
legend('Default', 'Custom');
grid on;
xlim([0 20]);

% Plot group delay
subplot(2, 2, 4);
[gd1,w] = grpdelay(coeff1, 1, 1024);
f = w*fs/(2*pi);
[gd2,~] = grpdelay(coeff2, 1, 1024);

plot(f, gd1/fs*1000, 'b', ...
     f, gd2/fs*1000, 'r');
title('Group Delay');
xlabel('Frequency (Hz)');
ylabel('Delay (ms)');
legend('Default', 'Custom');
grid on;
xlim([0 20]);

%% Filter Coefficient Reuse for Efficiency
% When processing multiple signals with the same parameters,
% you can compute the filter coefficients once and reuse them

% Get filter coefficients (only compute once)
[~, defaultCoeff] = lpdfilter(signal(1:100), fs);
[~, customCoeff] = lpdfilter(signal(1:100), fs, ...
    'PassFreq', 10, 'StopFreq', 11);

% Time the filtering operation with coefficient computation
tic;
[filtered1_withDesign, ~] = lpdfilter(signal, fs);
t1 = toc;

% Time the filtering operation with pre-computed coefficients
tic;
filtered1_preComputed = lpdfilter(signal, fs, 'Coefficients', defaultCoeff);
t2 = toc;

% Display timing results
fprintf('Filtering with coefficient design: %.3f seconds\n', t1);
fprintf('Filtering with pre-computed coefficients: %.3f seconds\n', t2);
fprintf('Speed improvement: %.1fx\n', t1/t2);

% Verify results are identical
disp(['Maximum difference between results: ' ...
    num2str(max(abs(filtered1_withDesign - filtered1_preComputed)))]);

%% Spectral Analysis
% Commented until nanpwelch is implemented
%
% figure('Name', 'Spectral Analysis');
% 
% % Calculate and plot power spectral densities
% [pxx1,f1] = nanpwelch(signal, hamming(256), 128, 1024, fs);
% [pxx2,f2] = nanpwelch(filtered1, hamming(256), 128, 1024, fs);
% [pxx3,f3] = nanpwelch(filtered2, hamming(256), 128, 1024, fs);
% 
% plot(f1, 10*log10(pxx1), 'k', ...
%      f2, 10*log10(pxx2), 'b', ...
%      f3, 10*log10(pxx3), 'r');
% title('Power Spectral Density');
% xlabel('Frequency (Hz)');
% ylabel('Power/frequency (dB/Hz)');
% legend('Original', 'Default LPD', 'Custom LPD');
% grid on;
% xlim([0 20]);
