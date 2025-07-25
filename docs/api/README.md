# biosigmat API Reference

Complete reference documentation for all functions in the biosigmat toolbox.

## Function Categories

### ECG Processing
Functions for electrocardiography signal analysis and QRS detection.

| Function | Description | Status |
| -------- | ----------- | ------ |
| [`baselineremove`](ecg/baselineremove.md) | Removes baseline wander from biosignals using cubic spline interpolation. | β Beta |
| [`pantompkins`](ecg/pantompkins.md) | Algorithm for R-wave detection in ECG signals. | β Beta |
| [`sloperange`](ecg/sloperange.md) | Compute ECG-derived respiration (EDR) using slope range method. | β Beta |

**[ECG Module Documentation](ecg/README.md)**

### HRV Analysis
Functions for heart rate variability analysis and metrics calculation.

| Function | Description | Status |
| -------- | ----------- | ------ |
| [`tdmetrics`](hrv/tdmetrics.md) | Compute classical time domain indices for heart rate variability analysis. | β Beta |

**[HRV Module Documentation](hrv/README.md)**

### PPG Processing
Functions for photoplethysmography signal analysis and pulse detection.

| Function | Description | Status |
| -------- | ----------- | ------ |
| [`pulsedelineation`](ppg/pulsedelineation.md) | Plethysmography signals delineation using adaptive thresholding. | β Beta |
| [`pulsedetection`](ppg/pulsedetection.md) | Pulse detection in plethysmography signals using adaptive thresholding. | β Beta |

**[PPG Module Documentation](ppg/README.md)**

### General Tools
Utility functions for signal processing and data manipulation.

| Function | Description | Status |
| -------- | ----------- | ------ |
| [`findsequences`](tools/findsequences.md) | Find sequences of repeated (adjacent/consecutive) numeric values | β Beta |
| [`interpgap`](tools/interpgap.md) | Interpolate small NaN gaps in a signal. | β Beta |
| [`ispeaky`](tools/ispeaky.md) | Determines if spectra are considered peaky based on peakedness thresholds. | β Beta |
| [`lpdfilter`](tools/lpdfilter.md) | Low-pass derivative filter. | β Beta |
| [`medfiltThreshold`](tools/medfiltThreshold.md) | Compute median-filtered adaptive threshold. | β Beta |
| [`nanfilter`](tools/nanfilter.md) | Implements filter function with support for NaN values. | β Beta |
| [`nanfiltfilt`](tools/nanfiltfilt.md) | Implements filtfilt function with support for NaN values. | β Beta |
| [`nanpwelch`](tools/nanpwelch.md) | Compute Welch periodogram when signal has NaN segments. | β Beta |
| [`peakedness`](tools/peakedness.md) | Computes the peakedness of power spectral density estimates. | β Beta |
| [`slicesignal`](tools/slicesignal.md) | Divide signal into overlapping segments. | β Beta |
| [`slider`](tools/slider.md) | Creates and adds a scroll slider to a figure with time-based plots | β Beta |
| [`snaptopeak`](tools/snaptopeak.md) | Refine QRS detections by snapping to local maxima. | β Beta |
| [`trimnans`](tools/trimnans.md) | Trim NaN values from the beginning and end of a signal. | β Beta |

**[TOOLS Module Documentation](tools/README.md)**

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

*Last updated: 2025-07-25 | Total functions: 19*
