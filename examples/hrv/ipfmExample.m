% IPFMEXAMPLE Example demonstrating IPFM-based instantaneous heart rate estimation.
%
% This example demonstrates how to estimate instantaneous heart rate and the
% normalized modulating signal from beat occurrence times using the ipfm
% function. The process involves loading ECG beat timestamps from a fixture,
% constructing the IPFM spline representation, evaluating it on a uniform
% sampling grid, and visualizing the resulting instantaneous heart rate and
% modulating signal.

% Add required paths
addpath('../../src/hrv');

% Load beat occurrence times from fixture data
tkData = readtable('../../fixtures/ecg/ecg_tk.csv');
tn = tkData.tk(1:100);
fs = 4;

% Build the spline representation and evaluate it on a regular grid
sp = ipfm(tn);
[ihr, m] = ipfm(tn, fs);
tm = (tn(1):1/fs:tn(end))';
ihrFromSpline = spval(sp, tm);

% Visualize the spline evaluation and modulation signal
figure;
subplot(2,1,1);
plot(tm, ihrFromSpline, 'k--', 'DisplayName', 'Spline evaluation');
hold on;
plot(tm, ihr, 'b', 'DisplayName', 'Instantaneous heart rate');
xlabel('Time (s)');
ylabel('Heart rate (Hz)');
title('IPFM-Based Instantaneous Heart Rate');
legend('Location', 'best');
grid on;

subplot(2,1,2);
plot(tm, m, 'r');
xlabel('Time (s)');
ylabel('Modulating signal');
title('Normalized Modulating Signal');
grid on;