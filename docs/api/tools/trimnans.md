# `trimnans` - Trim NaN values from the beginning and end of a signal

## Syntax

```matlab
function trimmedSignal = trimnans(signal)
trimmed = trimnans(signal);
```

## Description

Trim NaN values from the beginning and end of a signal

## Source Code

[View source code](../../../src/tools/trimnans.m)

## Input Arguments

- **signal**: Input signal (numeric vector)

## Output Arguments

- **trimmedSignal**: Signal with NaN values trimmed from beginning and end

## Examples

```matlab
Trim NaN values from a signal
signal = [NaN; NaN; 1; 2; NaN; 3; NaN; NaN];
trimmed = trimnans(signal);
Result: trimmed = [1; 2; NaN; 3]
```

## See Also

- [TOOLS Module](README.md)
- [API Reference](../README.md)

---

**Module**: TOOLS | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-25
