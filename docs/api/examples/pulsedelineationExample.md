# `pulsedelineationExample` - Example demonstrating pulse delineation in PPG signals.

## Description

This example demonstrates how to perform detailed pulse delineation in photoplethysmographic (PPG) signals using the pulsedelineation function. The process requires the PPG signal to be preprocessed with low-pass derivative (LPD) filtering before delineation can be applied. The example loads PPG signal data from fixture files, applies the necessary preprocessing steps, and uses the pulsedelineation algorithm to identify key fiducial points within each pulse including onset, peak, and offset locations. Results are visualized showing the original PPG signal with detailed pulse delineation markers, demonstrating the algorithm's capability to extract morphological features from individual cardiac cycles.

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/examples/ppg/pulsedelineationExample.m)

## See Also

- [API Reference](../index.md)
- [PPG Module](../ppg/index.md)
- [Examples Overview](index.md)

---

**Module**: [PPG](../ppg/index.md) | **Last Updated**: 2025-08-08
