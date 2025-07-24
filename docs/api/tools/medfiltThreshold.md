# `medfiltThreshold` - Compute median-filtered adaptive threshold

## Syntax

```matlab
function threshold = medfiltThreshold(x, window, factor, maxthreshold)
threshold = medfiltThreshold(x, 5, 1.5, 1.5);
```

## Description

Compute median-filtered adaptive threshold

## Source Code

[View source code](../../../src/tools/medfiltThreshold.m)

## Input Arguments

- **x**: Series (in seconds) as a numeric vector
- **window**: Window size for median filtering
- **factor**: Multiplicative factor for threshold computation
- **maxthreshold**: Maximum threshold value

## Output Arguments

- **threshold**: Adaptive threshold values

## Examples

```matlab
Create sample series
x = [0.8, 0.82, 0.81, 1.2, 0.79, 0.83, 0.80]';
Compute adaptive threshold
threshold = medfiltThreshold(x, 5, 1.5, 1.5);
Identify outliers
outliers = x > threshold;
```

## See Also

- [TOOLS Module](README.md)
- [API Reference](../README.md)

---

**Module**: TOOLS | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-24
