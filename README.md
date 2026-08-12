# Biosigmat

[![MATLAB](https://img.shields.io/badge/MATLAB-R2025a-blue)](https://www.mathworks.com/products/matlab.html)
[![License](https://img.shields.io/badge/License-GPL--3.0-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-0.2.0-orange)](src/+biosigmat/version.m)

MATLAB functions for biomedical signal processing, maintained by the [BSICoS Research Group](https://bsicos.i3a.es/).

## Installation

Download the archive and checksum from the [latest GitHub release](https://github.com/BSICoS/biosigmat/releases/latest), verify the archive, extract it, and add its `src` directory to the MATLAB path:

```matlab
addpath(genpath('path/to/biosigmat/src'));
biosigmat.version()
```

Biosigmat is tested with MATLAB R2025a, Signal Processing Toolbox, and Curve Fitting Toolbox. See the [installation guide](docs/getting-started/installation.md) for development setup.

## Documentation

The [Biosigmat documentation](https://bsicos.github.io/biosigmat/) contains the MATLAB API, with direct links to executable example code. For practical method descriptions, expected inputs and outputs, scientific references, and links to the Python implementation, use the [Biosiglib method catalog](https://bsicos.github.io/biosiglib/methods/).

## Support and license

Report problems through [GitHub Issues](https://github.com/BSICoS/biosigmat/issues). Biosigmat is distributed under the [GNU General Public License version 3](LICENSE).
