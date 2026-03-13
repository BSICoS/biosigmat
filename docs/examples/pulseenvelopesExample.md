# `pulseenvelopesExample`

Example demonstrating envelope estimation in PPG signals.

## Description

This example demonstrates how to estimate lower and upper envelopes of a photoplethysmographic (PPG) signal using the pulseenvelopes function. The workflow loads a sample PPG signal from fixtures, detects pulse maximum upslopes using pulsedetection on an LPD-filtered signal, and then estimates both envelopes by interpolating pulse-anchored extrema.

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/examples/ppg/pulseenvelopesExample.m)

## See Also

- [API Reference](../index.md)
- [PPG Module](../api/ppg/index.md)
- [Examples Overview](index.md)

---

**Module**: [PPG](../api/ppg/index.md) | **Last Updated**: 2026-03-13
