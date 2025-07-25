# Code Style Guide

This document outlines the coding standards and style guidelines for the biosigmat project.

## Language

- All code comments must be written in English
- All variable, function, and file names must be in English
- Documentation must be written in English

## Naming Conventions

- Use lowercase for short variable and function names (e.g., `signal`, `fs`, `pwelch`, `filtfilt`)
- Use camelCase only for longer or compound names (e.g., `filteredSignal`, `inputParser`, `medfiltThreshold`)
- Use descriptive names that clearly indicate the purpose of the variable or function
- Follow MATLAB's built-in function naming style: short names in lowercase when possible

## Code Structure

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

## Test Structure

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
