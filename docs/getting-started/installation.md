# Installation Guide

<div class="result" markdown>

:material-download:{ .lg .middle } **Get started with Biosigmat**

---

This guide will help you install and set up the biosigmat toolbox in your MATLAB environment.

</div>

!!! warning "Required MATLAB Toolboxes"
    Biosigmat 0.2.0 is tested with MATLAB R2025a and the following toolboxes:

    - :material-sine-wave:{ .middle } **Signal Processing Toolbox** - Required for filtering and spectral analysis
    - :material-chart-bell-curve:{ .middle } **Curve Fitting Toolbox** - Required for spline handling

## :material-download-multiple: Installation Methods

Download `biosigmat-0.2.0.zip` and `SHA256SUMS` from the
[v0.2.0 GitHub release](https://github.com/BSICoS/biosigmat/releases/tag/v0.2.0).
Verify the SHA-256 hash, extract the archive, and add only the `src` directory:

```matlab
addpath(genpath('path/to/biosigmat-0.2.0/src'));
assert(strcmp(biosigmat.version(), '0.2.0'));
```

<div class="grid cards" markdown>

-   :material-github:{ .lg .middle } **Method 1: Direct Download**

    ---

    Clone from GitHub for development:

    1. **Download the toolbox**:
       ```bash
       git clone https://github.com/BSICoS/biosigmat.git
       ```
       
    2. **Add to MATLAB path**:
       ```matlab
       addpath(genpath('path\to\biosigmat\src'));
       ```

    !!! tip "Persistent Path"
        Add this line to your `startup.m` file to make the path addition persistent across MATLAB sessions.

-   :material-puzzle:{ .lg .middle } **Method 2: MATLAB Add-On**

    ---

    **Coming Soon** - Official MATLAB Add-On installation

    !!! info "In Development"
        We're working on packaging this as a MATLAB Add-On for easier installation through the Add-On Explorer.

</div>

!!! question "Need Assistance?"
    If you encounter any issues during installation contact us through [GitHub Issues](https://github.com/BSICoS/biosigmat/issues)
