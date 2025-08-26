# `pulsedetection`

Pulse detection in LPD-filtered PPG signals using configurable algorithms.

## Syntax

```matlab
function [nD, threshold] = pulsedetection(dppg, fs, varargin)
```

## Description

ND = PULSEDETECTION(DPPG, FS) detects pulse maximum upslopes ND in PPG derivative (DPPG) using the default adaptive threshold algorithm. DPPG is the LPD-filtered PPG signal (column vector) and FS is the sampling rate in Hz.

The function supports multiple detection algorithms and processes long signals in segments for computational efficiency. Each algorithm includes specialized mechanisms for missed or false detection correction.

ND = PULSEDETECTION(..., 'Name', Value) specifies additional parameters
using name-value pairs:
- 'Method'        - Detection algorithm: 'adaptive' (default)

Adaptive algorithm parameters:
- 'AdaptiveAlphaAmp'      - Multiplier for previous amplitude of detected maximum
when updating the threshold (default: 0.2)
- 'AdaptiveRefractPeriod' - Refractory period for threshold in seconds
(default: 0.15)
- 'AdaptiveTauRR'         - Fraction of estimated RR interval where threshold reaches
its minimum value (default: 1.0). Larger values create
steeper threshold slopes

[ND, THRESHOLD] = PULSEDETECTION(...) also returns the computed time-varying THRESHOLD for the selected algorithm.

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/ppg/pulsedetection.m)

## Examples

```matlab
% Load PPG signal and apply LPD filtering
load('ppg_sample.mat', 'ppg', 'fs');

% Design and apply LPD filter
fcLPD = 8; fpLPD = 0.9; orderLPD = 4;
[b, delay] = lpdfilter(fs, fcLPD, 'PassFreq', fpLPD, 'Order', orderLPD);
signalFiltered = filter(b, 1, ppg);
signalFiltered = [signalFiltered(delay+1:end); zeros(delay, 1)];

% Detect pulses with default adaptive algorithm
[nD, threshold] = pulsedetection(signalFiltered, fs);

% Visualize results
t = (0:length(signalFiltered)-1) / fs;
figure;
plot(t, signalFiltered, 'b');
hold on;
plot(t, threshold, 'r--', 'LineWidth', 1.5);
plot(nD, signalFiltered(round(nD*fs)+1), 'go', 'MarkerSize', 8);
xlabel('Time (s)');
ylabel('Amplitude');
title('PPG Pulse Detection');
legend('Filtered PPG', 'Threshold', 'Detected Pulses');

% Calculate heart rate
heartRate = 60 ./ diff(nD);
fprintf('Detected %d pulses\n', length(nD));
fprintf('Mean heart rate: %.1f bpm\n', mean(heartRate));
```

[View detailed example](https://github.com/BSICoS/biosigmat/tree/main/examples/ppg/pulsedetectionExample.m)

## See Also

- LPDFILTER
- PULSEDELINEATION
- FINDPEAKS

- [API Reference](../index.md)

---

**Module**: [PPG](index.md) | **Last Updated**: 2025-08-26
