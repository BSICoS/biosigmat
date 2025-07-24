# `pantompkins` - algorithm for R-wave detection in ECG signals

## Syntax

```matlab
function varargout = pantompkins(ecg, fs, varargin)
pantompkins(ECG, FS) Detects R-waves in ECG signal using the Pan-Tompkins
TK = pantompkins(ECG, FS)
pantompkins(..., 'Name', Value) specifies optional parameters using
```

## Description

algorithm for R-wave detection in ECG signals

## Source Code

[View source code](../../../src/ecg/pantompkins.m)

## Input Arguments

- **ECG**: Single-lead ECG signal (numeric vector)
- **FS**: Sampling frequency in Hz (numeric scalar)
- **BandpassFreq**: Optional parameter
- **WindowSize**: Optional parameter (default: 0.15)
- **MinPeakDistance**: Optional parameter (default: 0.5)
- **UseSnapToPeak**: Optional parameter (default: true)
- **SnapTopeakWindowSize**: Optional parameter (default: 20)

## Output Arguments

- **varargout**: Variable number of output arguments

## Examples

```matlab
% Basic usage example
result = pantompkins(input);
```

## See Also

- [ECG Module](README.md)
- [API Reference](../README.md)

---

**Module**: ECG | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-24
