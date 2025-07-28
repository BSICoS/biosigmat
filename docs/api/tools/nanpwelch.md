# `nanpwelch` - Compute Welch periodogram when signal has NaN segments.

## Syntax

```matlab
function varargout = nanpwelch(x, window, noverlap, nfft, fs, varargin)
```

## Description

PXX = NANPWELCH(X, WINDOW, NOVERLAP, NFFT, FS) computes the Welch power spectral density estimate for signals containing NaN values. X is the input signal (vector or matrix), WINDOW is the window for segmentation (scalar length or window vector), NOVERLAP is the number of overlapped samples, NFFT is the number of DFT points, and FS is the sample rate in Hz. It trims NaN values at the beginning and end of the signal and splits the signal at large gaps. The power spectral density is computed for each valid segment and averaged across all segments. PXX is the power spectral density estimate.

PXX = NANPWELCH(..., MAXGAP) interpolates small gaps (≤ MAXGAP) before computing the PSD. If MAXGAP is empty or not provided, no interpolation is performed.

[PXX, F] = NANPWELCH(...) also returns the frequency vector F in Hz.

[PXX, F, PXXSEGMENTS] = NANPWELCH(...) returns additional output:
- PXXSEGMENTS - Power spectral density for each segment
For vector input: matrix where each column contains the PSD of one segment
For matrix input: cell array where PXXSEGMENTS{i} contains the PSD segments for signal i

## Source Code

[View source code](../../../src/tools/nanpwelch.m)

## Examples

```matlab
% Compute Welch PSD for a signal with NaN gaps
fs = 1000;
t = 0:1/fs:1;
signal = sin(2*pi*50*t)' + 0.1*randn(length(t),1);
signal(100:150) = NaN;  % Add NaN gap

% Compute PSD with gap interpolation
[pxx, f] = nanpwelch(signal, 256, 128, 512, fs, 10);
```

## See Also

- PWELCH
- PERIODOGRAM
- TRIMNANS
- INTERPGAP

- [API Reference](../README.md)

---

**Module**: [TOOLS](README.md) | **Last Updated**: 2025-07-28
