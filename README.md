# biosigmat - Biomedical Signal Processing Toolbox for MATLAB

A comprehensive MATLAB toolbox for processing and analyzing biomedical signals including ECG, PPG, and HRV analysis.

[![MATLAB](https://img.shields.io/badge/MATLAB-R2025a%2B-blue)](https://www.mathworks.com/products/matlab.html)
[![License](https://img.shields.io/badge/License-GPL-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-Passing-brightgreen)](test/)

---

**Developed by**: [BSICoS Research Group](https://bsicos.i3a.es/)  
**Status**: Active Development

## Installation

1. Download or clone the repository:
```bash
git clone https://github.com/BSICoS/biosigmat.git
```

2. Add the toolbox to your MATLAB path:
```matlab
addpath(genpath('path/to/biosigmat'));
```

## Documentation

📚 **[Complete Documentation](docs/README.md)** - Comprehensive guides and API reference

## Project Structure

The code is organized by signal type:
```
src/
  ├── ppg/     # Photoplethysmography signal processing
  ├── ecg/     # Electrocardiography signal processing
  ├── hrv/     # Heart Rate Variability analysis
  ├── resp/    # Respiratory signal processing 🚧 (planned)
  └── tools/   # General purpose signal processing tools
test/
  ├── ppg/     # Tests for PPG processing
  ├── ecg/     # Tests for ECG processing
  ├── hrv/     # Tests for HRV analysis
  ├── resp/    # Tests for respiratory processing 🚧 (planned)
  └── tools/   # Tests for general tools
examples/
  ├── ppg/       # Simple examples of PPG processing
  ├── ecg/       # Simple examples of ECG processing
  ├── hrv/       # Simple examples of HRV analysis
  ├── resp/      # Simple examples of respiratory processing 🚧 (planned)
  ├── workflows/ # Complex examples combining multiple functions
  └── tutorials/ # Educational step-by-step examples 🚧 (planned)
```

Each signal-specific module contains relevant processing methods with corresponding tests and examples.

### Examples Organization

- **Signal-specific directories** (`ppg/`, `ecg/`, `hrv/`, `resp/`): Simple examples demonstrating individual functions
- **`workflows/`**: Complex examples that combine multiple tools and functions to solve real-world biomedical signal processing problems
- **`tutorials/`**: Educational examples focusing on specific signal processing concepts and techniques 🚧 (planned)

## Contributing

We welcome contributions! Please see our [Contributing Guide](docs/contributing/README.md) for details.

## Support

- 📖 Check the [documentation](docs/README.md) for detailed information
- 💡 Browse [examples](docs/examples/README.md) for common use cases
- 🐛 Report issues on [GitHub Issues](https://github.com/BSICoS/biosigmat/issues)
- 📧 Contact the development team for additional support

## License

This project is licensed - see the [LICENSE](LICENSE) file for details.