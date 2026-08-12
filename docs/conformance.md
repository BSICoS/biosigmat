# Conformance

Biosigmat is the MATLAB implementation of the language-independent [Biosiglib](https://github.com/BSICoS/biosiglib) specifications.

The one-line root `biosiglib.lock` pins the exact Biosiglib revision used by shared conformance tests. Merged code must conform to every specification in that revision; partial support and roadmaps belong in issues and pull requests. Tests resolve Biosiglib from `BIOSIGLIB_ROOT` when it is set and otherwise use a sibling `../biosiglib` checkout.

The MATLAB suite discovers every specification and case file from the pinned Biosiglib checkout. Each case definition determines whether the implementation is expected to return outputs or raise a MATLAB error. The suite fails when a specification has no shared cases, and a coverage test compares all discovered case IDs with the parameterized suite so a future Biosiglib commit cannot silently add an unexecuted case.

## Run the MATLAB test suite

Run the complete MATLAB suite from the Biosigmat repository root with the existing runner:

```powershell
matlab -batch "addpath('scripts/local'); runTests"
```

This single command validates the lock, verifies the Biosiglib checkout commit, and executes every shared case.
