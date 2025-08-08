# Installation Guide

<div class="result" markdown>

:material-download:{ .lg .middle } **Get started with Biosigmat**

---

This guide will help you install and set up the biosigmat toolbox in your MATLAB environment.

</div>

## :material-package-variant: Prerequisites

!!! warning "Required MATLAB Toolboxes"
    The following MATLAB toolboxes are required for full functionality:

    :material-sine-wave:{ .middle } **Signal Processing Toolbox** - Required for filtering and spectral analysis

## :material-download-multiple: Installation Methods

<div class="grid cards" markdown>

-   :material-github:{ .lg .middle } **Method 1: Direct Download**

    ---

    **Recommended** - Clone from GitHub repository

    1. **Download the toolbox**:
       ```bash
       git clone https://github.com/BSICoS/biosigmat.git
       ```
       
       Or download the ZIP file from the GitHub repository.

    2. **Add to MATLAB path**:
       ```matlab
       addpath(genpath('path\to\biosigmat'));
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