# `pulsedetectionExample` - Example demonstrating pulse detection in PPG signals.

## Description

This example demonstrates how to detect individual pulses in photoplethysmographic (PPG) signals using the pulsedetection function. The process requires the PPG signal to be preprocessed with low-pass derivative (LPD) filtering before pulse detection can be applied. The example loads PPG signal data from fixture files, applies the necessary preprocessing steps, and uses the pulsedetection algorithm to identify pulse locations. Results are visualized showing the original PPG signal with detected pulse markers, demonstrating the algorithm's effectiveness in identifying individual cardiac cycles within the PPG waveform.

## Source Code

[View source code](../../examples/ppg/pulsedetectionExample.m)

## See Also

- [API Reference](../api/README.md)
- [PPG Module](../api/ppg/README.md)
- [Examples Overview](README.md)

---

**Module**: [PPG](../api/ppg/README.md) | **Last Updated**: 2025-07-28
