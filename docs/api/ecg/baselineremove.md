# `baselineremove`

Removes baseline wander from biosignals using cubic spline interpolation.

## Syntax

```matlab
function [ecgDetrended, baseline] = baselineremove(ecg, tk, offset, varargin)
```

## Description

ECGDETRENDED = BASELINEREMOVE(ECG, TK, OFFSET) removes baseline wander from vector ECG signal by interpolating between fiducial points computed as (TK - OFFSET), where TK are typically R-peak indices and OFFSET is the number of samples before each TK to use as the fiducial point (e.g., PR interval in ECG). The interpolation is performed using cubic splines, and the resulting baseline estimate is subtracted. Returns the detrended ECG signal ECGDETRENDED, with same size as ECG.

ECGDETRENDED = BASELINEREMOVE(..., WINDOW) allows specifying the number of samples WINDOW to use for estimation at each fiducial point.

[ECGDETRENDED, BASELINE] = BASELINEREMOVE(...) returns the estimated BASELINE, which is a vector of the same size as ECG.

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/ecg/baselineremove.m)

## Examples

```matlab
% Remove baseline from ECG signal using R-peaks
[cleanEcg, baseline] = baselineremove(ecg, rpeaks, 50);
plot(1:length(ecg), ecg, 1:length(cleanEcg), cleanEcg);
legend('Original', 'Detrended');
```

[View detailed example](https://github.com/BSICoS/biosigmat/tree/main/examples/ecg/baselineremoveExample.m)

## See Also

- PAMTOMPKINS

- [API Reference](../index.md)

---

**Module**: [ECG](index.md) | **Last Updated**: 2025-09-04
