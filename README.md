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
  ├── ppg/     # Photoplethysmography signal processing 🚧 (planned)
  ├── ecg/     # Electrocardiography signal processing
  ├── resp/    # Respiratory signal processing 🚧 (planned)
  └── tools/   # General purpose signal processing tools
test/
  ├── ppg/     # Tests for PPG processing 🚧 (planned)
  ├── ecg/     # Tests for ECG processing
  ├── resp/    # Tests for respiratory processing 🚧 (planned)
  └── tools/   # Tests for general tools
examples/
  ├── ppg/       # Simple examples of PPG processing 🚧 (planned)
  ├── ecg/       # Simple examples of ECG processing
  ├── resp/      # Simple examples of respiratory processing 🚧 (planned)
  ├── workflows/ # Complex examples combining multiple functions
  └── tutorials/ # Educational step-by-step examples 🚧 (planned)
```

Each signal-specific module contains relevant processing methods with corresponding tests and examples.

### Examples Organization

- **Signal-specific directories** (`ppg/`, `ecg/`, `resp/`): Simple examples demonstrating individual functions
- **`workflows/`**: Complex examples that combine multiple tools and functions to solve real-world biomedical signal processing problems
- **`tutorials/`**: Educational examples focusing on specific signal processing concepts and techniques 🚧 (planned)

## Contributing

For information on how to contribute to this project, please see the [CONTRIBUTING.md](CONTRIBUTING.md) file.

## License

This project is licensed - see the [LICENSE](LICENSE) file for details.
