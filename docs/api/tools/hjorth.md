# `hjorth`

Computes Hjorth parameters (activity, mobility, and complexity) from a signal.

## Syntax

```matlab
function [h0, h1, h2] = hjorth(x, fs)
```

## Description

[H0, H1, H2] = HJORTH(X, FS) computes the three Hjorth parameters from the input signal X sampled at frequency FS. X is the input signal (numeric vector) and FS is the sampling frequency in Hz (positive scalar). The function returns H0 (activity), H1 (mobility), and H2 (complexity) computed using spectral moments of order 0, 2, and 4. The first and second derivatives of the signal are computed automatically using numerical differentiation.

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/tools/hjorth.m)

## Examples

```matlab
% Compute Hjorth parameters for a synthetic signal
fs = 1000;  % Sampling frequency
t = 0:1/fs:2;  % Time vector
x = sin(2*pi*10*t) + 0.5*sin(2*pi*50*t) + randn(size(t))*0.1;

% Calculate Hjorth parameters
[h0, h1, h2] = hjorth(x, fs);

% Display results
fprintf('Activity (H0): %.4f\n', h0);
fprintf('Mobility (H1): %.4f Hz\n', h1);
fprintf('Complexity (H2): %.4f\n', h2);
```

## See Also

- VAR
- DIFF

- [API Reference](../index.md)

---

**Module**: [TOOLS](index.md) | **Last Updated**: 2025-09-01
