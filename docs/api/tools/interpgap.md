# `interpgap` - Interpolate small NaN gaps in a signal.

## Syntax

```matlab
function interpolated = interpgap(x, maxgap, varargin)
```

## Description

INTERPOLATED = INTERPGAP(X, MAXGAP) interpolates NaN gaps in a vector X that are smaller than or equal to a specified MAXGAP Gaps larger than MAXGAP are left unchanged. INTERPOLATED is a vector with the same size as X.

INTERPOLATED = INTERPGAP(..., METHOD) allows specifying the interpolation
method:
- 'linear'   - Linear interpolation (default)
- 'nearest'  - Nearest neighbor interpolation
- 'spline'   - Spline interpolation
- 'pchip'    - Piecewise cubic Hermite interpolating polynomial

## Source Code

[View source code](../../../src/tools/interpgap.m)

## Examples

```matlab
% Create a signal with small gaps and interpolate
x = [1, 2, NaN, 4, 5, NaN, NaN, 8, 9, 10]';
interpolated = interpgap(x, 2);
interpolatedCubic = interpgap(x, 2, 'spline');

% Plot results
figure;
plot(1:length(x), x, 'ro', 1:length(interpolated), interpolated, 'b-');
legend('Original', 'Interpolated');
title('Signal Gap Interpolation');
```

## See Also

- INTERP1
- ISNAN
- FILLMISSING

- [API Reference](../README.md)

---

**Module**: [TOOLS](README.md) | **Last Updated**: 2025-07-28
