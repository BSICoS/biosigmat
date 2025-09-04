# `slicesignal`

Divide signal into overlapping segments.

## Syntax

```matlab
function [sliced, tcenter] = slicesignal(x, window, overlap, varargin)
```

## Description

SLICED = SLICESIGNAL(X, WINDOW, OVERLAP) divides input signal X into overlapping segments of specified length WINDOW samples. OVERLAP specifies the number of overlapping samples between consecutive segments. Each segment becomes a column in the output matrix SLICED, making it suitable for spectral analysis methods.

SLICED = SLICESIGNAL(..., FS) includes the sampling frequency FS in Hz, which is required when requesting time center output (TCENTER).

SLICED = SLICESIGNAL(..., 'Uselast', true) if true, the last segment will be included in the slicing, with nan padding to ensure it has the same length as the other segments. This option is set to false by default.

[SLICED, TCENTER] = SLICESIGNAL(...) returns TCENTER, the time values in seconds corresponding to the center of each slice. When requesting TCENTER output, FS parameter is required.

This function is particularly useful for time-frequency analysis where you need to apply spectral analysis methods like pwelch or periodogram to multiple overlapping segments of a signal.

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/tools/slicesignal.m)

## Examples

```matlab
% Create a chirp signal and slice it for time-frequency analysis
fs = 1000;
t = (0:1/fs:2)';
x = chirp(t, 10, 2, 50) + 0.1*randn(size(t));

% Slice the signal with 50% overlap (without time information)
sliced = slicesignal(x, 256, 128);

% Slice with time center information (fs required)
[sliced, tcenter] = slicesignal(x, 256, 128, fs);

% Compute power spectral density for each slice
[pxx, f] = pwelch(sliced, [], [], [], fs);

% Create time-frequency map
figure;
imagesc(tcenter, f, 10*log10(pxx));
axis xy;
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('Time-Frequency Spectrogram');
colorbar;
```

## See Also

- PWELCH
- SPECTROGRAM
- PERIODOGRAM

- [API Reference](../index.md)

---

**Module**: [TOOLS](index.md) | **Last Updated**: 2025-09-04
