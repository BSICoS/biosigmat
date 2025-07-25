# `findsequences` - Find sequences of repeated (adjacent/consecutive) numeric values.

## Syntax

```matlab
function varargout = findsequences(A)
```

## Description

SEQUENCES = FINDSEQUENCES(A) finds sequences of repeated numeric values in A along the first dimension. A should be numeric. SEQUENCES is a "m by 4" numeric matrix where m is the number of sequences found. Each sequence has 4 columns where: 1st col. - The value being repeated 2nd col. - The position of the first value of the sequence (startIndices) 3rd col. - The position of the last value of the sequence (endIndices) 4th col. - The length of the sequence (seqLengths) [VALUES, INPOS, FIPOS, LEN] = FINDSEQUENCES(...) returns SEQUENCES as separate outputs. If no sequences are found no value is returned. To convert positions into subs/coordinates use IND2SUB.

## Source Code

[View source code](../../../src/tools/findsequences.m)

## Examples

```matlab
Find sequences of repeated values in a matrix
A = [20, 19,   3,   2, NaN, NaN;
20, 23,   1,   1,   1, NaN;
20,  7,   7, NaN,   1, NaN];
OUT = findsequences(A);
OUT contains:
Value  startIndices  endIndices  seqLengths
20        1              3           3        Three 20s in first column
1       14             15           2        Two 1s (positions 14-15)
NaN       16             18           3        Three NaNs (positions 16-18)
Get separate outputs
[values, startPos, endPos, lengths] = findsequences(A);
```

## See Also

- IND2SUB
- DIFF

- [TOOLS Module](README.md)
- [API Reference](../README.md)

---

**Module**: TOOLS | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-25
