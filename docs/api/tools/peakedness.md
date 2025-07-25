# `peakedness` - Computes the peakedness of power spectral density estimates.

## Syntax

```matlab
function [pkl, akl] = peakedness(pxx, f, varargin)
fprintf('Power concentration peakedness: .1f\n', pkl);
fprintf('Absolute maximum peakedness: .1f\n', akl);
```

## Description

Computes the peakedness of power spectral density estimates.

## Source Code

[View source code](../../../src/tools/peakedness.m)

## Input Arguments

- **PXX**: pxx - Required input parameter
- **F**: f - Required input parameter
- **referenceFreq**: Optional parameter
- **window**: Optional parameter

## Output Arguments

- **pkl**: Power concentration peakedness values ( of power in narrow vs wide window) (1 per spectrum in pxx)
- **akl**: Absolute maximum peakedness values ( of max in window vs global max) (1 per spectrum in pxx)

## Examples

```matlab
Generate a test spectrum with a peak at 0.3 Hz
f = 0:0.01:1;
pxx = exp(-((f-0.3)/0.05).^2) + 0.1*randn(size(f));
[pkl, akl] = peakedness(pxx, f, 0.3);
fprintf('Power concentration peakedness: .1f\n', pkl);
fprintf('Absolute maximum peakedness: .1f\n', akl);
Use adaptive method (no reference frequency)
[pkl, akl] = peakedness(pxx, f);
Use custom window with fixed method
[pkl, akl] = peakedness(pxx, f, 0.3, 0.2);
Use custom window with adaptive method
[pkl, akl] = peakedness(pxx, f, [], 0.2);
```

## See Also

- [TOOLS Module](README.md)
- [API Reference](../README.md)

---

**Module**: TOOLS | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-25
