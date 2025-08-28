# API Reference

Complete reference documentation for all functions in the biosigmat toolbox.

## Modules

### [ECG Processing](ecg/index.md)

Functions for electrocardiography signal analysis and QRS detection.

| Function | Description | Examples | Status |
| -------- | ----------- | -------- | ------ |
| [`baselineremove`](ecg/baselineremove.md) | Removes baseline wander from biosignals using cubic spline interpolation. | [View code](https://github.com/BSICoS/biosigmat/tree/main/examples/ecg/baselineremoveExample.m) | :material-beta: Beta |
| [`pantompkins`](ecg/pantompkins.md) | Algorithm for R-wave detection in ECG signals. | [View code](https://github.com/BSICoS/biosigmat/tree/main/examples/ecg/pantompkinsExample.m) | :white_check_mark: Stable |
| [`sloperange`](ecg/sloperange.md) | Compute ECG-derived respiration (EDR) using slope range method. | [View code](https://github.com/BSICoS/biosigmat/tree/main/examples/ecg/sloperangeExample.m) | :material-beta: Beta |

### [HRV Analysis](hrv/index.md)

Functions for heart rate variability analysis and metrics calculation.

| Function | Description | Examples | Status |
| -------- | ----------- | -------- | ------ |
| [`tdmetrics`](hrv/tdmetrics.md) | Compute standard time-domain indices for heart rate variability analysis. | [View code](https://github.com/BSICoS/biosigmat/tree/main/examples/hrv/tdmetricsExample.m) | :white_check_mark: Stable |

### [PPG Processing](ppg/index.md)

Functions for photoplethysmography signal analysis and pulse detection.

| Function | Description | Examples | Status |
| -------- | ----------- | -------- | ------ |
| [`pulsedelineation`](ppg/pulsedelineation.md) | Performs pulse delineation in PPG signals using adaptive thresholding. | [View code](https://github.com/BSICoS/biosigmat/tree/main/examples/ppg/pulsedelineationExample.m) | :material-beta: Beta |
| [`pulsedetection`](ppg/pulsedetection.md) | Pulse detection in LPD-filtered PPG signals using configurable algorithms. | [View code](https://github.com/BSICoS/biosigmat/tree/main/examples/ppg/pulsedetectionExample.m) | :material-beta: Beta |

### [RESP](resp/index.md)

Functions for resp processing.

| Function | Description | Examples | Status |
| -------- | ----------- | -------- | ------ |
| [`tidalvolume`](resp/tidalvolume.md) | Extracts upper and lower peak envelopes from a signal. | [View code](https://github.com/BSICoS/biosigmat/tree/main/examples/resp/tidalvolumeExample.m) | :white_check_mark: Stable |

### [General Tools](tools/index.md)

Utility functions for signal processing and data manipulation.

| Function | Description | Status |
| -------- | ----------- | ------ |
| [`findsequences`](tools/findsequences.md) | Find sequences of repeated (adjacent/consecutive) numeric values. | :white_check_mark: Stable |
| [`interpgap`](tools/interpgap.md) | Interpolate small NaN gaps in a signal. | :white_check_mark: Stable |
| [`ispeaky`](tools/ispeaky.md) | Determines if spectra are considered peaky based on peakedness thresholds. | :white_check_mark: Stable |
| [`localmax`](tools/localmax.md) | Finds local maxima in matrix rows or columns. | :material-beta: Beta |
| [`lpdfilter`](tools/lpdfilter.md) | Low-pass derivative filter. | :white_check_mark: Stable |
| [`medfiltThreshold`](tools/medfiltThreshold.md) | Compute median-filtered adaptive threshold. | :white_check_mark: Stable |
| [`nanfilter`](tools/nanfilter.md) | Implements filter function with support for NaN values. | :white_check_mark: Stable |
| [`nanfiltfilt`](tools/nanfiltfilt.md) | Implements filtfilt function with support for NaN values. | :white_check_mark: Stable |
| [`nanpwelch`](tools/nanpwelch.md) | Compute Welch periodogram when signal has NaN segments. | :white_check_mark: Stable |
| [`peakedness`](tools/peakedness.md) | Computes the peakedness of power spectral density estimates. | :white_check_mark: Stable |
| [`slicesignal`](tools/slicesignal.md) | Divide signal into overlapping segments. | :white_check_mark: Stable |
| [`slider`](tools/slider.md) | Creates and adds a scroll slider to a figure with time-based plots. | :white_check_mark: Stable |
| [`snaptopeak`](tools/snaptopeak.md) | Refine QRS detections by snapping to local maxima. | :white_check_mark: Stable |
| [`trimnans`](tools/trimnans.md) | Trim NaN values from the beginning and end of a signal. | :white_check_mark: Stable |

## Function Index

### Alphabetical Index

All functions sorted alphabetically:

- [`baselineremove`](ecg/baselineremove.md)
- [`findsequences`](tools/findsequences.md)
- [`interpgap`](tools/interpgap.md)
- [`ispeaky`](tools/ispeaky.md)
- [`localmax`](tools/localmax.md)
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
- [`tidalvolume`](resp/tidalvolume.md)
- [`trimnans`](tools/trimnans.md)


## Development Status Legend

- :white_check_mark: **Stable**: Well-tested, production ready
- :material-alpha: **Beta**: Feature complete, undergoing testing
- :material-beta: **Alpha**: Under development, API may change
- :material-cancel: **Deprecated**: No longer recommended for use

---

*Last updated: 2025-08-28 | Total functions: 21*
