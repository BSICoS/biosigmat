# `tdmetrics` - Compute classical time domain indices for heart rate variability analysis

## Syntax

```matlab
function Output = tdmetrics(dtk)
Output = tdmetrics(dtk) computes time domain indices from interval series (dtk).
```

## Description

Compute classical time domain indices for heart rate variability analysis

## Source Code

[View source code](../../../src/hrv/tdmetrics.m)

## Input Arguments

- **dtk**: Interval series (in seconds) as a numeric vector
- **TK**: tk - Required input parameter
- **removeOutliers**: Optional parameter

## Output Arguments

- **Output**: Structure containing the following time domain metrics:
- **mhr**: Mean heart rate (beats/min)
- **sdnn**: Standard deviation of normal-to-normal (NN) intervals (ms)
- **sdsd**: Standard deviation of differences between adjacent NN intervals (ms)
- **rmssd**: Root mean square of successive differences of NN intervals (ms)
- **pNN50**: Proportion of interval differences > 50ms with respect to all NN intervals ()

## Examples

```matlab
% Basic usage example
result = tdmetrics(input);
```

## See Also

- [HRV Module](README.md)
- [API Reference](../README.md)

---

**Module**: HRV | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-24
