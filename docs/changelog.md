# Changelog

## Unreleased

- Conformed sampled `hrv.ipfm` to the Biosiglib contract while retaining the
  MATLAB-only unevaluated spline convenience. The implementation now uses the
  canonical uniform sampling grid, enforces the input-dependent spline
  order bound, distinguishes the sampling-frequency requirements for `ihr` and
  `m`, and rejects insufficient or non-physiological numerical results.
- Consumed all six shared `hrv.ipfm` cases directly from Biosiglib, including
  the Biosigmat-backed nonuniform-event and TVIPFM fixture.
- Pinned conformance to Biosiglib v1.3.0 at commit
  `a1e7c3eae157c588705117ea9480b2cf3190d107`.

## 0.2.0 - 2026-08-04

- Conformed `hrv.removefp` to the shared contract with strict event ordering,
  fixed adaptive-baseline settings, and simultaneous one-pass removal.
- Conformed `hrv.fillgaps` while retaining its iterative algorithm and
  interactive, attempt-by-attempt debug view. The function now rejects invalid
  event ordering, leaves false-positive removal explicit, exposes the empirical
  thresholds as arguments, uses the four normative PCHIP support intervals, and
  preserves unresolved original timestamps while marking their intervals NaN.
- Extended the shared-output verifier for literal vectors and added complete
  automatic shared-case coverage for `hrv.removefp`.
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
