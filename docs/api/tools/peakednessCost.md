# `peakednessCost` - 

## Syntax

```matlab
function [ vars, Setup ] = peakednessCost(signals, ts, fs, Setup )
```

## Description

Inputs: signals - DR signals, one column for each signal ts      - time vector (sec) fs      - DR signals sampling rate (Hz) Setup   - struct containing the following fields: DT        : step of rate estimation (s) Ts        : interval length of Welch periodograms (s) Tm        : interval length of subintervals for Welch periodograms (s) Nfft      : number of points for FFT Omega_r   : frequency range to study (Hz) K         : successive running spectra of each DR signal to be averaged ksi_p     : peakedness threshold based on power concentration ksi_a     : peakedness threshold based on absolute maximum d         : half bandwidth of Omega centered around bar_fr (Hz) b         : forgetting factor for bar_fr a         : forgetting factor for hat_fr plotFlag  : true to enable the plots in this function Outputs: vars - struct containing the following fields: f              : frequency vector Skl            : Welch TF maps in a 3D matrix (f x t x DR signals) t_orig         : time vector for original Welch periodograms Sk             : peak conditioned average TF map (f x t) t_aver         : time vector for averaged Welch periodograms hat_fr         : estimated respiratory rate bar_fr         : smoothed estimate of hat_fr used           : one column for each DR signal, containing 1 in the indexes where the DR signal took part in the average times_used     : one column for each DR signal, containing the number of times its spectrum at time kk took part in the average Naveraged      : number of spectra which took part in the average in each time index (min=0; max=K*L) percentage_used: used in combination percentage of each signal Setup - updated Setup struct with default values if not provided

## Source Code

[View source code](../../../src/tools/peakednessCost.m)

## Examples

```matlab
% Basic usage example
result = peakednessCost(input);
```

## See Also

- [TOOLS Module](README.md)
- [API Reference](../README.md)

---

**Module**: TOOLS | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-25
