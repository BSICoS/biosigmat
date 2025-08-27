# `peakedness`

Computes the peakedness of power spectral density estimates.

## Syntax

```matlab
function [pkl, akl] = peakedness(pxx, f, varargin)
```

## Description

[PKL, AKL] = PEAKEDNESS(PXX, F) calculates the peakedness of power spectral density estimates PXX at frequencies F using an adaptive method that automatically determines the reference frequency as the spectrum maximum. PXX can be a column vector for a single spectrum or a matrix with spectra as columns. F is the frequency vector in Hz corresponding to PXX. Returns PKL (power concentration peakedness) and AKL (absolute maximum peakedness), both as percentages.

The peakedness measures how concentrated the power is in a narrow frequency band compared to a wider band. Power concentration peakedness (PKL) is the percentage of power in a narrow window compared to power in a wider window. Absolute maximum peakedness (AKL) is the percentage of the maximum power in the window compared to the global maximum power.

[PKL, AKL] = PEAKEDNESS(PXX, F, REFERENCEFREQ) uses a fixed reference frequency REFERENCEFREQ in Hz for peakedness calculation instead of the adaptive method.

[PKL, AKL] = PEAKEDNESS(PXX, F, REFERENCEFREQ, WINDOW) additionally specifies the search window bandwidth WINDOW in Hz centered around the reference frequency. Default window size is 0.125 Hz. Use empty array [] for REFERENCEFREQ to use adaptive method with custom window.

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/tools/peakedness.m)

## Examples

```matlab
% Generate a test spectrum with a peak at 0.3 Hz
f = 0:0.01:1;
pxx = exp(-((f-0.3)/0.05).^2) + 0.1*randn(size(f));

% Calculate peakedness using fixed reference frequency
[pkl, akl] = peakedness(pxx, f, 0.3);
```

## See Also

- NANPWELCH
- PWELCH

- [API Reference](../index.md)

---

**Module**: [TOOLS](index.md) | **Last Updated**: 2025-08-27
