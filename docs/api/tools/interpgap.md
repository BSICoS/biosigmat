# `interpgap` - Interpolate small NaN gaps in a signal

## Syntax

```matlab
function interpolatedSignal = interpgap(signal, maxgap, varargin)
interpolated = interpgap(signal, 2);
interpolatedCubic = interpgap(signal, 2, 'cubic');
```

## Description

Interpolate small NaN gaps in a signal

## Source Code

[View source code](../../../src/tools/interpgap.m)

## Input Arguments

- **signal**: Input signal (numeric vector)
- **maxgap**: Maximum gap length in samples to interpolate (scalar)
- **method**: (optional) Interpolation method: 'linear', 'nearest', 'cubic',
- **spline, or pchip (default**: 'linear')

## Output Arguments

- **interpolatedSignal**: Signal with small gaps interpolated

## Examples

```matlab
Create a signal with small gaps
signal = [1, 2, NaN, 4, 5, NaN, NaN, 8, 9, 10]';
interpolated = interpgap(signal, 2);
interpolatedCubic = interpgap(signal, 2, 'cubic');
plot(1:length(signal), signal, 'ro', 1:length(interpolated), interpolated, 'b-');
legend('Original', 'Interpolated');
```

## See Also

- [TOOLS Module](README.md)
- [API Reference](../README.md)

---

**Module**: TOOLS | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-24
