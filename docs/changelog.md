# Changelog

## Unreleased

- Integrate the shared Biosiglib `hrv.tdmetrics` conformance case and manifest.
- Align `hrv.tdmetrics` with the Biosiglib minimum-data contract, returning
  `NaN` only for metrics that are undefined for the available valid intervals.
- Discover and execute every shared case for each conformant specification,
  with a suite-collection gate that detects unexecuted cases added by Biosiglib.
- Integrate the shared Biosiglib `ecg.pantompkins` conformance case using common fixture and output helpers.

## 0.1.0
Library in construction
