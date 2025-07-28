# `slicesignal` - Divide signal into overlapping segments.

## Syntax

```matlab
function [sliced, tcenter] = slicesignal(x, window, overlap, fs)
```

## Description

[SLICED, TCENTER] = SLICESIGNAL(X, WINDOW, OVERLAP, FS) divides input signal X into overlapping segments of specified length WINDOW samples. OVERLAP specifies the number of overlapping samples between consecutive segments, and FS is the sampling frequency in Hz. Each segment becomes a column in the output matrix SLICED, making it suitable for spectral analysis methods. TCENTER contains the time values in seconds corresponding to the center of each slice.

This function is particularly useful for time-frequency analysis where you need to apply spectral analysis methods like pwelch or periodogram to multiple overlapping segments of a signal.

## Source Code

[View source code](../../../src/tools/slicesignal.m)

## Examples

```matlab
% Create a chirp signal and slice it for time-frequency analysis
fs = 1000;
t = (0:1/fs:2)';
x = chirp(t, 10, 2, 50) + 0.1*randn(size(t));
% Slice the signal with 50% overlap
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

- [TOOLS Module](README.md)
- [API Reference](../README.md)

---

**Module**: TOOLS | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-28
