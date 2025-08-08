# `pulsedelineation` - Plethysmography signals delineation using adaptive thresholding.

## Syntax

```matlab
function [ nD , nA , nB , nM , threshold ] = pulsedelineation ( signal , fs , Setup )
```

## Description

[ nD , nA , nB , nM , threshold ] = pulsedelineation ( signal , fs , Setup )

This function performs pulse delineation in PPG signals, detecting pulse features (nA, nB, nM) based on pulse detection points (nD). If nD points are not provided, they are computed using the pulsedetection function.

In: signal        = Filtered LPD-filtered PPG signal fs            = sampling rate (Hz) Setup         = Structure with optional parameters: .nD         = Pre-computed pulse detection points [Default: []] .alfa       = Multiplies previous amplitude of detected maximum in filtered signal for updating the threshold [Default: 0.2] .refractPeriod = Refractory period for threshold (s) [Default: 150e-3] .tauRR      = Fraction of estimated RR where threshold reaches its minimum value (alfa*amplitude of previous SSF peak) [Default: 1]. If tauRR increases, steeper slope .thrIncidences = Threshold for incidences [Default: 1.5] .wdw_nA     = Window width for searching pulse onset [Default: 250e-3] .wdw_nB     = Window width for searching pulse offset [Default: 150e-3] .fsi        = Sampling frequency for interpolation [Default: 2*fs] .computePeakDelineation = Enable peak delineation [Default: true]

Out: nD            = Location of peaks detected in filtered signal (seconds) nA            = Location of pulse onsets (seconds) nB            = Location of pulse offsets (seconds) nM            = Location of pulse midpoints (seconds) threshold     = Computed time varying threshold

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/ppg/pulsedelineation.m)

## Examples

```matlab
% LPD-filter PPG signal
[b, delay] = lpdfilter(fs, fcLPD, 'PassFreq', fpLPD, 'Order', orderLPD);
signalFiltered = filter(b, 1, signal);
signalFiltered = [signalFiltered(delay+1:end); zeros(delay, 1)];

% Set up pulse delineation parameters
Setup = struct();
Setup.alfa = 0.2;                   % Threshold adaptation factor
Setup.refractPeriod = 150e-3;       % Refractory period (s)
Setup.thrIncidences = 1.5;          % Threshold for incidences
Setup.wdw_nA = 250e-3;              % Window for onset detection (s)
Setup.wdw_nB = 150e-3;              % Window for offset detection (s)

% Run pulse delineation on filtered signal
[nD, nA, nB, nM, threshold] = pulsedelineation(signalFiltered, fs, Setup);

Status: Alpha
```

[View detailed example](https://github.com/BSICoS/biosigmat/tree/main/examples/ppg/pulsedelineationExample.m)

## See Also

- [API Reference](../README.md)

---

**Module**: [PPG](README.md) | **Last Updated**: 2025-08-08
