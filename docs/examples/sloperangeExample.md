# SLOPERANGEEXAMPLE Example demonstrating ECG-derived respiration using slope range method

## Description

This example shows how to:

**Module**: ECG

## Steps

1. This example shows how to: - Load ECG signals and R-peak timing data - Preprocess ECG signal with bandpass filtering - Calculate ECG derivative for slope analysis - Apply the sloperange function to extract respiratory signal - Visualize the results with multiple subplots
2. The example uses fixture data from CSV files containing: - ECG signal sampled at 256 Hz - Pre-calculated R-peak timing in seconds

## Usage

Run the example from the MATLAB command window:

```matlab
run('examples/ecg/sloperangeExample.m');
```

## File Location

`examples/ecg/sloperangeExample.m`

## See Also

- [ECG Module](../api/ecg/README.md)
- [Examples Overview](README.md)

---

**Type**: Example | **Module**: ECG | **Last Updated**: 2025-07-25
