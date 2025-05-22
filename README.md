# biosigmat

A MATLAB library for biomedical signal processing. This library is currently under development and will include methods for processing and analyzing various biomedical signals.

## Overview

Biosigmat aims to provide comprehensive tools for processing biomedical signals such as:
- PPG (Photoplethysmography)
- ECG (Electrocardiography)
- Respiratory signals

## Repository Structure

The code is organized by signal type:
```
src/
  ├── ppg/     # Photoplethysmography signal processing
  ├── ecg/     # Electrocardiography signal processing
  ├── resp/    # Respiratory signal processing
  └── tools/   # General purpose signal processing tools
test/
  ├── ppg/     # Tests for PPG processing
  ├── ecg/     # Tests for ECG processing
  ├── resp/    # Tests for respiratory processing
  └── tools/   # Tests for general tools
examples/
  ├── ppg/     # Examples of PPG processing
  ├── ecg/     # Examples of ECG processing
  ├── resp/    # Examples of respiratory processing
```

Each signal-specific module contains relevant processing methods with corresponding tests and examples.

## Contributing

For information on how to contribute to this project, please see the [CONTRIBUTING.md](CONTRIBUTING.md) file.

## License

This project is licensed - see the [LICENSE](LICENSE) file for details.
