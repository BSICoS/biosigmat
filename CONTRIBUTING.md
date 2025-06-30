# Contributing to biosigmat

Thank you for your interest in contributing to biosigmat! This document provides guidelines and information to help you contribute effectively to the project.

## Pre-push Hook: Run Tests Before Pushing

To ensure that all code pushed to the repository passes the MATLAB tests, this project uses a pre-push hook. This hook automatically runs the tests before any push to the repository.

- If the tests pass, the push will complete successfully.
- If the tests fail, the push will be stopped.

This ensures that the repository always remains in a healthy state.

### How to Set Up the Pre-push Hook

1. Open your terminal and navigate to the root of the repository. Use Git Bash if using Windows (It won't work on PowerShell)

2. Run:

```bash
bash setup-hooks.sh
```

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

### Language

- All code comments must be written in English
- All variable, function, and file names must be in English
- Documentation must be written in English

### Naming Conventions

- Use camelCase for variable names (e.g., `filteredSignal`, `nanIndices`)
- Use camelCase for function names (e.g., `nanFiltFilt`, `findSequences`)
- Use PascalCase for struct names (e.g., `Setup`)
- Use descriptive names that clearly indicate the purpose of the variable or function

### Code Structure

- Every function must begin by checking the number of input and output arguments using `narginchk` and `nargoutchk`.
- After argument count checks, use `inputParser` to handle and validate all inputs.
- This structure must be used consistently in all functions. Example:

```matlab
function outputSignal = processSignal(inputSignal, windowSize)
% Processes the input signal using a sliding window approach
% 
% Inputs:
%   inputSignal - The signal to be processed
%   windowSize - Size of the sliding window
%
% Outputs:
%   outputSignal - The processed signal

% Check number of input and output arguments
narginchk(2, 2);
nargoutchk(0, 1);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'processSignal';
addRequired(parser, 'inputSignal', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'windowSize', @(x) isnumeric(x) && isscalar(x) && x > 0);
parse(parser, inputSignal, windowSize);
inputSignal = parser.Results.inputSignal;
windowSize = parser.Results.windowSize;

% ...function implementation...
end
```

- The header comment must describe the function's purpose, inputs, and outputs.
- The argument validation and parsing block must always appear immediately after the header comment, before any other code.
- Use the same commenting and structure style as shown above and in the files in `src/`.

### Test Structure

- Each test file must begin with a header comment summarizing the test scenarios covered. For example:

```matlab
% Tests covering:
%   - Basic functionality
%   - Edge-case handling
%   - Special values (NaN, Inf)
```

Test files must define a test class using MATLAB's unittest framework:

```matlab
% functionNameTest.m - Test class for the functionName function
classdef functionNameTest < matlab.unittest.TestCase

  methods (TestClassSetup)
    function addCodeToPath(tc)
      % Add source path for the function under test
      addpath('../../src/tools');
    end
  end

  methods (Test)
    function testBasicFunctionality(tc)
      % Setup input data
      inputData = ...;  % define inputs
      expected = ...;   % define expected output

      % Execute function under test
      actual = functionName(inputData);
      % Verify result
      tc.verifyEqual(actual, expected, 'Basic functionality failed');
    end

    function testEdgeCase(tc)
      % Setup edge-case input
      badInput = ...;
      % Verify error is thrown
      tc.verifyError(@() functionName(badInput), '', 'Error handling failed');
    end
  end

end
```

Key requirements for each test file:

- Filename must be `functionNameTest.m` located under `test/` with matching subfolder
- Include a `methods (TestClassSetup)` block for shared setup (e.g., addpath)
- Define one test method per scenario inside `methods (Test)`
- Use `tc.verify*` assertions (`verifyEqual`, `verifyTrue`, `verifyWarning`, etc.)
- Name test methods starting with `test` and use descriptive comments
- Handle special values (`NaN`, `Inf`) and multi-column inputs as needed
- Include dependency checks via `exist` in a first test method if external functions are required

## MATLAB-Specific Guidelines

- Use column vectors consistently
- Include appropriate error checking for function inputs
- Use meaningful variable names instead of single letters when possible (except for common math notation)
- Group related code blocks with comments

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
