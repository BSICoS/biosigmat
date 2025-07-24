# Installation Guide

This guide will help you install and set up the biosigmat toolbox in your MATLAB environment.

## System Requirements

### Required Toolboxes
The following MATLAB toolboxes are required for full functionality:

- **Signal Processing Toolbox** - Required for filtering and spectral analysis

## Installation Methods

### Method 1: Direct Download (Recommended)

1. **Download the toolbox**:
   ```bash
   git clone https://github.com/BSICoS/biosigmat.git
   ```
   
   Or download the ZIP file from the GitHub repository.

2. **Extract to desired location**:
   ```
   C:\MATLAB\toolboxes\biosigmat\    (Windows)
   ~/MATLAB/toolboxes/biosigmat/     (macOS/Linux)
   ```

3. **Add to MATLAB path**:
   ```matlab
   % Navigate to the toolbox directory
   cd('C:\MATLAB\toolboxes\biosigmat')  % Adjust path as needed
   
   % Add all subdirectories to path
   addpath(genpath(pwd));
   
   % Save path for future sessions
   savepath;
   ```

### Method 2: MATLAB Add-On Installation

*Coming soon - we're working on packaging this as a MATLAB Add-On for easier installation.*

## Path Configuration

### Automatic Path Setup (Recommended)
Create a startup script that automatically adds biosigmat to your path:

1. **Find your MATLAB startup folder**:
   ```matlab
   userpath  % Shows your MATLAB user path
   ```

2. **Create or edit startup.m**:
   ```matlab
   % Add this to your startup.m file
   biosigmatPath = 'C:\MATLAB\toolboxes\biosigmat';  % Adjust path
   if exist(biosigmatPath, 'dir')
       addpath(genpath(biosigmatPath));
       fprintf('biosigmat toolbox loaded successfully.\n');
   end
   ```

### Manual Path Setup
For temporary use or testing:

```matlab
% Add to current session only
addpath(genpath('path/to/biosigmat'));
```

### Getting Help

If you encounter issues:

1. **Check the documentation**: [Getting Started Guide](getting-started.md)
2. **Report issues**: [GitHub Issues](https://github.com/BSICoS/biosigmat/issues)

## Uninstallation

To remove the toolbox:

1. **Remove from MATLAB path**:
   ```matlab
   rmpath(genpath('path/to/biosigmat'));
   savepath;
   ```

2. **Delete files**:
   Simply delete the biosigmat directory from your file system.

## Next Steps

After successful installation:

1. **Read the [Getting Started Guide](getting-started.md)**
2. **Explore the [Examples](examples/README.md)**
3. **Check out the [API Documentation](api/README.md)**

---

**Need help?** Contact us through [GitHub Issues](https://github.com/BSICoS/biosigmat/issues).
