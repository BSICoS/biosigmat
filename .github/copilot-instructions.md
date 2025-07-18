# GitHub Copilot Instructions for biosigmat

## General Development Guidelines

### Work Scope
- **ALWAYS ask before creating additional functions, tests, examples, or workflows** that are not explicitly requested
- Only create what is specifically asked for in the user's request
- Do not assume additional components are needed unless explicitly stated
- When in doubt, ask the user for clarification about scope

### Test Creation Guidelines
- **Only create tests when explicitly requested** by the user
- When creating tests, **always start with basic functionality tests first**
- If the user doesn't specify whether to use fixtures or synthetic signals, **ask which approach they prefer**
- Create tests incrementally - only implement the specific tests requested, not comprehensive test suites
- Do not create all possible tests at once unless specifically asked to do so

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
- Each function should have a descriptive header comment explaining its purpose, inputs, and outputs
- Use appropriate spacing and indentation for readability
- Group related code blocks with comments that explain the general approach or algorithm
- Avoid redundant comments that simply restate what self-explanatory variable, function, or class names already convey
- Focus comments on explaining the "why" and "how" of code blocks, not the obvious "what"
- Functions in the `tools` directory should include usage examples in their help documentation rather than having separate example files

### Indentation
- Always use 4 spaces for indentation.

### Consistency
- When writing a method, test, or example, always refer to other files in the directory to ensure consistency in structure, style, and formatting.

### Test Structure

- Each test file must begin with a header comment summarizing the test scenarios covered. For example:
% Tests covering:
%   - Basic functionality
%   - Edge-case handling
%   - Special values (NaN, Inf)

**Test Creation Process:**
- Always start with basic functionality tests when creating new test files
- Ask the user whether to use fixture data or synthetic signals if not specified
- Create tests incrementally based on user requests, not comprehensive test suites
- Only implement the specific test scenarios requested by the user

Test files should define a test class using MATLAB's unittest framework:

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
      % Setup test data
      inputData = [1, 2, 3, 4, 5];
      expected = [2, 4, 6, 8, 10];
      
      % Execute function under test
      actual = functionName(inputData);
      
      % Verify results
      tc.verifyEqual(actual, expected, 'Basic functionality failed');
    end

    function testEdgeCase(tc)
      % Test with empty input
      actual = functionName([]);
      tc.verifyEmpty(actual, 'Empty input handling failed');
    end
  end

end
```

Test files must:
- Be named `functionNameTest.m` and located in `test/tools/` or the corresponding subfolder
- Include a `methods (TestClassSetup)` block for common setup (e.g., adding paths)
- Define individual test methods inside a `methods (Test)` block, each prefixed with `test`
- Use `tc.verify*` assertions (e.g., `verifyEqual`, `verifyTrue`, `verifyWarning`) for pass/fail checks
- Use descriptive method names and comments for clarity
- Use fixture data from the `fixtures/` directory whenever possible instead of generating test data programmatically
- Include comprehensive input/output validation testing for the validations implemented in the function:
  - Test invalid input types only if the function validates them (empty arrays, scalars, non-numeric data, strings, character arrays)
  - Test special input types only if the function handles them (logical arrays, complex numbers)
  - Test boundary conditions and edge cases relevant to the function's logic
  - Test parameter validation only for parameters that the function actually validates (invalid ranges, negative values, zero values)
  - Verify error handling with `tc.verifyError()` only for errors that the function is designed to throw
  - Test input format conversion only if the function performs such conversions (row vs column vectors)
  - Input and output checks to be tested must match those of the function being tested. Checks not present in the function under test should not be included.
  - All checks implemented in a function must be tested.

## MATLAB-Specific Guidelines
- Use column vectors consistently
- Include appropriate error checking for function inputs
- Use meaningful variable names instead of single letters when possible (except for common math notation)

# Function Structure Requirements
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
%
% Example:
%   % Process a simple sine wave with a window size of 5
%   t = 0:0.01:1;
%   signal = sin(2*pi*10*t)';
%   processed = processSignal(signal, 5);
%   plot(t, signal, 'b', t, processed, 'r');
%   legend('Original', 'Processed');

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