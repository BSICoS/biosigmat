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
[mResp, mUnrelated, delay] = osp(resp, respPxx, f, m, fs);

% Visualize the original delayed signal and the two components
figure;
subplot(2,1,1);
plot(tm, resp, 'b');
xlabel('Time (s)');
ylabel('Respiration');
title('Respiration Aligned to the HRV Sampling Grid');
grid on;

subplot(2,1,2);
plot(tm(delay:end), m(delay:end), 'k', 'DisplayName', 'm(t)');
hold on;
plot(tm(delay:end), mResp, 'b', 'DisplayName', 'Respiratory component');
plot(tm(delay:end), mUnrelated, 'r', 'DisplayName', 'Unrelated component');
xlabel('Time (s)');
ylabel('Modulating signal');
title('Orthogonal Subspace Projection Decomposition');
legend('Location', 'best');
grid on;