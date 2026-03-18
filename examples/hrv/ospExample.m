% OSPEXAMPLE Example demonstrating orthogonal subspace projection decomposition of HRV modulation.
%
% This example demonstrates how to decompose an HRV modulating signal into a
% component linearly related to respiration and a residual component using the
% osp function. The workflow loads repository fixtures for beat occurrence
% times and ECG-derived respiration, computes the modulating signal with ipfm,
% estimates the respiratory spectrum, and visualizes the delayed decomposition.

% Add required paths
addpath('../../src/hrv');

% Load beat occurrence times and respiration fixture data
tkData = readtable('../../fixtures/ecg/ecg_tk.csv');
respData = readtable('../../fixtures/ecg/edr_signals.csv');
fs = 4;

% Compute the HRV modulating signal and align respiration to the same grid
tn = tkData.tk(1:100);
[~, m] = ipfm(tn, fs);
tm = (tn(1):1/fs:tn(end))';
resp = interp1(respData.t, detrend(respData.resp), tm, 'pchip');

% Estimate the respiratory spectrum on the aligned signal
windowLength = min(256, length(resp));
[respPxx, f] = pwelch(resp, hamming(windowLength), floor(windowLength / 2), [], fs);

% Decompose the modulating signal using orthogonal subspace projection
[mResp, mUnrelated, delay] = osp(m, resp, respPxx, f, fs);
tmDelayed = tm(delay:end);

% Visualize the decomposition
figure
subplot(4,1,1);
plot(tm, resp, 'Color', [0.24 0.35 0.74], 'LineWidth', 1.4);
ylabel('$r(n)$', 'Interpreter', 'latex');
title('OSP Decomposition of HRV Modulating Signal');
subplot(4,1,2);
plot(tm, m, 'Color', [0.70 0.70 0.72], 'LineWidth', 2.2);
ylabel('$m(n)$', 'Interpreter', 'latex');
subplot(4,1,3);
plot(tmDelayed, mUnrelated, 'Color', [0.20 0.20 0.20], 'LineWidth', 1.5);
ylabel('$\hat{m}_{\perp}(n)$', 'Interpreter', 'latex');
subplot(4,1,4);
plot(tmDelayed, mResp, 'Color', [0.20 0.20 0.20], 'LineWidth', 1.5, 'LineStyle', ':');
ylabel('$\hat{m}_{r}(n)$', 'Interpreter', 'latex');
xlabel('Time (seconds)');