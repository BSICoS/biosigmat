# `pantompkins` - Algorithm for R-wave detection in ECG signals.

## Syntax

```matlab
function varargout = pantompkins(ecg, fs, varargin)
```

## Description

TK = PANTOMPKINS(ECG, FS) Detects R-waves in ECG signals sampled at FS Hz using the Pan-Tompkins algorithm. This method applies bandpass filtering, derivative calculation, squaring, and integration to enhance R-wave peaks. TK is a column vector containing the R-wave occurrence times in seconds.

TK = PANTOMPKINS(..., Name, Value) allows specifying additional options using
name-value pairs.
- 'BandpassFreq'         -  Two-element vector [low, high] for bandpass filter
cutoff frequencies in Hz. Default: [5, 12]
- 'WindowSize'           -  Integration window size in seconds. Default: 0.15
- 'MinPeakDistance'      -  Minimum distance between peaks in seconds. Default: 0.5
- 'SnapTopeakWindowSize' -  Window size in samples for peak refinement. Default: 20

## Source Code

[View source code](../../../src/ecg/pantompkins.m)

## Examples

```matlab
% Basic usage example
result = pantompkins(input);
```

[View detailed example](../../../examples/ecg/pantompkinsExample.m)

## See Also

- [API Reference](../README.md)

---

**Module**: [ECG](README.md) | **Last Updated**: 2025-08-08
