# `ispeaky` - Determines if spectra are considered peaky based on peakedness thresholds.

## Syntax

```matlab
function isPeaky = ispeaky(pkl, akl, pklThreshold, aklThreshold)
```

## Description

ISPEAKY = ISPEAKY(PKL, AKL, PKLTHRESHOLD, AKLTHRESHOLD) determines if spectra are considered peaky based on peakedness thresholds. ISPEAKY is a logical array indicating which spectra meet both criteria (PKL >= PKLTHRESHOLD and AKL >= AKLTHRESHOLD).

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/tools/ispeaky.m)

## Examples

```matlab
% Using with peakedness function output
[pxx, f] = periodogram(signal, [], [], fs);
[pkl, akl] = peakedness(pxx, f, 0.3);
isPeaky = ispeaky(pkl, akl, 45, 85);

% Using with separate arrays
pkl = [30; 50; 70];
akl = [80; 90; 95];
isPeaky = ispeaky(pkl, akl, 45, 85);
% Result: [false; true; true] (only 2nd and 3rd spectra are peaky)
```

## See Also

- PEAKEDNESS
- PERIODOGRAM

- [API Reference](../index.md)

---

**Module**: [TOOLS](index.md) | **Last Updated**: 2025-08-08
