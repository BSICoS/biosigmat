# `snaptopeak` - Refine QRS detections by snapping to local maxima

## Syntax

```matlab
function refinedDetections = snaptopeak(ecg, detections, varargin)
snaptopeak(ECG, DETECTIONS) Refines QRS detection positions by moving
REFINEDDETECTIONS = snaptopeak(ECG, DETECTIONS)
snaptopeak(..., 'Name', Value) specifies optional parameters using
```

## Description

Refine QRS detections by snapping to local maxima

## Source Code

[View source code](../../../src/tools/snaptopeak.m)

## Input Arguments

- **ECG**: Single-lead ECG signal (numeric vector)
- **DETECTIONS**: Initial detection positions in samples (numeric vector)
- **REFINEDDETECTIONS**: Refined detection positions in samples (column vector)

## Output Arguments

- **refinedDetections**: refinedDetections output

## Examples

```matlab
% Basic usage example
result = snaptopeak(input);
```

## See Also

- [TOOLS Module](README.md)
- [API Reference](../README.md)

---

**Module**: TOOLS | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-24
