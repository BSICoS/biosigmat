# `sloperange` - Compute ECG-derived respiration (EDR) using slope range method.

## Syntax

```matlab
function varargout = sloperange(decg, tk, fs)
edr = sloperange(decg, tk, fs);
```

## Description

Compute ECG-derived respiration (EDR) using slope range method.

## Source Code

[View source code](../../../src/ecg/sloperange.m)

## Input Arguments

- **DECG**: Single-lead ECG signal derivative (numeric vector)
- **TK**: Beat occurrence time series for R-waves in seconds (numeric vector)
- **FS**: Sampling frequency in Hz (numeric scalar)

## Output Arguments

- **varargout**: Variable number of output arguments

## Examples

```matlab
Derive respiratory signal from ECG using slope range method
edr = sloperange(decg, tk, fs);
plot(tk, edr); title('ECG-derived Respiration');
```

## See Also

- [ECG Module](README.md)
- [API Reference](../README.md)

---

**Module**: ECG | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-25
