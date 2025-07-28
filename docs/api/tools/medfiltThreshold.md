# `medfiltThreshold` - Compute median-filtered adaptive threshold.

## Syntax

```matlab
function threshold = medfiltThreshold(x, window, factor, maxthreshold)
```

## Description

THRESHOLD = MEDFILTTHRESHOLD(X, WINDOW, FACTOR, MAXTHRESHOLD) computes an adaptive threshold for identifying outliers in a series using median filtering. The threshold is based on a median-filtered version of the series, with padding at the boundaries to handle edge effects. THRESHOLD is the adaptive threshold values, same length as X, computed as FACTOR times the median-filtered signal, capped at MAXTHRESHOLD.

## Source Code

[View source code](../../../src/tools/medfiltThreshold.m)

## Examples

```matlab
% Create sample series with outliers
x = [0.8, 0.82, 0.81, 1.2, 0.79, 0.83, 0.80]';

% Compute adaptive threshold
threshold = medfiltThreshold(x, 5, 1.5, 1.5);

% Identify outliers
outliers = x > threshold;
```

## See Also

- MEDFILT1
- MOVMEDIAN

- [API Reference](../README.md)

---

**Module**: [TOOLS](README.md) | **Last Updated**: 2025-07-28
