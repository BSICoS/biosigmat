# `sloperange` - Compute ECG-derived respiration (EDR) using slope range method.

## Syntax

```matlab
function varargout = sloperange(decg, tk, fs)
```

## Description

EDR = SLOPERANGE(DECG, TK, FS) computes ECG-derived respiration (EDR) signal using the slope range method. This method analyzes the derivative of the ECG signal (DECG) around R-wave peaks (TK) to extract respiratory information. EDR is a column vector with the same length as TK.

[EDR, UPSLOPES, DOWNSLOPES, UPMAXPOS, DOWNMINPOS] = SLOPERANGE(...) returns
additional outputs:
- UPSLOPES   - Matrix containing upslope values around R-waves
- DOWNSLOPES - Matrix containing downslope values around R-waves
- UPMAXPOS   - Positions of maximum upslope values
- DOWNMINPOS - Positions of minimum downslope values

## Source Code

[View source code](../../../src/ecg/sloperange.m)

## Examples

```matlab
% Derive respiratory signal from ECG using slope range method
load('ecg_data.mat'); % Load ECG signal and R-wave positions
decg = diff(ecg); % Calculate ECG derivative
edr = sloperange(decg, tk, fs);

% Plot results
figure;
plot(tk, edr);
title('ECG-derived Respiration');
xlabel('Time (s)');
ylabel('EDR Amplitude');
```

[View detailed example](../../../examples/ecg/sloperangeExample.m)

## See Also

- PANTOMPKINS
- BASELINEREMOVE

- [API Reference](../README.md)

---

**Module**: [ECG](README.md) | **Last Updated**: 2025-07-28
