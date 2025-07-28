# `snaptopeak` - Refine QRS detections by snapping to local maxima.

## Syntax

```matlab
function refinedDetections = snaptopeak(ecg, detections, varargin)
```

## Description

REFINEDDETECTIONS = SNAPTOPEAK(ECG, DETECTIONS) refines QRS detection positions by moving each detection in DETECTIONS to the nearest local maximum within a search window around the original detection. ECG is the single-lead ECG signal and DETECTIONS contains the initial detection positions in samples. This improves the precision of R-wave peak localization by ensuring detections align with actual signal peaks. Returns REFINEDDETECTIONS as a column vector of refined positions with the same length as DETECTIONS.

REFINEDDETECTIONS = SNAPTOPEAK(..., 'WindowSize', WINDOWSIZE) specifies the search window size WINDOWSIZE in samples around each detection. Default window size is 20 samples.

The function searches for the maximum value within the specified window around each detection and moves the detection to that location. This is particularly useful after initial QRS detection to ensure precise alignment with R-wave peaks.

## Source Code

[View source code](../../../src/tools/snaptopeak.m)

## Examples

```matlab
% Load ECG data and perform initial detection
load('ecg_sample.mat', 'ecg', 'fs');

% Perform initial QRS detection (using pantompkins or similar)
initialDetections = pantompkins(ecg, fs);

% Refine detections by snapping to local maxima
refinedDetections = snaptopeak(ecg, initialDetections);

% Use larger search window
refinedDetections2 = snaptopeak(ecg, initialDetections, 'WindowSize', 30);
```

## See Also

- PANTOMPKINS
- FINDPEAKS
- MAX

- [API Reference](../README.md)

---

**Module**: [TOOLS](README.md) | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-28
