# Changelog

## Unreleased

- Conformed `hrv.removefp` to the shared contract with strict event ordering,
  fixed adaptive-baseline settings, and simultaneous one-pass removal.
- Reimplemented `hrv.fillgaps` against the shared contract while preserving
  the stable MATLAB two-output API, positional debug/maximum-gap arguments,
  and optional visualization. The numerical core now uses segment-wide
  iterative PCHIP reconstruction, exact duration preservation,
  over-insertion fallback, and NaN-marked unresolved gaps without implicit
  false-positive removal or warning-state leakage.
- Extended the shared-output verifier for literal vectors and embedded NaN
  markers, and added complete automatic shared-case coverage for both HRV
  preprocessing algorithms.
- Pinned conformance to Biosiglib v1.2.1 at commit
  `050a0527741415d4099ed6e2d8ba873fc76cf577`.

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
