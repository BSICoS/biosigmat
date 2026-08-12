# Installation

## Requirements

- MATLAB R2025a
- Signal Processing Toolbox
- Curve Fitting Toolbox

## Install the latest release

Download the archive and `SHA256SUMS` from the [latest GitHub release](https://github.com/BSICoS/biosigmat/releases/latest). Verify the SHA-256 checksum, extract the archive, and add its `src` directory to the MATLAB path:

```matlab
addpath(genpath('path/to/biosigmat/src'));
```

Add this command to `startup.m` if Biosigmat should be available in every MATLAB session.

## Verify the installation

```matlab
biosigmat.version()
```

## Get help

If installation fails, open an issue in the [Biosigmat repository](https://github.com/BSICoS/biosigmat/issues) and include your MATLAB version, operating system, and the complete error message.
