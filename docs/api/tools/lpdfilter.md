# `lpdfilter` - Low-pass derivative filter.

## Syntax

```matlab
function [b, delay] = lpdfilter(fs, stopFreq, varargin)
```

## Description

B = LPDFILTER(FS, STOPFREQ) designs a low-pass derivative (LPD) linear-phase FIR filter with a specified sampling frequency FS and stop-band frequency STOPFREQ. using least-squares estimation.

B = LPDFILTER(..., Name, Value) allows specifying additional options
using name-value pairs.
- 'PassFreq' - Pass-band frequency in Hz (positive scalar).
Must be less than STOPFREQ. If not specified, defaults
to (STOPFREQ - 0.2) Hz.
- 'Order'    - Filter order (positive even integer). If not specified,
automatically calculated based on transition band requirements.

[B, DELAY] = LPDFILTER(...) also returns the filter delay, which is half the filter order.

## Source Code

[View source code](../../../src/tools/lpdfilter.m)

## Examples

```matlab
% Design filter and visualize the frequency response
fs = 100;
[b, delay] = lpdfilter(fs, 10);

[h, w] = freqz(b, 1, 2^16);
figure;
plot(w*fs/(2*pi), abs(h)/max(abs(h)));
title('Normalized Frequency Response');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
grid on;

% Apply filter to a signal and compensate delay
signalFiltered = filter(b, 1, signal);
signalFiltered = [signalFiltered(delay+1:end); zeros(delay, 1)];
```

## See Also

- FIRPMORD
- FIRLS
- FDESIGN.DIFFERENTIATOR

- [API Reference](../README.md)

---

**Module**: [TOOLS](README.md) | **Last Updated**: 2025-08-08
