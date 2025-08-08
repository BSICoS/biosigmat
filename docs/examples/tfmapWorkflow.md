# `tfmapWorkflow` - Workflow demonstrating time-frequency analysis of synthetic signals.

## Description

This workflow demonstrates how to create comprehensive time-frequency maps of synthetic signals using advanced signal processing techniques. The process begins by generating a synthetic chirp signal with time-varying dominant frequency to simulate real-world signal characteristics. The signal is then systematically sliced into overlapping 20-second segments with 50 overlap to ensure adequate temporal resolution. Power spectral density is computed for each segment using the nanpwelch function, creating a matrix of frequency content over time. Finally, the results are visualized as a time-frequency plot that reveals how the signal's spectral characteristics evolve over time, providing valuable insights for understanding non-stationary signal behavior.

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/examples/workflows/tfmapWorkflow.m)

## See Also

- [API Reference](../index.md)
- [Examples Overview](index.md)

---

**Last Updated**: 2025-08-08
