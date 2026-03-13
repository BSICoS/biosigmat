# `pulseenvelopes`

Estimates lower and upper PPG envelopes using pulse-anchored interpolation.

## Syntax

```matlab
function [lowerEnvelope, upperEnvelope] = pulseenvelopes(ppg, fs, nD, varargin)
```

## Description

LOWERENVELOPE = PULSEENVELOPES(PPG, FS, ND) estimates the lower envelope of a photoplethysmographic (PPG) signal by selecting one local minimum per pulse within a window before each pulse detection time ND and interpolating these anchor points. PPG is a numeric vector, FS is the sampling rate in Hz (positive scalar), and ND contains pulse detection times in seconds (typically returned by pulsedetection). LOWERENVELOPE is a column vector with the same length as PPG.

[LOWERENVELOPE, UPPERENVELOPE] = PULSEENVELOPES(PPG, FS, ND) also returns the upper envelope by selecting one local maximum per pulse within a window after each detection and interpolating these anchor points.

[...] = PULSEENVELOPES(..., 'Name', Value) specifies additional
parameters using name-value pairs:
- 'WindowA'  - Window width in seconds for searching the upper envelope
after each detection (default: 400e-3)
- 'WindowB'  - Window width in seconds for searching the lower envelope
before each detection (default: 300e-3)

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/ppg/pulseenvelopes.m)

## Examples

```matlab
% Pulse detection on the LPD-filtered signal
[b, delay] = lpdfilter(fs, 8, 'PassFreq', 7.8, 'Order', 100);
dppg = filter(b, 1, ppg);
dppg = [dppg(delay+1:end); zeros(delay, 1)];
nD = pulsedetection(dppg, fs);

% Estimate envelopes
[lowerEnv, upperEnv] = pulseenvelopes(ppg, fs, nD);

t = (0:length(ppg)-1)/fs;
figure;
plot(t, ppg, 'k'); hold on;
plot(t, lowerEnv, 'b', 'LineWidth', 1.5);
plot(t, upperEnv, 'r', 'LineWidth', 1.5);
legend('PPG', 'Lower envelope', 'Upper envelope');
xlabel('Time (s)'); ylabel('Amplitude');
```

[View detailed example](https://github.com/BSICoS/biosigmat/tree/main/examples/ppg/pulseenvelopesExample.m)

## See Also

- PULSEDETECTION
- PULSEDELINEATION
- INTERP1

- [API Reference](../index.md)

---

**Module**: [PPG](index.md) | **Last Updated**: 2026-03-13
