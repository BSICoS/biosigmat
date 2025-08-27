# `localmax`

Finds local maxima in matrix rows or columns.

## Syntax

```matlab
function [maxValue, maxLoc] = localmax(X, varargin)
```

## Description

MAXVALUE = LOCALMAX(X) finds the location and value of the most prominent local maximum along the first non-singleton dimension of matrix X. Returns MAXVALUE containing the max values. For rows/columns without maxima, returns NaN.

MAXVALUE = LOCALMAX(X, DIM) finds the location and value of the most prominent local maximum along dimension DIM of matrix X. DIM specifies the dimension along which to search for maxima (1 for columns, 2 for rows).

MAXVALUE = LOCALMAX(..., 'Name', Value) specifies additional
parameters using name-value pairs:
- 'MinProminence' - Minimum prominence required for max detection
(default: 0)
- 'MinSeparation' - Minimum separation between max in samples
(default: 1)

[MAXVALUE, MAXLOC] = LOCALMAX(...) also returns MAXLOC containing the max locations.

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/tools/localmax.m)

## Examples

```matlab
% Create test signals with peaks
t = 0:0.01:2;
signal1 = sin(2*pi*t) + 0.5*sin(6*pi*t);
signal2 = cos(3*pi*t) + 0.3*randn(size(t));
X = [signal1; signal2];

% Find local maxima using automatic dimension detection
[maxValue, maxLoc] = localmax(X);

% Find local maxima along rows (dim=2) explicitly
[maxValue2, maxLoc2] = localmax(X, 2);

% Plot results
figure;
subplot(2,1,1);
plot(t, signal1, 'b-', t(maxLoc2(1)), maxValue2(1), 'ro', 'MarkerFaceColor', 'r');
title('Signal 1 with Local Maximum');
subplot(2,1,2);
plot(t, signal2, 'g-', t(maxLoc2(2)), maxValue2(2), 'ro', 'MarkerFaceColor', 'r');
title('Signal 2 with Local Maximum');
```

## See Also

- ISLOCALMAX
- MAX
- FINDPEAKS

- [API Reference](../index.md)

---

**Module**: [TOOLS](index.md) | **Last Updated**: 2025-08-27
