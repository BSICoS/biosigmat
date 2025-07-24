# `slicesignal` - Divide signal into overlapping segments

## Syntax

```matlab
function [sliced, tcenter] = slicesignal(x, window, overlap, fs)
```

## Description

Divide signal into overlapping segments

## Source Code

[View source code](../../../src/tools/slicesignal.m)

## Input Arguments

- **x**: Input signal (numeric column vector)
- **window**: Length of each slice in samples (scalar)
- **overlap**: Number of overlapping samples between slices (scalar)
- **fs**: Sample rate in Hz (scalar)

## Output Arguments

- **sliced**: Matrix where each column is a signal segment
- **tcenter**: Time axis in seconds corresponding to center of each slice (column vector)

## Examples

```matlab
Slice a signal and compute time-frequency map with pwelch
fs = 1000;
tSignal = (0:1/fs:2)';
x = chirp(tSignal, 10, 2, 50);
[sliced, tcenter] = slicesignal(x, 256, 128, fs);
[pxx, f] = pwelch(sliced, [], [], [], fs);
imagesc(tcenter, f, 10*log10(pxx));
axis xy;
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('Time-Frequency Map');
```

## See Also

- [TOOLS Module](README.md)
- [API Reference](../README.md)

---

**Module**: TOOLS | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-24
