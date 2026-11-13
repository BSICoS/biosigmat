# Installation

## Requirements

- MATLAB R2025a
- Signal Processing Toolbox
- Curve Fitting Toolbox

## Install the latest release

Download the archive from the [latest GitHub release](https://github.com/BSICoS/biosigmat/releases/latest), extract it, and add its `src` directory to the MATLAB path:

```matlab
addpath(genpath('path/to/biosigmat/src'));
```

Add this command to `startup.m` if Biosigmat should be available in every MATLAB session.

Beta releases awaiting validation in everyday use are marked **Pre-release** on [GitHub Releases](https://github.com/BSICoS/biosigmat/releases). Install them using the same steps as a stable release.

## Verify the installation

```matlab
biosigmat.version()
```

## Get help

If installation fails, open an issue in the [Biosigmat repository](https://github.com/BSICoS/biosigmat/issues) and include your MATLAB version, operating system, and the complete error message.
