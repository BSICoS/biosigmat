# `osp`

Decompose the HRV modulating signal into respiratory and unrelated components.

## Syntax

```matlab
function [mResp, mUnrelated, delay] = osp(m, resp, respPxx, f, fs, varargin)
```

## Description

[MRESP, MUNRELATED, DELAY] = OSP(M, RESP, RESPPXX, F, FS) decomposes the HRV modulating signal M into a component linearly related to the respiration signal RESP and a residual component containing the remaining dynamics. RESP must be sampled at the same sampling frequency FS and aligned in time with M. RESPPXX is the respiratory power spectral density evaluated on the frequency vector F. MRESP and MUNRELATED correspond to the delayed segment M(DELAY:END), where DELAY is the model order estimated from the dominant respiratory frequency. If M or RESP is empty, MRESP and MUNRELATED are returned as empty vectors. If either input signal contains NaN values, MRESP and MUNRELATED are also returned as empty vectors.

[MRESP, MUNRELATED, DELAY] = OSP(..., 'MinRespFrequency', MINRESPFREQUENCY) enforces a lower bound in hertz for the dominant respiratory frequency used to compute the model order. The default value is 0.1 Hz.

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/hrv/osp.m)

## Examples

```matlab
% Load fixture-based respiration and beat occurrence times
tkData = readtable('../../fixtures/ecg/ecg_tk.csv');
respData = readtable('../../fixtures/ecg/edr_signals.csv');
fs = 4;

% Compute the HRV modulating signal and align respiration to its grid
tn = tkData.tk(1:100);
[~, m] = ipfm(tn, fs);
tm = (tn(1):1/fs:tn(end))';
resp = interp1(respData.t, detrend(respData.resp), tm, 'pchip');

% Estimate the respiratory spectrum and decompose the modulating signal
windowLength = min(256, length(resp));
[respPxx, f] = pwelch(resp, hamming(windowLength), floor(windowLength / 2), [], fs);
[mResp, mUnrelated, delay] = osp(m, resp, respPxx, f, fs);
```

[View detailed example](https://github.com/BSICoS/biosigmat/tree/main/examples/hrv/ospExample.m)

## See Also

- IPFM
- PWELCH
- FINDPEAKS
- HANKEL

- [API Reference](../index.md)

---

**Module**: [HRV](index.md) | **Last Updated**: 2026-03-18
