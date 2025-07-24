# biosigmat API Reference

Complete reference documentation for all functions in the biosigmat toolbox.

## Function Categories

### ECG Processing
Functions for electrocardiography signal analysis and QRS detection.

| Function                                  | Description                            | Status   |
| ----------------------------------------- | -------------------------------------- | -------- |
| [`pantompkins`](ecg/pantompkins.md)       | Pan-Tompkins QRS detection algorithm   | ✅ Stable |
| [`baselineremove`](ecg/baselineremove.md) | Baseline drift removal using filtering | ✅ Stable |
| [`sloperange`](ecg/sloperange.md)         | Slope-based QRS detection method       | ✅ Stable |

**[ECG Module Documentation](ecg/README.md)**

### PPG Processing  
Functions for photoplethysmography signal analysis and pulse detection.

| Function                                      | Description                                | Status   |
| --------------------------------------------- | ------------------------------------------ | -------- |
| [`pulsedetection`](ppg/pulsedetection.md)     | Pulse detection in PPG signals             | ✅ Stable |
| [`pulsedelineation`](ppg/pulsedelineation.md) | Pulse wave delineation and fiducial points | ✅ Stable |

**[PPG Module Documentation](ppg/README.md)**

### HRV Analysis
Functions for heart rate variability analysis and metrics calculation.

| Function                        | Description                         | Status   |
| ------------------------------- | ----------------------------------- | -------- |
| [`tdmetrics`](hrv/tdmetrics.md) | Time-domain HRV metrics calculation | ✅ Stable |

**[HRV Module Documentation](hrv/README.md)**

### General Tools
Utility functions for signal processing and data manipulation.

| Function                                        | Description                              | Status   |
| ----------------------------------------------- | ---------------------------------------- | -------- |
| [`nanfiltfilt`](tools/nanfiltfilt.md)           | Zero-phase filtering with NaN handling   | ✅ Stable |
| [`nanfilter`](tools/nanfilter.md)               | Forward filtering with NaN handling      | ✅ Stable |
| [`findsequences`](tools/findsequences.md)       | Find sequences of consecutive values     | ✅ Stable |
| [`interpgap`](tools/interpgap.md)               | Interpolate gaps in signals              | ✅ Stable |
| [`ispeaky`](tools/ispeaky.md)                   | Peak detection utility                   | ✅ Stable |
| [`lpdfilter`](tools/lpdfilter.md)               | Low-pass derivative filter               | ✅ Stable |
| [`medfiltThreshold`](tools/medfiltThreshold.md) | Median filtering with threshold          | ✅ Stable |
| [`nanpwelch`](tools/nanpwelch.md)               | Power spectral density with NaN handling | ✅ Stable |
| [`peakedness`](tools/peakedness.md)             | Signal peakedness measure                | ✅ Stable |
| [`slicesignal`](tools/slicesignal.md)           | Extract signal segments                  | ✅ Stable |
| [`slider`](tools/slider.md)                     | Sliding window operations                | ✅ Stable |
| [`snaptopeak`](tools/snaptopeak.md)             | Snap indices to nearest peaks            | ✅ Stable |
| [`trimnans`](tools/trimnans.md)                 | Remove NaN values from signal edges      | ✅ Stable |

**[Tools Module Documentation](tools/README.md)**

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

## Usage Patterns

### Common Workflows
1. **ECG Analysis Pipeline**: `baselineremove` → `pantompkins` → `tdmetrics`
2. **PPG Analysis Pipeline**: `pulsedetection` → `pulsedelineation`
3. **Signal Preprocessing**: `trimnans` → `nanfiltfilt` → `interpgap`

### Function Dependencies
- Most ECG/PPG functions depend on tools from the `tools/` module
- HRV functions require peak detection results from ECG/PPG functions
- All filtering functions handle NaN values appropriately

## Development Status Legend
- ✅ **Stable**: Well-tested, production ready
- 🧪 **Beta**: Feature complete, undergoing testing
- 🚧 **Alpha**: Under development, API may change
- ❌ **Deprecated**: No longer recommended for use

---

*Last updated: 2025-07-24 | Total functions: 19*
