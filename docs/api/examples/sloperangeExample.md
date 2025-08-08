# `sloperangeExample` - Example demonstrating ECG-derived respiration using slope range method.

## Description

This example demonstrates how to extract respiratory information from ECG signals using the slope range method. The process begins by loading ECG signals and pre-calculated R-peak timing data from CSV files. The ECG signal is then processed using low-pass derivative filtering to obtain the first derivative, which is essential for slope analysis. The sloperange function is applied to extract the ECG-derived respiration (EDR) signal by analyzing upslope and downslope patterns around R-wave peaks. Finally, the results are visualized in three subplots showing the original ECG with detected R-peaks, the ECG derivative with highlighted slope intervals, and the extracted EDR signal.

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/examples/ecg/sloperangeExample.m)

## See Also

- [API Reference](../api/README.md)
- [ECG Module](../api/ecg/README.md)
- [Examples Overview](README.md)

---

**Module**: [ECG](../api/ecg/README.md) | **Last Updated**: 2025-08-08
