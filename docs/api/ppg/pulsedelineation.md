# `pulsedelineation`

Performs pulse delineation in PPG signals using adaptive thresholding.

## Syntax

```matlab
function [nA, nB, nM] = pulsedelineation(ppg, fs, nD, varargin)
```

## Description

[NA, NB, NM] = PULSEDELINEATION(PPG, FS, ND) performs pulse delineation in photoplethysmographic (PPG) signals, detecting pulse features (nA, nB, nM) based on pulse detection points (nD). FS is the sampling rate in Hz (positive scalar). NA returns pulse onset locations in seconds, NB returns pulse offset locations in seconds, and NM returns pulse midpoint locations in seconds.

[NA, NB, NM] = PULSEDELINEATION(..., 'Name', Value) specifies additional
parameters using name-value pairs:
- 'WindowA'  - Window width for searching pulse onset in seconds
(default: 250e-3)
- 'WindowB'  - Window width for searching pulse offset in seconds
(default: 150e-3)

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/ppg/pulsedelineation.m)

## Examples

```matlab
% Load PPG signal and apply LPD filtering
ppgData = readtable('ppg_signals.csv');
ppg = ppgData.sig(1:30000);
fs = 1000;

% Apply LPD filter
[b, delay] = lpdfilter(fs, 8, 'PassFreq', 7.8, 'Order', 100);
dppg = filter(b, 1, ppg);
dppg = [dppg(delay+1:end); zeros(delay, 1)];

% Compute pulse detection points
nD = pulsedetection(dppg, fs);

% Perform pulse delineation
[nA, nB, nM] = pulsedelineation(ppg, fs, nD);

% Plot results
t = (0:length(ppg)-1)/fs;
figure;
plot(t, ppg, 'k');
hold on;
plot(nA, ppg(1+round(nA*fs)), 'ro', 'MarkerFaceColor', 'r');
plot(nB, ppg(1+round(nB*fs)), 'go', 'MarkerFaceColor', 'g');
plot(nM, ppg(1+round(nM*fs)), 'bo', 'MarkerFaceColor', 'b');
legend('PPG Signal', 'Onset (nA)', 'Offset (nB)', 'Midpoint (nM)');
xlabel('Time (s)');
ylabel('Amplitude');
title('PPG Pulse Delineation');
```

[View detailed example](https://github.com/BSICoS/biosigmat/tree/main/examples/ppg/pulsedelineationExample.m)

## See Also

- PULSEDETECTION
- LPDFILTER

- [API Reference](../index.md)

---

**Module**: [PPG](index.md) | **Last Updated**: 2025-08-27
