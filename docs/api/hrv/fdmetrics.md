# `fdmetrics`

Compute standard frequency-domain indices for heart rate variability analysis.

## Syntax

```matlab
function metrics = fdmetrics(pxx, varargin)
```

## Description

METRICS = FDMETRICS(PXX, F) computes standard frequency-domain metrics used in heart rate variability (HRV) analysis from the power spectral density PXX of the HRV signal evaluated on the frequency vector F in hertz. METRICS contains the following fields: hf   - High-frequency power lf   - Low-frequency power lfn  - Normalized low-frequency power lfhf - Low-frequency to high-frequency power ratio

METRICS = FDMETRICS(PXX, F, LIMITHF) controls the upper boundary of the high-frequency band. When LIMITHF is true, the conventional 0.15 Hz to 0.4 Hz band is used. When LIMITHF is false, the high-frequency band extends from 0.15 Hz to the highest frequency available in F. The default value is true.

METRICS = FDMETRICS(PXXRELATED, PXXUNRELATED, F) assumes that orthogonal subspace projection (OSP) has been performed, where PXXRELATED contains the HRV component linearly related to respiration and PXXUNRELATED contains the HRV component not linearly related to respiration, and computes the following fields from the separated spectra: urlf - Unrelated low-frequency power re   - Total respiration-related power r    - Unrelated-to-total power ratio

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/hrv/fdmetrics.m)

## Examples

```matlab
% Compute frequency-domain HRV metrics from a synthetic spectrum
f = linspace(0, 0.5, 512)';
pxx = 0.01 * exp(-((f - 0.1) / 0.03).^2) + 0.02 * exp(-((f - 0.25) / 0.04).^2);
metrics = fdmetrics(pxx, f, false);

% Plot the spectrum and show the computed bands
figure;
plot(f, pxx);
xlabel('Frequency (Hz)');
ylabel('Power spectral density');
title(sprintf('LF/HF = %.2f', metrics.lfhf));
```

[View detailed example](https://github.com/BSICoS/biosigmat/tree/main/examples/hrv/fdmetricsExample.m)

## See Also

- NANPWELCH
- PWELCH
- OSP

- [API Reference](../index.md)

---

**Module**: [HRV](index.md) | **Last Updated**: 2026-07-02
