# Biosigmat

[![MATLAB](https://img.shields.io/badge/MATLAB-R2025a-blue)](https://www.mathworks.com/products/matlab.html)
[![License](https://img.shields.io/badge/License-GPL--3.0-green.svg)](LICENSE)
[![Latest release](https://img.shields.io/github/v/release/BSICoS/biosigmat?label=Version)](https://github.com/BSICoS/biosigmat/releases/latest)

MATLAB functions for biomedical signal processing, maintained by the [BSICoS Research Group](https://bsicos.i3a.es/).

## Installation

Download the archive and checksum from the [latest GitHub release](https://github.com/BSICoS/biosigmat/releases/latest), verify the archive, extract it, and add its `src` directory to the MATLAB path:

```matlab
addpath(genpath('path/to/biosigmat/src'));
biosigmat.version()
```

Biosigmat is tested with MATLAB R2025a, Signal Processing Toolbox, and Curve Fitting Toolbox. See the public [installation guide](https://bsicos.github.io/biosigmat/installation/) for the complete instructions.

## Documentation

The [Biosigmat documentation](https://bsicos.github.io/biosigmat/) contains the MATLAB API, with direct links to executable example code. For practical method descriptions, expected inputs and outputs, scientific references, and links to the Python implementation, use the [Biosiglib method catalog](https://bsicos.github.io/biosiglib/methods/). See the [changelog](CHANGELOG.md) for the release history.

## Support and license

Report problems through [GitHub Issues](https://github.com/BSICoS/biosigmat/issues). Biosigmat is distributed under the [GNU General Public License version 3](LICENSE).
