# `nanfilter` - Implements filter function with support for NaN values

## Syntax

```matlab
function y = nanfilter(b, a, x, maxgap)
filtered = nanfilter(b, a, signal, 10);
```

## Description

Implements filter function with support for NaN values

## Source Code

[View source code](../../../src/tools/nanfilter.m)

## Input Arguments

- **b**: Numerator coefficients of the filter
- **a**: Denominator coefficients of the filter
- **x**: Input matrix with signals in columns that can include NaN values
- **maxgap**: Optional. Maximum gap size to interpolate. If not specified,

## Output Arguments

- **y**: Matrix of filtered signals in columns with NaN values preserved where appropriate

## Examples

```matlab
Filter a noisy signal with NaN gaps
fs = 1000;
t = 0:1/fs:1;
signal = sin(2*pi*50*t)' + 0.1*randn(length(t),1);
signal(100:150) = NaN;   Add NaN gap
[b, a] = butter(4, 0.1);
filtered = nanfilter(b, a, signal, 10);
```

## See Also

- [TOOLS Module](README.md)
- [API Reference](../README.md)

---

**Module**: TOOLS | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-24
