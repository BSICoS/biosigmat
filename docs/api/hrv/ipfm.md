# `ipfm`

Estimate instantaneous heart rate using the integral pulse frequency modulation model.

## Syntax

```matlab
function [outputSignal, m] = ipfm(tn, varargin)
```

## Description

SP = IPFM(TN) estimates the spline representation of instantaneous heart rate from the normal beat occurrence time series TN using the integral pulse frequency modulation model. TN is a vector of normal beat occurrence times in seconds. SP is a spline representation that can be evaluated with SPVAL.

IHR = IPFM(TN, FS) evaluates the IPFM spline at the uniformly sampled time vector TM = TN(1):1/FS:TN(end), where FS is the desired sampling frequency in hertz. IHR is the instantaneous heart rate in hertz.

SP = IPFM(TN, 'SplineOrder', SPLINEORDER) uses the specified spline order for the spline interpolation stage. The default spline order is 14.

IHR = IPFM(TN, FS, 'SplineOrder', SPLINEORDER) evaluates the IPFM spline using the specified spline order.

[IHR, M] = IPFM(TN, FS, ...) also returns M, the modulating signal obtained by removing the low-frequency trend of IHR and normalizing the residual by that trend.

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/hrv/ipfm.m)

## Examples

```matlab
% Estimate instantaneous heart rate from beat occurrence times
tkData = readtable('../../fixtures/ecg/ecg_tk.csv');
tn = tkData.tk(1:100);
fs = 4;

% Evaluate the IPFM spline and compute the modulating signal
[ihr, m] = ipfm(tn, fs);
tm = (tn(1):1/fs:tn(end))';

% Plot results
figure;
subplot(2,1,1);
plot(tm, ihr);
ylabel('Heart rate (Hz)');
title('IPFM-Based Instantaneous Heart Rate');

subplot(2,1,2);
plot(tm, m);
xlabel('Time (s)');
ylabel('Modulating signal');
title('IPFM Modulating Signal');
```

[View detailed example](https://github.com/BSICoS/biosigmat/tree/main/examples/hrv/ipfmExample.m)

## See Also

- SPAPI
- SPVAL
- FNDER

- [API Reference](../index.md)

---

**Module**: [HRV](index.md) | **Last Updated**: 2026-03-17
