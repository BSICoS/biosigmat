# `tdmetrics` - Compute standard time-domain indices for heart rate variability analysis.

## Syntax

```matlab
function metrics = tdmetrics(dtk)
```

## Description

METRICS = TDMETRICS(DTK) computes standard time-domain metrics used in heart rate
variability (HRV) analysis from interval series (DTK). METRICS is a structure
containing the following time-domain metrics:
- MHR   - Mean heart rate (beats/min)
- SDNN  - Standard deviation of normal-to-normal (NN) intervals (ms)
- SDSD  - Standard deviation of differences between adjacent NN intervals (ms)
- RMSSD - Root mean square of successive differences of NN intervals (ms)
- PNN50 - Proportion of interval differences > 50ms with respect to all NN intervals ()

## Source Code

[View source code](../../../src/hrv/tdmetrics.m)

## Examples

```matlab
% Compute time domain metrics from R-R interval series
load('ecg_data.mat'); % Load ECG data
rpeaks = pantompkins(ecg, fs); % Detect R-peaks
dtk = diff(rpeaks); % Compute R-R intervals
metrics = tdmetrics(dtk);

% Display results
fprintf('Mean HR: %.1f bpm\n', metrics.mhr);
fprintf('SDNN: %.1f ms\n', metrics.sdnn);
fprintf('RMSSD: %.1f ms\n', metrics.rmssd);
fprintf('SDSD: %.1f ms\n', metrics.sdsd);
fprintf('pNN50: %.1f %%\n', metrics.pNN50);
```

[View detailed example](../../../examples/hrv/tdmetricsExample.m)

## See Also

- PANTOMPKINS

- [API Reference](../README.md)

---

**Module**: [HRV](README.md) | **Last Updated**: 2025-08-08
