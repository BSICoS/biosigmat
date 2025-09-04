# `fillgaps`

Fill gaps in HRV event series using iterative interpolation.

## Syntax

```matlab
function [tn, dtn] = fillgaps(tk, varargin)
```

## Description

TN = FILLGAPS(TK) fills gaps in the HRV event series TK using an iterative interpolation algorithm. TK is a vector of event timestamps (beat or pulse occurrence times in seconds). TN is the corrected event series with gaps filled. The algorithm starts by inserting a single beat per gap, moving to the next gap until the entire signal is processed. Once all gaps have been attempted, those that were not corrected are attempted with two insertions, and so on. This approach consolidates a reference with simple gaps to improve the accuracy of more complex ones.

The algorithm maintains original detections without displacement, trusting that detections are correct at these points. It is recommended that the processing chain discards all areas with artifacts or low SNR before detection.

TN = FILLGAPS(TK, DEBUG) enables visual inspection when DEBUG is true. When DEBUG is true, the function displays gap-by-gap plots for visual inspection of the correction process.

TN = FILLGAPS(TK, DEBUG, MAXGAPDURATION) sets the maximum gap duration in seconds that will be attempted for interpolation. Gaps longer than MAXGAPDURATION will be excluded from processing. Default value is 10 seconds.

[TN, DTN] = FILLGAPS(...) also returns DTN, the RR interval series (diff of TN). Gaps that were too large to interpolate (exceeding maxgapDuration) will have NaN values in the corresponding positions of DTN.

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/hrv/fillgaps.m)

## Examples

```matlab
% Create synthetic HRV event series with gaps
tk = 0:0.8:60; % Regular 75 bpm baseline
tk(20:22) = []; % Remove some beats to create a gap
tk(40:44) = []; % Create another larger gap
dtk = diff(tk);

% Fill gaps with custom maximum gap duration (5 seconds)
[tn, dtn] = fillgaps(tk, true, 5);

% Plot results
figure;
subplot(2,1,1);
stem(dtk, 'k'); hold on
stem([19, 39], dtk([19, 39]), 'r')
title('Original RR Intervals');
ylabel('RR Interval (s)');

subplot(2,1,2);
stem(dtn, 'k');
title('Filled RR Intervals (NaN for too-large gaps)');
ylabel('RR Interval (s)');
xlabel('Beat Index');
```

[View detailed example](https://github.com/BSICoS/biosigmat/tree/main/examples/hrv/fillgapsExample.m)

## See Also

- TDMETRICS
- MEDFILTTHRESHOLD
- REMOVEFP

- [API Reference](../index.md)

---

**Module**: [HRV](index.md) | **Last Updated**: 2025-09-04
