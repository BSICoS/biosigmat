# `pulsedetection` - Pulse detection in plethysmography signals using adaptive thresholding.

## Syntax

```matlab
function [nD, threshold] = pulsedetection(signal, fs, varargin)
```

## Description

Pulse detection in plethysmography signals using adaptive thresholding.

## Source Code

[View source code](../../../src/ppg/pulsedetection.m)

## Input Arguments

- **signal**: LPD-filtered PPG signal (column vector)
- **fs**: Sampling rate (Hz)
- **alfa**: Optional parameter (default: 0.2)
- **refractPeriod**: Optional parameter (default: 150e-03)
- **tauRR**: Optional parameter (default: 1)
- **thrIncidences**: Optional parameter (default: 1.5)

## Output Arguments

- **nD**: Location of peaks detected in filtered signal (seconds)
- **threshold**: Computed time varying threshold

## Examples

```matlab
% Basic usage example
result = pulsedetection(input);
```

## See Also

- [PPG Module](README.md)
- [API Reference](../README.md)

---

**Module**: PPG | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-24
