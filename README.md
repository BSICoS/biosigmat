# biosigmat - Biomedical Signal Processing Toolbox for MATLAB

[![MATLAB](https://img.shields.io/badge/MATLAB-R2025a-blue)](https://www.mathworks.com/products/matlab.html)
[![License](https://img.shields.io/badge/License-GPL-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-Passing-brightgreen)](test/)
[![Version](https://img.shields.io/badge/Version-0.1.0-orange)](src/+biosigmat/version.m)

A MATLAB toolbox for processing and analyzing biomedical signals including ECG, PPG, and HRV analysis.

---

**Developed by**: [BSICoS Research Group](https://bsicos.i3a.es/)  
**Status**: Active Development

## Installation

Download `biosigmat-0.1.0.zip` and `SHA256SUMS` from the
[v0.1.0 GitHub release](https://github.com/BSICoS/biosigmat/releases/tag/v0.1.0),
verify the archive hash, and extract it. Add only its `src` directory to the
MATLAB path:

```matlab
addpath(genpath('path/to/biosigmat-0.1.0/src'));
biosigmat.version()
```

For development, clone the repository:

```bash
git clone https://github.com/BSICoS/biosigmat.git
```

Then add its source directory:

```matlab
addpath(genpath('path/to/biosigmat/src'));
```

Biosigmat 0.1.0 is tested with MATLAB R2025a, Signal Processing Toolbox, and
Curve Fitting Toolbox. Its implementation version is independent from
Biosiglib and can be queried with `biosigmat.version()` without shadowing
MATLAB's built-in `version` function.

## Biosiglib conformance

Biosigmat is the MATLAB implementation of the language-independent [Biosiglib](https://github.com/BSICoS/biosiglib) specifications. The root `conformance.json` pins the exact Biosiglib revision used by shared conformance tests.

See [Conformance](docs/conformance.md) for validation commands and local checkout details.

## Documentation

> **Documentation site**  
> Visit: [https://bsicos.github.io/biosigmat/](https://bsicos.github.io/biosigmat/)

The documentation includes getting-started material, API reference pages, examples, contribution guidance, and code-style notes.
API and example reference pages are generated from MATLAB headers and example source files during the documentation build.

## Support

- Report issues on [GitHub Issues](https://github.com/BSICoS/biosigmat/issues)
- Contact the development team for additional support

## License

This project is licensed - see the [LICENSE](LICENSE) file for details.
