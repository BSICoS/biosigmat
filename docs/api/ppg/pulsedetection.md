# `pulsedetection` - Pulse detection in LPD-filtered PPG signals using adaptive thresholding.

## Syntax

```matlab
function [nD, threshold] = pulsedetection(dppg, fs, varargin)
```

## Description

ND = PULSEDETECTION(DPPG, FS) detects pulse peaks ND in PPG signals using an adaptive threshold algorithm. DPPG is the LPD-filtered PPG signal (column vector) and FS is the sampling rate in Hz.

The algorithm uses adaptive thresholding with refractory periods and beat pattern analysis to handle irregular rhythms. It processes long signals in segments for computational efficiency and includes correction mechanisms for missed or false detections based on pulse-to-pulse interval regularity.

ND = PULSEDETECTION(..., 'Name', Value) specifies additional parameters
using name-value pairs:
- 'alfa'          - Multiplier for previous amplitude of detected maximum
when updating the threshold (default: 0.2)
- 'refractPeriod' - Refractory period for threshold in seconds
(default: 0.15)
- 'tauRR'         - Fraction of estimated RR interval where threshold reaches
its minimum value (default: 1.0). Larger values create
steeper threshold slopes
- 'thrIncidences' - Threshold for detecting irregular beat patterns
(default: 1.5)

[ND, THRESHOLD] = PULSEDETECTION(...) also returns the computed time-varying THRESHOLD.

## Source Code

[View source code](../../../src/ppg/pulsedetection.m)

## Examples

```matlab
% Load PPG signal and apply LPD filtering
load('ppg_sample.mat', 'ppg', 'fs');

% Design and apply LPD filter
fcLPD = 8; fpLPD = 0.9; orderLPD = 4;
[b, delay] = lpdfilter(fs, fcLPD, 'PassFreq', fpLPD, 'Order', orderLPD);
signalFiltered = filter(b, 1, ppg);
signalFiltered = [signalFiltered(delay+1:end); zeros(delay, 1)];

% Detect pulses with default parameters
[nD, threshold] = pulsedetection(signalFiltered, fs);

% Detect pulses with custom parameters
[nD2, threshold2] = pulsedetection(signalFiltered, fs, ...
   'alfa', 0.3, 'refractPeriod', 0.2, 'thrIncidences', 2.0);

% Visualize results
t = (0:length(signalFiltered)-1) / fs;
figure;
plot(t, signalFiltered, 'b');
hold on;
plot(t, threshold, 'r--', 'LineWidth', 1.5);
plot(nD, signalFiltered(round(nD*fs)+1), 'go', 'MarkerSize', 8);
xlabel('Time (s)');
ylabel('Amplitude');
title('PPG Pulse Detection with Adaptive Threshold');
legend('Filtered PPG', 'Threshold', 'Detected Pulses');

% Calculate heart rate
heartRate = 60 ./ diff(nD);
fprintf('Detected %d pulses\n', length(nD));
fprintf('Mean heart rate: %.1f bpm\n', mean(heartRate));
```

[View detailed example](../../../examples/ppg/pulsedetectionExample.m)

## See Also

- LPDFILTER
- PULSEDELINEATION
- FINDPEAKS

- [API Reference](../README.md)

---

**Module**: [PPG](README.md) | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-28
