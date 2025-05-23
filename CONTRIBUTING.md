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
- Use PascalCase for struct names (e.g., `Setup`)
- Use descriptive names that clearly indicate the purpose of the variable or function

### Code Structure

Each function should have a descriptive header comment following this format:

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
%
% Created by [Author Name]

% Function implementation...
end
```

### Test Structure

Test files should follow this structure:

```matlab
% functionNameTest.m - Test for the functionName function
%
% This script tests the functionName function with different test cases:
% 1. Brief description of test case 1
% 2. Brief description of test case 2
% 3. Brief description of test case n

%% Add source path if needed
addpath('../../src/path/to/function');

%% Print header
fprintf('\n=========================================================\n');
fprintf('          RUNNING FUNCTIONNAME TEST CASES\n');
fprintf('=========================================================\n\n');

%% Test 1: Description of the first test case

% Setup test data
...

% Execute function under test
...

% Test 1 validation - verify expected results
if testCondition
  fprintf('Test 1: Description: passed\n');
else
  fprintf('Test 1: Description: failed\n');
end

%% Test n: Description of additional test cases
...

%% Summarize all results
fprintf('\n---------------------------------------------------------\n');
fprintf('  SUMMARY: %i of %i tests passed\n', ...
  sum([test1Passed, test2Passed, ...]), totalTests);
fprintf('---------------------------------------------------------\n\n');
```

Each test should:

1. Have a descriptive title with the %% section marker
2. Include test setup with clear, descriptive variable names
3. Execute the function being tested
4. Validate results with clear pass/fail criteria
5. Print clear pass/fail messages for each test
6. Include subtests where appropriate (e.g., Test 2a, Test 2b)
7. End with a summary of all test results

### Example Test File

Here is an example of a complete test file for a hypothetical `processSignal` function:

```matlab
% processSignalTest.m - Test for the processSignal function
%
% This script tests the processSignal function with different test cases:
% 1. Test with normal input
% 2. Test with edge case input
% 3. Test with invalid input

%% Add source path if needed
addpath('../../src/');

%% Print header
fprintf('\n=========================================================\n');
fprintf('          RUNNING PROCESSSIGNAL TEST CASES\n');
fprintf('=========================================================\n\n');

%% Test 1: Normal input

% Setup test data
inputSignal = [1, 2, 3, 4, 5];
windowSize = 3;

% Execute function under test
outputSignal = processSignal(inputSignal, windowSize);

% Test 1 validation - verify expected results
expectedOutput = [2, 3, 4];
test1Passed = isequal(outputSignal, expectedOutput);
if test1Passed
  fprintf('Test 1: Normal input: passed\n');
else
  fprintf('Test 1: Normal input: failed\n');
end

%% Test 2: Edge case input

% Setup test data
inputSignal = [1];
windowSize = 3;

% Execute function under test
outputSignal = processSignal(inputSignal, windowSize);

% Test 2 validation - verify expected results
expectedOutput = [1];
test2Passed = isequal(outputSignal, expectedOutput);
if test2Passed
  fprintf('Test 2: Edge case input: passed\n');
else
  fprintf('Test 2: Edge case input: failed\n');
end

%% Test 3: Invalid input

% Setup test data
inputSignal = 'invalid';
windowSize = 3;

% Execute function under test
try
    outputSignal = processSignal(inputSignal, windowSize);
    test3Passed = false;
catch
    test3Passed = true;
end

% Test 3 validation - verify expected results
if test3Passed
  fprintf('Test 3: Invalid input: passed\n');
else
  fprintf('Test 3: Invalid input: failed\n');
end

%% Summarize all results
totalTests = 3;
fprintf('\n---------------------------------------------------------\n');
fprintf('  SUMMARY: %i of %i tests passed\n', ...
  sum([test1Passed, test2Passed, test3Passed]), totalTests);
fprintf('---------------------------------------------------------\n\n');
```

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
