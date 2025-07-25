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

### Language

- All code comments must be written in English
- All variable, function, and file names must be in English
- Documentation must be written in English

### Naming Conventions

- Use camelCase for variable names (e.g., `filteredSignal`, `nanIndices`)
- Use camelCase for function names (e.g., `nanFiltFilt`, `findSequences`)
- Use descriptive names that clearly indicate the purpose of the variable or function

### Code Structure

- Every function must begin by checking the number of input and output arguments using `narginchk` and `nargoutchk`.
- After argument count checks, use `inputParser` to handle and validate all inputs.
- This structure must be used consistently in all functions. Example:

```matlab
function outputSignal = processSignal(inputSignal, windowSize)
% PROCESSSIGNAL Processes the input signal using a sliding window approach.
%
%   OUTPUTSIGNAL = PROCESSSIGNAL(INPUTSIGNAL, WINDOWSIZE) processes the input
%   signal using a sliding window approach. INPUTSIGNAL is the signal to be
%   processed (numeric vector) and WINDOWSIZE is the size of the sliding window
%   (positive scalar). OUTPUTSIGNAL is the processed signal.
%
%   Example:
%     % Process a simple sine wave with a window size of 5
%     t = 0:0.01:1;
%     signal = sin(2*pi*10*t)';
%     processed = processSignal(signal, 5);
%     
%     % Plot results
%     figure;
%     plot(t, signal, 'b', t, processed, 'r');
%     legend('Original', 'Processed');
%     title('Signal Processing Example');
%
%   See also FILTER, CONV


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

- The header comment must follow a specific structure:
  - Function name in uppercase followed by brief description
  - Main usage description with parameter explanations integrated in the text
  - Additional usage forms (if applicable) in separate paragraphs
  - Example section with complete, runnable code including plotting/visualization
  - "See also" section with related functions
  - No separate "Inputs" and "Outputs" sections - integrate descriptions in the main text
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
% processSignalTest.m - Test class for the processSignal function
classdef processSignalTest < matlab.unittest.TestCase

  methods (TestClassSetup)
    function addCodeToPath(tc)
      addpath('route/to/path');
    end
  end

  methods (Test)
    function testBasicFunctionality(tc)
      % define expected output
      expected = ...;

      % Execute function under test
      actual = processSignal();

      % Verify result
      tc.verifyEqual(actual, expected, 'Basic functionality failed');
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
