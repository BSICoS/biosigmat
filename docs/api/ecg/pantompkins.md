# `pantompkins`

Algorithm for R-wave detection in ECG signals.

## Syntax

```matlab
function varargout = pantompkins(ecg, fs, varargin)
```

## Description

RWAVETIMES = PANTOMPKINS(ECG, FS) Detects R-waves in ECG signals sampled at FS Hz using the Pan-Tompkins algorithm. This method applies bandpass filtering, derivative calculation, squaring, and integration to enhance R-wave peaks. RWAVETIMES is a column vector containing the ECG R-wave occurrence times in seconds.

RWAVETIMES = PANTOMPKINS(..., Name, Value) allows specifying additional options using
name-value pairs.
- 'BandpassFreq'         -  Two-element vector [low, high] for bandpass filter
cutoff frequencies in Hz. Default: [5, 12]
- 'WindowSize'           -  Integration window size in seconds. Default: 0.15
- 'MinPeakDistance'      -  Minimum distance between peaks in seconds. Default: 0.5
- 'SnapTopeakWindowSize' -  Window size in samples for peak refinement. Default: 20

[RWAVETIMES, ECGFILTERED, DECG, DECGENVELOPE] = PANTOMPKINS(...) returns additional outputs:
- ECGFILTERED  - Bandpass filtered ECG signal
- DECG         - Squared derivative of the filtered ECG signal
- DECGENVELOPE - Integrated envelope signal used for peak detection

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/ecg/pantompkins.m)

## Examples

```matlab
% Load ECG data and sampling frequency
rWaveTimes = pantompkins(ecg, fs);
plot(t, ecg); hold on;
plot(rWaveTimes, ecg(round(rWaveTimes*fs)), 'ro');
title('Detected R-waves in ECG Signal');
```

[View detailed example](https://github.com/BSICoS/biosigmat/tree/main/examples/ecg/pantompkinsExample.m)

## See Also

- BASELINEREMOVE
- LPDFILTER
- FINDPEAKS

- [API Reference](../index.md)

---

**Module**: [ECG](index.md) | **Last Updated**: 2026-06-30
