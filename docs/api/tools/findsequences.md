# `findsequences` - Find sequences of repeated (adjacent/consecutive) numeric values

## Syntax

```matlab
function varargout = findsequences(A)
findsequences(A) Find sequences of repeated numeric values in A along the
OUT = findsequences(...)
OUT = findsequences(A)
```

## Description

Find sequences of repeated (adjacent/consecutive) numeric values

## Source Code

[View source code](../../../src/tools/findsequences.m)

## Input Arguments

- **A**: A - Required input parameter

## Output Arguments

- **varargout**: Variable number of output arguments

## Examples

```matlab
There are sequences of 20s, 1s and NaNs (column-wise)
A   =  [  20,  19,   3,   2, NaN, NaN
20,  23,   1,   1,   1, NaN
20,   7,   7, NaN,   1, NaN]
OUT = findsequences(A)
OUT =
Value  startIndices  endIndices  seqLengths
20        1              3           3        Sequence of three 20s in first column
1       14             15           2        Sequence of two 1s (positions 14-15)
NaN       16             18           3        Sequence of three NaNs (positions 16-18)
```

## See Also

- [TOOLS Module](README.md)
- [API Reference](../README.md)

---

**Module**: TOOLS | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-24
