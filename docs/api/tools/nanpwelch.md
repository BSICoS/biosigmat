# `nanpwelch` - Compute Welch periodogram when signal has NaN segments

## Syntax

```matlab
function varargout = nanpwelch(x, window, noverlap, nfft, fs, varargin)
```

## Description

Compute Welch periodogram when signal has NaN segments

## Source Code

[View source code](../../../src/tools/nanpwelch.m)

## Input Arguments

- **x**: Input signal (numeric vector or matrix)
- **window**: Window for segmentation (scalar window length or window vector)
- **noverlap**: Number of overlapped samples (scalar)
- **nfft**: Number of DFT points (scalar)
- **fs**: Sample rate in Hz (scalar)
- **maxgap**: Maximum gap length in samples to interpolate (scalar, optional)

## Output Arguments

- **pxx**: Power spectral density estimate
- **f**: Frequency axis in Hz (column vector, optional)
- **pxxSegments**: Power spectral density for each segment (optional)

## Examples

```matlab
% Basic usage example
result = nanpwelch(input);
```

## See Also

- [TOOLS Module](README.md)
- [API Reference](../README.md)

---

**Module**: TOOLS | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-24
