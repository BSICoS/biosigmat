# `baselineremove` - Removes baseline wander from biosignals using cubic spline interpolation.

## Syntax

```matlab
function [ecgDetrended, baseline] = baselineremove(ecg, tk, offset, varargin)
```

## Description

Removes baseline wander from biosignals using cubic spline interpolation.

## Source Code

[View source code](../../../src/ecg/baselineremove.m)

## Input Arguments

- **ecg**: Input signal to be filtered (column vector)
- **tk**: Vector containing indices of R-peaks (or other fiducial events)
- **offset**: Number of samples to subtract from each tk to obtain fiducial points
- **window**: (Optional) Number of samples to use for estimation at each fiducial point (default: 5)

## Output Arguments

- **ecgDetrended**: ecg with baseline wander removed
- **baseline**: The estimated baseline that was removed from the ecg

## Examples

```matlab
Remove baseline from ECG signal using R-peaks
[cleanEcg, baseline] = baselineremove(ecg, rpeaks, 50);
plot(1:length(ecg), ecg, 1:length(cleanEcg), cleanEcg);
legend('Original', 'Detrended');
```

## See Also

- [ECG Module](README.md)
- [API Reference](../README.md)

---

**Module**: ECG | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-25
