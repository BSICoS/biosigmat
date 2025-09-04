# `tidalvolume`

Extracts upper and lower peak envelopes from a signal.

## Syntax

```matlab
function [tdvol, upper, lower] = tidalvolume(resp, varargin)
```

## Description

TDVOL = TIDALVOLUME(RESP) extracts a signal proportional to an estimation of the tidal volume from a respiration signal RESP (numeric vector). The estimation is performed using the upper and lower envelopes connecting the peaks and valleys.

The algorithm does not detect every peak and valley to compute the envelopes. It only uses peaks and valleys between zero crossings. This way we assure that small fluctuations that may occur in real respiration signals are not detected as separate events. This means that the function expects detrended input signals. Although a simple detrend is performed internally, a preprocessing step to remove any slow drifts or trends is recommended.

ALGORITHM PHILOSOPHY:
- Peak-valley synchronization is guaranteed by the zero-crossing approach
- Peaks are defined as global maxima between consecutive zero crossings
- Valleys are defined as global minima between consecutive zero crossings
- This definition ignores intermediate local maxima/minima that don't cross zero
- This approach has physiological sense: it removes noise, artifacts, and
imperfections in breathing patterns while preserving the main respiratory cycles
- The method ensures robust envelope extraction for real respiratory signals

TDVOL = TIDALVOLUME(RESP, MINDIST) specifies the minimum distance between consecutive peaks in samples. MINDIST is a non-negative scalar with default value 0.

[TDVOL, UPPER, LOWER] = TIDALVOLUME(...) also returns the UPPER and LOWER envelopes connecting the peaks and valleys.

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/resp/tidalvolume.m)

## Examples

```matlab
% Basic usage example
result = tidalvolume(input);
```

[View detailed example](https://github.com/BSICoS/biosigmat/tree/main/examples/resp/tidalvolumeExample.m)

## See Also

- [API Reference](../index.md)

---

**Module**: [RESP](index.md) | **Last Updated**: 2025-09-04
