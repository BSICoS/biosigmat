# `lpdfilter` - Low-pass derivative filter.

## Syntax

```matlab
function [b, delay] = lpdfilter(fs, stopFreq, varargin)
filterCoeff = lpdfilter(fs, stopFreq) designs an LPD filter with
filterCoeff = lpdfilter(fs, stopFreq, Name, Value) allows specifying
```

## Description

Low-pass derivative filter.

## Source Code

[View source code](../../../src/tools/lpdfilter.m)

## Input Arguments

- **fs**: Sampling frequency in Hz (positive numeric scalar).
- **stopFreq**: Stop-band frequency in Hz (positive scalar).

## Output Arguments

- **b**: Filter impulsional response (1 x (Order+1) numeric array).
- **delay**: Delay introduced by the filter (scalar).

## Examples

```matlab
Design filter and visualize the frequency response
fs = 100;
[b, delay] = lpdfilter(fs, 10);
[h, w] = freqz(b, 1, 2^16);
figure;
plot(w*fs/(2*pi), abs(h)/max(abs(h)));
title('Normalized Frequency Response');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
grid on;
Apply filter to a signal and compensate delay
signalFiltered = filter(b, 1, signal);
signalFiltered = [signalFiltered(delay+1:end); zeros(delay, 1)];
```

## See Also

- [TOOLS Module](README.md)
- [API Reference](../README.md)

---

**Module**: TOOLS | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-24
