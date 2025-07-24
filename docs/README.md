# biosigmat Documentation

Welcome to the comprehensive documentation for the biosigmat toolbox - a MATLAB toolbox for biomedical signal processing and analysis.

## Quick Navigation

### Getting Started
- [Installation Guide](installation.md)
- [Quick Start Guide](getting-started.md)
- [First Steps Tutorial](tutorials/first-steps.md)

### API Reference
- [Complete API Documentation](api/README.md)
- [ECG Processing](api/ecg/README.md) - Electrocardiography signal analysis
- [PPG Processing](api/ppg/README.md) - Photoplethysmography signal analysis
- [HRV Analysis](api/hrv/README.md) - Heart Rate Variability metrics
- [General Tools](api/tools/README.md) - Utility functions for signal processing

### Examples & Tutorials
- [Code Examples](examples/README.md) - Ready-to-use examples
- [Step-by-step Tutorials](tutorials/README.md) - In-depth learning guides
- [Workflow Examples](examples/workflows.md) - Complete analysis pipelines

### Contributing
- [Development Guide](contributing/development-guide.md)
- [Coding Standards](contributing/coding-standards.md)
- [Testing Guidelines](contributing/testing-guide.md)

## Toolbox Overview

biosigmat provides a comprehensive suite of functions for:

- **ECG Analysis**: QRS detection, baseline removal, and morphological analysis
- **PPG Processing**: Pulse detection, delineation, and quality assessment
- **HRV Metrics**: Time-domain, frequency-domain, and nonlinear measures
- **Signal Utilities**: Filtering, interpolation, and preprocessing tools

## Quick Example

```matlab
% Load and process an ECG signal
load('sample_ecg.mat');

% Remove baseline drift
cleanEcg = baselineremove(ecg, fs);

% Detect R-peaks using Pan-Tompkins algorithm
[peaks, locs] = pantompkins(cleanEcg, fs);

% Calculate HRV metrics
rrIntervals = diff(locs) / fs * 1000; % Convert to milliseconds
hrvMetrics = tdmetrics(rrIntervals);

% Display results
fprintf('RMSSD: %.2f ms\n', hrvMetrics.RMSSD);
fprintf('SDNN: %.2f ms\n', hrvMetrics.SDNN);
```

## Documentation Structure

This documentation is organized into several sections:

- **API Reference**: Detailed function documentation with syntax, parameters, and examples
- **Examples**: Practical code examples for common use cases
- **Tutorials**: Step-by-step guides for learning signal processing concepts
- **Contributing**: Guidelines for developers contributing to the toolbox

## Need Help?

- Check the [FAQ](faq.md) for common questions
- Browse the [examples](examples/README.md) for similar use cases
- Review the [API documentation](api/README.md) for function details
- See [contributing guidelines](contributing/README.md) to report issues or contribute

---

*This documentation is automatically generated and updated. Last updated: 2025-07-24*
