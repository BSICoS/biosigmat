# `sloperange`

Compute ECG-derived respiration (EDR) using slope range method.

## Syntax

```matlab
function varargout = sloperange(decg, rWaveTimes, fs)
```

## Description

EDR = SLOPERANGE(DECG, RWAVETIMES, FS) computes ECG-derived respiration (EDR) signal using the slope range method. This method analyzes the derivative of the ECG signal (DECG) around ECG R-wave occurrence times (RWAVETIMES) to extract respiratory information. EDR is a column vector with the same length as RWAVETIMES.

[EDR, UPSLOPES, DOWNSLOPES, UPMAXPOS, DOWNMINPOS] = SLOPERANGE(...) returns
additional outputs:
- UPSLOPES   - Matrix containing upslope values around R-waves
- DOWNSLOPES - Matrix containing downslope values around R-waves
- UPMAXPOS   - Positions of maximum upslope values
- DOWNMINPOS - Positions of minimum downslope values

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/ecg/sloperange.m)

## Examples

```matlab
% Derive respiratory signal from ECG using slope range method
load('ecg_data.mat'); % Load ECG signal and R-wave positions
decg = diff(ecg); % Calculate ECG derivative
edr = sloperange(decg, rWaveTimes, fs);

% Plot results
figure;
plot(rWaveTimes, edr);
title('ECG-derived Respiration');
xlabel('Time (s)');
ylabel('EDR Amplitude');
```

[View detailed example](https://github.com/BSICoS/biosigmat/tree/main/examples/ecg/sloperangeExample.m)

## See Also

- PANTOMPKINS
- BASELINEREMOVE

- [API Reference](../index.md)

---

**Module**: [ECG](index.md) | **Last Updated**: 2026-07-02
