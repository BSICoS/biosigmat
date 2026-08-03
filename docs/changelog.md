# Changelog

## Unreleased

- No changes yet.

## 0.1.0 - 2026-08-03

- Published the first reproducible pre-1.0 Biosigmat source release with a
  SHA-256 checksum.
- Added the package-qualified `biosigmat.version()` query backed by one
  authoritative version source without shadowing MATLAB's built-in `version`.
- Documented the tested MATLAB R2025a, Signal Processing Toolbox, and Curve
  Fitting Toolbox configuration.
- Integrated the shared Biosiglib `hrv.tdmetrics` conformance case and manifest.
- Align `hrv.tdmetrics` with the Biosiglib minimum-data contract, returning
  `NaN` only for metrics that are undefined for the available valid intervals.
- Discover and execute every shared case for each conformant specification,
  with a suite-collection gate that detects unexecuted cases added by Biosiglib.
- Integrate the shared Biosiglib `ecg.pantompkins` conformance case using common fixture and output helpers.
- Implemented the complete five-output `ecg.sloperange` contract, adapting
  canonical zero-based positions only at the MATLAB conformance boundary.
- Reached conformance for all eight specifications in Biosiglib v1.0.0, pinned
  exactly to commit `ea2d5ded43e1348342f0db4fbd97d754b90a28c9`.
