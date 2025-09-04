# `hjorthArtifacts`

Detects artifacts in physiological signals using Hjorth parameters.

## Syntax

```matlab
function [artifactVector, artifactMatrix] = hjorthArtifacts(signal, fs, seg, step, margins, varargin)
```

## Description

ARTIFACTVECTOR = HJORTHARTIFACTS(SIGNAL, FS, SEG, STEP, MARGINS) detects artifacts in the input signal using Hjorth parameters analysis. SIGNAL is the input signal vector, FS is the sampling frequency in Hz, SEG is the time window search in seconds, STEP is the step in seconds to shift the window, MARGINS is a 3x2 matrix where each row contains [low, up] margins for H0, H1, and H2 parameters respectively, relative to their median filtered baselines. ARTIFACTVECTOR is a logical vector indicating artifact samples.

[ARTIFACTVECTOR, ARTIFACTMATRIX] = HJORTHARTIFACTS(...) returns both the artifact vector and a matrix. ARTIFACTMATRIX contains the onset and offset times of artifact segments in seconds as an Nx2 matrix where each row represents [start_time, end_time] of an artifact segment.

[...] = HJORTHARTIFACTS(..., 'minSegmentSeparation', MINSEGMENTSEPARATION) sets the minimum time separation between consecutive artifact segments in seconds. This parameter prevents fragmentation of artifacts by merging nearby detections that are separated by less than the specified duration. Useful for consolidating artifacts that may appear as multiple short segments due to brief returns to normal parameter values (default: 1).

[...] = HJORTHARTIFACTS(..., 'medfiltOrder', MEDFILTORDER) sets the median filter order used for computing adaptive thresholds from the Hjorth parameters. A larger order provides smoother baseline estimation and is more robust to outliers, while a smaller order allows thresholds to adapt more quickly to signal changes. The order should be chosen based on the expected duration of normal signal variations (default: 300).

[...] = HJORTHARTIFACTS(..., 'negative', NEGATIVE) inverts the artifact detection logic when NEGATIVE is true, marking segments as artifacts when Hjorth parameters fall within the normal range instead of outside it. This is useful for detecting periods of unusually regular or low-activity signal behavior rather than traditional high-amplitude or noisy artifacts (default: false).

[...] = HJORTHARTIFACTS(..., 'plotflag', PLOTFLAG) enables plotting of intermediate results when PLOTFLAG is true (default: false).

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/ppg/hjorthArtifacts.m)

## Examples

```matlab
% Define parameters
seg = 4;
step = 3;
marginH0 = [5, 1];
marginH1 = [0.8, 2];
marginH2 = [6, 6];
margins = [marginH0; marginH1; marginH2];

% Get both artifact vector and matrix
[artifactVector, artifactMatrix] = hjorthArtifacts(signal, fs, seg, step, ...
   margins, 'minSegmentSeparation', 1, 'medfiltOrder', 15, 'plotflag', true);
```

[View detailed example](https://github.com/BSICoS/biosigmat/tree/main/examples/ppg/hjorthArtifactsExample.m)

## See Also

- HJORTH
- MEDFILT1

- [API Reference](../index.md)

---

**Module**: [PPG](index.md) | **Last Updated**: 2025-09-04
