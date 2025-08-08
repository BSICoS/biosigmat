# API Reference

Complete reference documentation for all functions in the biosigmat toolbox.

## Modules

### [ECG Processing](ecg/index.md)
Functions for electrocardiography signal analysis and QRS detection.

| Function | Description | Examples | Status |
| -------- | ----------- | -------- | ------ |
| [`baselineremove`](ecg/baselineremove.md) | Removes baseline wander from biosignals using cubic spline interpolation. | [View code](https://github.com/BSICoS/biosigmat/tree/main/examples/ecg/baselineremoveExample.m) | β Beta |
| [`pantompkins`](ecg/pantompkins.md) | Algorithm for R-wave detection in ECG signals. | [View code](https://github.com/BSICoS/biosigmat/tree/main/examples/ecg/pantompkinsExample.m) | ✅ Stable |
| [`sloperange`](ecg/sloperange.md) | Compute ECG-derived respiration (EDR) using slope range method. | [View code](https://github.com/BSICoS/biosigmat/tree/main/examples/ecg/sloperangeExample.m) | β Beta |

### [HRV Analysis](hrv/index.md)
Functions for heart rate variability analysis and metrics calculation.

| Function | Description | Examples | Status |
| -------- | ----------- | -------- | ------ |
| [`tdmetrics`](hrv/tdmetrics.md) | Compute standard time-domain indices for heart rate variability analysis. | [View code](https://github.com/BSICoS/biosigmat/tree/main/examples/hrv/tdmetricsExample.m) | ✅ Stable |

### [PPG Processing](ppg/index.md)
Functions for photoplethysmography signal analysis and pulse detection.

| Function | Description | Examples | Status |
| -------- | ----------- | -------- | ------ |
| [`pulsedelineation`](ppg/pulsedelineation.md) | Plethysmography signals delineation using adaptive thresholding. | [View code](https://github.com/BSICoS/biosigmat/tree/main/examples/ppg/pulsedelineationExample.m) | α Alpha |
| [`pulsedetection`](ppg/pulsedetection.md) | Pulse detection in LPD-filtered PPG signals using adaptive thresholding. | [View code](https://github.com/BSICoS/biosigmat/tree/main/examples/ppg/pulsedetectionExample.m) | α Alpha |

### [General Tools](tools/index.md)
Utility functions for signal processing and data manipulation.

| Function | Description | Status |
| -------- | ----------- | ------ |
| [`findsequences`](tools/findsequences.md) | Find sequences of repeated (adjacent/consecutive) numeric values. | ✅ Stable |
| [`interpgap`](tools/interpgap.md) | Interpolate small NaN gaps in a signal. | ✅ Stable |
| [`ispeaky`](tools/ispeaky.md) | Determines if spectra are considered peaky based on peakedness thresholds. | ✅ Stable |
| [`lpdfilter`](tools/lpdfilter.md) | Low-pass derivative filter. | ✅ Stable |
| [`medfiltThreshold`](tools/medfiltThreshold.md) | Compute median-filtered adaptive threshold. | ✅ Stable |
| [`nanfilter`](tools/nanfilter.md) | Implements filter function with support for NaN values. | ✅ Stable |
| [`nanfiltfilt`](tools/nanfiltfilt.md) | Implements filtfilt function with support for NaN values. | ✅ Stable |
| [`nanpwelch`](tools/nanpwelch.md) | Compute Welch periodogram when signal has NaN segments. | ✅ Stable |
| [`peakedness`](tools/peakedness.md) | Computes the peakedness of power spectral density estimates. | ✅ Stable |
| [`slicesignal`](tools/slicesignal.md) | Divide signal into overlapping segments. | ✅ Stable |
| [`slider`](tools/slider.md) | Creates and adds a scroll slider to a figure with time-based plots. | ✅ Stable |
| [`snaptopeak`](tools/snaptopeak.md) | Refine QRS detections by snapping to local maxima. | ✅ Stable |
| [`trimnans`](tools/trimnans.md) | Trim NaN values from the beginning and end of a signal. | ✅ Stable |
## Function Index

### Alphabetical Index
All functions sorted alphabetically:

- [`baselineremove`](ecg/baselineremove.md)
- [`findsequences`](tools/findsequences.md)
- [`interpgap`](tools/interpgap.md)
- [`ispeaky`](tools/ispeaky.md)
- [`lpdfilter`](tools/lpdfilter.md)
- [`medfiltThreshold`](tools/medfiltThreshold.md)
- [`nanfilter`](tools/nanfilter.md)
- [`nanfiltfilt`](tools/nanfiltfilt.md)
- [`nanpwelch`](tools/nanpwelch.md)
- [`pantompkins`](ecg/pantompkins.md)
- [`peakedness`](tools/peakedness.md)
- [`pulsedelineation`](ppg/pulsedelineation.md)
- [`pulsedetection`](ppg/pulsedetection.md)
- [`slicesignal`](tools/slicesignal.md)
- [`slider`](tools/slider.md)
- [`sloperange`](ecg/sloperange.md)
- [`snaptopeak`](tools/snaptopeak.md)
- [`tdmetrics`](hrv/tdmetrics.md)
- [`trimnans`](tools/trimnans.md)


## Development Status Legend
- ✅ **Stable**: Well-tested, production ready
- β **Beta**: Feature complete, undergoing testing
- α **Alpha**: Under development, API may change
- ❌ **Deprecated**: No longer recommended for use
---

*Last updated: 2025-08-08 | Total functions: 19*
