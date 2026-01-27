# `expandnans`

Expands NaN segments by a time window.

## Syntax

```matlab
function signalClean = expandnans(signal, fs, seconds)
```

## Description

SIGNALCLEAN = EXPANDNANS(SIGNAL, FS, SECONDS) replaces samples with NaN around existing NaN segments in SIGNAL. SIGNAL can be a vector or a matrix; when it is a matrix, each column is treated as an independent signal. FS is the sampling frequency in Hz (positive scalar). SECONDS is the time window (in seconds, nonnegative scalar) to expand on each side of every NaN segment.

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/tools/expandnans.m)

## Examples

```matlab
% Expand NaNs by 0.5 seconds on each side
fs = 100;
t = (0:1/fs:10)';
signal = sin(2*pi*1*t);
signal(201:230) = NaN;
signalClean = expandnans(signal, fs, 0.5);

figure;
plot(t, signal, 'b'); hold on;
plot(t, signalClean, 'r');
legend('Original', 'Expanded NaNs');
title('EXPANDNANS example');
```

## See Also

- ISNAN
- DIFF

- [API Reference](../index.md)

---

**Module**: [TOOLS](index.md) | **Last Updated**: 2026-01-27
