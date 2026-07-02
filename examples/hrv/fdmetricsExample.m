% FDMETRICSEXAMPLE Example demonstrating frequency-domain heart rate variability analysis.
%
% This example demonstrates how to compute frequency-domain heart rate
% variability (HRV) metrics from fixture beat occurrence times and
% respiration signals using the fdmetrics function. The workflow estimates
% the HRV modulating signal with ipfm, computes its power spectral density,
% evaluates conventional LF/HF metrics with limited and unlimited HF bands,
% and then computes OSP-based respiratory and unrelated spectral metrics.

% Add required paths
addpath('../../src/hrv');

% Load beat occurrence times and respiration fixture data
tkData = readtable('../../fixtures/ecg/medicom_mtd_r_wave_timing.csv');
respData = readtable('../../fixtures/ecg/medicom_mtd_ecg_respiration.csv');
fs = 4;

% Compute the HRV modulating signal and align respiration to the same grid
tn = tkData.r_wave_times(1:100);
[~, m] = ipfm(tn, fs);
tm = (tn(1):1/fs:tn(end))';
resp = interp1(respData.time, detrend(respData.respiration), tm, 'pchip');

% Estimate the total and respiratory spectra on a common grid
windowLength = min(256, length(m));
[pxx, f] = pwelch(m, hamming(windowLength), floor(windowLength / 2), [], fs);
[respPxx, ~] = pwelch(resp, hamming(windowLength), floor(windowLength / 2), [], fs);

% Compute conventional and unlimited-HF metrics
classicMetrics = fdmetrics(pxx, f);
unlimitedMetrics = fdmetrics(pxx, f, false);

% Decompose the modulating signal and compute OSP-based frequency metrics
[mResp, mUnrelated, delay] = osp(m, resp, respPxx, f, fs);
windowLengthOsp = min(256, length(mResp));
[mRespPxx, fOsp] = pwelch(mResp, hamming(windowLengthOsp), floor(windowLengthOsp / 2), [], fs);
[mUnrelatedPxx, ~] = pwelch(mUnrelated, hamming(windowLengthOsp), floor(windowLengthOsp / 2), [], fs);
ospMetrics = fdmetrics(mRespPxx, mUnrelatedPxx, fOsp);

% Display the resulting metrics
fprintf('Classic LF/HF metrics:\n');
fprintf('  LF   = %.4f\n', classicMetrics.lf);
fprintf('  HF   = %.4f\n', classicMetrics.hf);
fprintf('  LFn  = %.4f\n', classicMetrics.lfn);
fprintf('  LFHF = %.4f\n\n', classicMetrics.lfhf);

fprintf('Unlimited-HF LF/HF metrics:\n');
fprintf('  LF   = %.4f\n', unlimitedMetrics.lf);
fprintf('  HF   = %.4f\n', unlimitedMetrics.hf);
fprintf('  LFn  = %.4f\n', unlimitedMetrics.lfn);
fprintf('  LFHF = %.4f\n\n', unlimitedMetrics.lfhf);

fprintf('OSP-based metrics:\n');
fprintf('  UrLF = %.4f\n', ospMetrics.urlf);
fprintf('  Re   = %.4f\n', ospMetrics.re);
fprintf('  R    = %.4f\n', ospMetrics.r);