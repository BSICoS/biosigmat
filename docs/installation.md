# Installation Guide

This guide will help you install and set up the biosigmat toolbox in your MATLAB environment.

## Required Toolboxes
The following MATLAB toolboxes are required for full functionality:

- **Signal Processing Toolbox** - Required for filtering and spectral analysis

## Installation Methods

### Method 1: Direct Download (Recommended)

1. **Download the toolbox**:
   ```bash
   git clone https://github.com/BSICoS/biosigmat.git
   ```
   
   Or download the ZIP file from the GitHub repository.

2. **Add to MATLAB path**:
   ```matlab
   addpath(genpath('path\to\biosigmat'));
   ```

   !!! tip
      Add this line to your `startup.m` file to make the path addition persistent across MATLAB sessions.

### Method 2: MATLAB Add-On Installation

*Coming soon - we're working on packaging this as a MATLAB Add-On for easier installation.*

---

**Need help?** Contact us through [GitHub Issues](https://github.com/BSICoS/biosigmat/issues).
