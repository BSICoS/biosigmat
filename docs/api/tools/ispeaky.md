# `ispeaky` - Determines if spectra are considered peaky based on peakedness thresholds.

## Syntax

```matlab
function isPeaky = ispeaky(pkl, akl, pklThreshold, aklThreshold)
isPeaky = ispeaky(pkl, akl, 45, 85);
```

## Description

Determines if spectra are considered peaky based on peakedness thresholds.

## Source Code

[View source code](../../../src/tools/ispeaky.m)

## Input Arguments

- **pkl**: Power concentration peakedness values ()
- **akl**: Absolute maximum peakedness values ()
- **pklThreshold**: Peakedness threshold based on power concentration ()
- **aklThreshold**: Peakedness threshold based on absolute maximum ()

## Output Arguments

- **isPeaky**: Logical array indicating which spectra are considered peaky

## Examples

```matlab
Using with peakedness function output
[pxx, f] = periodogram(signal, [], [], fs);
[pkl, akl] = peakedness(pxx, f, 0.3);
isPeaky = ispeaky(pkl, akl, 45, 85);
Using with separate arrays
pkl = [30; 50; 70];
akl = [80; 90; 95];
isPeaky = ispeaky(pkl, akl, 45, 85);
Result: [false; true; true] (only 2nd and 3rd spectra are peaky)
```

## See Also

- [TOOLS Module](README.md)
- [API Reference](../README.md)

---

**Module**: TOOLS | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-24
