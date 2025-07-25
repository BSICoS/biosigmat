# `nanfiltfilt` - Implements filtfilt function with support for NaN values

## Syntax

```matlab
function y = nanfiltfilt(b, a, x, maxgap)
```

## Description

Implements filtfilt function with support for NaN values

## Source Code

[View source code](../../../src/tools/nanfiltfilt.m)

## Input Arguments

- **b**: Numerator coefficients of the filter
- **a**: Denominator coefficients of the filter
- **x**: Input matrix with signals in columns that can include NaN values
- **maxgap**: Optional. Maximum gap size to interpolate. If not specified,

## Output Arguments

- **y**: Matrix of filtered signals in columns with NaN values preserved where appropriate

## Examples

```matlab
% Basic usage example
result = nanfiltfilt(input);
```

## See Also

- [TOOLS Module](README.md)
- [API Reference](../README.md)

---

**Module**: TOOLS | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-25
