# `trimnans` - Trim NaN values from the beginning and end of a signal.

## Syntax

```matlab
function trimmedSignal = trimnans(signal)
```

## Description

TRIMMEDSIGNAL = TRIMNANS(SIGNAL) removes NaN values from the beginning and end of the input signal SIGNAL, returning the trimmed signal TRIMMEDSIGNAL. The function preserves any NaN values that occur in the middle of the signal between valid data points. If all values in the signal are NaN, an empty array is returned.

This function is useful for cleaning up signals that may have NaN padding at the edges due to filtering operations, data acquisition issues, or preprocessing steps. It ensures that the signal starts and ends with valid numeric values while maintaining the original structure of any internal NaN values.

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/tools/trimnans.m)

## Examples

```matlab
% Create a signal with NaN padding at both ends
signal = [NaN; NaN; 1; 2; NaN; 3; 4; NaN; NaN];
trimmed = trimnans(signal);
% Result: trimmed = [1; 2; NaN; 3; 4]
```

## See Also

- ISNAN
- FIND
- RMMISSING

- [API Reference](../index.md)

---

**Module**: [TOOLS](index.md) | **Last Updated**: 2025-08-08
