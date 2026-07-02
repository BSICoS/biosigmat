# `tdmetrics`

Compute time-domain HRV metrics from interval series.

## Syntax

```matlab
function metrics = tdmetrics(dtk)
```

## Description

METRICS = TDMETRICS(DTK) computes standard time-domain heart-rate variability metrics from the interval series DTK, expressed in seconds.

DTK must be a non-empty numeric vector. Positive finite values are treated as valid intervals. NaN values are allowed as missing-interval markers and are omitted before computing the metrics. Inf, zero and negative values are rejected.

METRICS is a structure with fields: mhr   - Mean heart rate in beats per minute. sdnn  - Standard deviation of intervals in milliseconds. sdsd  - Standard deviation of successive interval differences in ms. rmssd - Root mean square of successive interval differences in ms. pNN50 - Percentage of successive interval differences greater than 50 ms.

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/hrv/tdmetrics.m)

## Examples

```matlab
dtk = [0.80 0.82 NaN 0.79 0.81];
metrics = tdmetrics(dtk);
```

[View detailed example](https://github.com/BSICoS/biosigmat/tree/main/examples/hrv/tdmetricsExample.m)

## See Also

- PANTOMPKINS

- [API Reference](../index.md)

---

**Module**: [HRV](index.md) | **Last Updated**: 2026-07-02
