# biosigmat - Biomedical Signal Processing Toolbox for MATLAB

[![MATLAB](https://img.shields.io/badge/MATLAB-R2025a-blue)](https://www.mathworks.com/products/matlab.html)
[![License](https://img.shields.io/badge/License-GPL-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-Passing-brightgreen)](test/)

A MATLAB toolbox for processing and analyzing biomedical signals including ECG, PPG, and HRV analysis.

---

**Developed by**: [BSICoS Research Group](https://bsicos.i3a.es/)  
**Status**: Active Development

## Installation

1. Download or clone the repository:
```bash
git clone https://github.com/BSICoS/biosigmat.git
```

2. Add the toolbox to your MATLAB path:
```matlab
addpath(genpath('path/to/biosigmat'));
```

## Biosiglib conformance

Biosigmat is the MATLAB implementation of the language-independent [Biosiglib](https://github.com/BSICoS/biosiglib) specifications. The root `conformance.json` pins the exact Biosiglib revision used by shared conformance tests.

See [Conformance](docs/conformance.md) for validation commands and local checkout details.

## Documentation

> **Documentation site**  
> Visit: [https://bsicos.github.io/biosigmat/](https://bsicos.github.io/biosigmat/)

The documentation includes getting-started material, API reference pages, examples, contribution guidance, and code-style notes.

## Support

- Report issues on [GitHub Issues](https://github.com/BSICoS/biosigmat/issues)
- Contact the development team for additional support

## License

This project is licensed - see the [LICENSE](LICENSE) file for details.
