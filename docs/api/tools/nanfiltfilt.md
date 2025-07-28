# `nanfiltfilt` - Implements filtfilt function with support for NaN values.

## Syntax

```matlab
function y = nanfiltfilt(b, a, x, maxgap)
```

## Description

Y = NANFILTFILT(B, A, X) zero-phase filters the data in vector, matrix, or N-D array, X, with the filter described by vectors A and B to create the filtered data Y with NaN values preserved.

The filter is described by the difference equation:

a(1)*y(n) = b(1)*x(n) + b(2)*x(n-1) + ... + b(nb+1)*x(n-nb) - a(2)*y(n-1) - ... - a(na+1)*y(n-na).

The length of the input channels must be more than three times the filter order, defined as filtord(B,A).

Y = NANFILTFILT(B, A, X, MAXGAP) allows specifying a maximum gap size MAXGAP.

Algorithm: 1. For each column, identify NaN sequences and classify them as long (> MAXGAP) or short (<= MAXGAP). 2. If no long NaN sequences exist, process the entire column with interpolation. 3. If long NaN sequences exist, divide the column into valid segments. 4. Process each valid segment independently using filter after interpolating any short NaN gaps within the segment. 5. Restore the original long NaN gaps in the final result.

NANFILTFILT should not be used when the intent of a filter is to modify signal phase, as is the case with differentiators and Hilbert filters.

## Source Code

[View source code](../../../src/tools/nanfiltfilt.m)

## Examples

```matlab
% Filter a noisy signal with NaN gaps
fs = 1000;
t = 0:1/fs:1;
signal = sin(2*pi*50*t)' + 0.1*randn(length(t),1);
signal(100:150) = NaN;  % Add NaN gap
% Design and apply filter
[b, a] = butter(4, 0.1);
filtered = nanfiltfilt(b, a, signal, 10);
```

## See Also

- NANFILTER
- FILTFILT
- BUTTER

- [TOOLS Module](README.md)
- [API Reference](../README.md)

---

**Module**: TOOLS | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-28
