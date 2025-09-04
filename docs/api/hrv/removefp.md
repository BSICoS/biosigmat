# `removefp`

Remove false positive detections from HRV event series.

## Syntax

```matlab
function tk = removefp(tk)
```

## Description

TK = REMOVEFP(TK) removes false positive detections from the HRV event series TK by identifying and eliminating beats that are too close together. TK is a vector of event timestamps (beat or pulse occurrence times in seconds). Returns the corrected event series with false positives removed.

The function uses an adaptive baseline approach to identify intervals that are significantly shorter than expected, indicating likely false positive detections. When such intervals are found, the second beat in the pair is removed.

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/hrv/removefp.m)

## Examples

```matlab
% Create synthetic HRV event series with false positives
tk = [0, 0.8, 1.6, 1.65, 2.4, 3.2, 4.0, 4.05, 4.8]; % Some beats too close
tkCleaned = removefp(tk);

% Compare intervals before and after
dtkOriginal = diff(tk);
dtkCleaned = diff(tkCleaned);

% Plot comparison
figure;
subplot(2,1,1);
stem(dtkOriginal, 'r');
title('Original RR Intervals (with false positives)');
ylabel('RR Interval (s)');

subplot(2,1,2);
stem(dtkCleaned, 'g');
title('Cleaned RR Intervals');
ylabel('RR Interval (s)');
xlabel('Beat Index');
```

[View detailed example](https://github.com/BSICoS/biosigmat/tree/main/examples/hrv/removefpExample.m)

## See Also

- FILLGAPS
- MEDFILTTHRESHOLD

- [API Reference](../index.md)

---

**Module**: [HRV](index.md) | **Last Updated**: 2025-09-04
