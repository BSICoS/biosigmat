# `pantompkinsExample` - Example demonstrating R-wave detection using Pan-Tompkins algorithm.

## Description

This example demonstrates the implementation of the Pan-Tompkins algorithm for reliable R-wave detection in ECG signals. The process begins by loading ECG data sampled at 256 Hz from fixture files. The Pan-Tompkins algorithm is then applied to detect R-wave peaks through a series of filtering and processing steps including bandpass filtering, differentiation, squaring, and integration. The example provides comprehensive visualization of all intermediate processing steps, showing the filtered signal, squared derivative, integrated envelope, and final R-wave detection results, allowing users to understand each stage of the algorithm's operation.

## Source Code

[View source code](../../examples/ecg/pantompkinsExample.m)

## See Also

- [API Reference](../api/README.md)
- [ECG Module](../api/ecg/README.md)
- [Examples Overview](README.md)

---

**Module**: [ECG](../api/ecg/README.md) | **Last Updated**: 2025-07-28
