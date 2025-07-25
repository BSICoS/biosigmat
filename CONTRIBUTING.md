# Contributing to biosigmat

Thank you for your interest in contributing to biosigmat! This document provides guidelines and information to help you contribute effectively to the project.

## Code Organization

The project is organized as follows:

- `src/`: Contains the source code of the library
  - `tools/`: Utility functions used throughout the library
  - Additional subdirectories for specific functionality
- `test/`: Contains test files for the source code
  - `tools/`: Tests for utility functions
  - Additional subdirectories matching the structure in `src/`
- `examples/`: Contains example usage of the library functions
  - Subdirectories matching the structure in `src/`

### Code and Test Requirements

- All methods in `src/` must have a corresponding test in `test/`
- All methods in `src/` must have a corresponding example in `examples/`
- Exception: Functions in `src/tools/` must have tests in `test/tools/` but are not required to have examples in `examples/tools/`

## Code Style Guidelines

For detailed code style guidelines including naming conventions, code structure, test structure, and MATLAB-specific guidelines, please refer to the [Code Style Guide](docs/code-style-guide.md).

## Contributing Process

1. **Fork the repository** and create a new branch for your feature or bug fix
2. **Implement your changes** following the coding guidelines
3. **Add tests** for your implementation
4. **Add examples** demonstrating the usage of your implementation (except for `tools/` functions)
5. **Ensure all tests pass**
6. **Submit a pull request** with a clear description of the changes and any relevant information

## Pull Request Guidelines

When submitting a pull request:

1. Provide a clear, descriptive title
2. Describe what your changes do and why they should be included
3. Include any relevant issue numbers in the PR description
4. Ensure your code follows the project's coding standards
5. Make sure all tests pass

## Getting Help

If you have questions or need assistance, please open an issue with a clear description of your question or problem.

Thank you for contributing to biosigmat!
