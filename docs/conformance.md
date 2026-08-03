# Conformance

Biosigmat is the MATLAB implementation of the language-independent [Biosiglib](https://github.com/BSICoS/biosiglib) specifications.

The root `conformance.json` pins the exact Biosiglib revision used by shared conformance tests. Tests resolve Biosiglib from `BIOSIGLIB_ROOT` when it is set and otherwise use a sibling `../biosiglib` checkout.

The MATLAB suite discovers case files from the pinned Biosiglib checkout for every specification marked `conformant`. Each case definition determines whether the implementation is expected to return outputs or raise a MATLAB error. A coverage test compares all discovered case IDs with the parameterized suite, so a future Biosiglib release cannot silently add an unexecuted case to a conformant specification.

## Run the MATLAB test suite

Run the complete MATLAB suite from the Biosigmat repository root with the existing runner:

```powershell
matlab -batch "addpath('scripts/local'); runTests"
```

## Validate the conformance manifest

Validate the manifest with the pinned Biosiglib checkout and its repository-local virtual environment:

```powershell
$biosiglibRoot = if ($env:BIOSIGLIB_ROOT) { $env:BIOSIGLIB_ROOT } else { (Resolve-Path ..\biosiglib).Path }
& "$biosiglibRoot\.venv\Scripts\python.exe" "$biosiglibRoot\tools\validate_specs.py" --manifest "$PWD\conformance.json"
```

On Linux or macOS, use the equivalent Python executable from the Biosiglib `.venv`:

```bash
biosiglib_root="${BIOSIGLIB_ROOT:-../biosiglib}"
"$biosiglib_root/.venv/bin/python" "$biosiglib_root/tools/validate_specs.py" --manifest "$PWD/conformance.json"
```
