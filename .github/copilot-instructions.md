# GitHub Copilot Instructions for biosigmat

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
- Each function should have a descriptive header comment explaining its purpose, inputs, and outputs
- Use appropriate spacing and indentation for readability
- Group related code blocks with comments

### Test Structure
- Test files should be named `functionNameTest.m` and placed in the corresponding subfolder in `test/`
- The first test should always be a dependency check that verifies all required non-MATLAB functions are available
- Test files should include multiple test cases validating different aspects of the function
- Each test case should have a descriptive title with %% section markers
- Test cases should print clear pass/fail messages
- Test files should end with a summary of all test results

### Example Function:
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

% Initialize variables
signalLength = length(inputSignal);
outputSignal = zeros(signalLength, 1);

% Process signal
for idx = 1:signalLength
    % ...processing logic...
end

end
```

### Example Test:
```matlab
% processSignalTest.m - Test for the processSignal function
%
% This script tests the processSignal function with different test cases:
% 1. Dependencies check (checks if required functions are available)
% 2. Basic functionality with simple input
% 3. Edge case with zero window size
% 4. Error handling with invalid inputs

%% Add source path if needed
addpath('../../src/path/to/function');

%% Print header
fprintf('\n=========================================================\n');
fprintf('          RUNNING PROCESSSIGNAL TEST CASES\n');
fprintf('=========================================================\n\n');

%% Test 1: Dependencies check

% Test if all required dependencies are available
dependenciesOk = true;
missingDependencies = {};

% Check for required functions
if ~exist('requiredFunction', 'file')
  dependenciesOk = false;
  missingDependencies{end+1} = 'requiredFunction';
end

% Print test results
if dependenciesOk
  fprintf('Test 1: All dependencies available: passed\n');
else
  fprintf('Test 1: All dependencies available: failed\n');
  fprintf(' - Missing dependencies: ');
  for i = 1:length(missingDependencies)
    if i > 1
      fprintf(', ');
    end
    fprintf('%s', missingDependencies{i});
  end
  fprintf('\n');
end

%% Test 2: Basic functionality

% Setup test data
inputSignal = [1, 2, 3, 4, 5]';
windowSize = 3;

% Execute function under test
result = processSignal(inputSignal, windowSize);

% Test validation
expected = [2, 3, 3, 4, 3]';
testPassed = all(abs(result - expected) < 1e-10);

if testPassed
  fprintf('Test 1: Basic functionality: passed\n');
else
  fprintf('Test 1: Basic functionality: failed\n');
end

%% Additional tests...

%% Summarize all results
fprintf('\n---------------------------------------------------------\n');
fprintf('  SUMMARY: %i of %i tests passed\n', sum([dependenciesOk, testPassed, ...]), totalTests);
fprintf('---------------------------------------------------------\n\n');
```

## MATLAB-Specific Guidelines
- Use column vectors consistently
- Include appropriate error checking for function inputs
- Use meaningful variable names instead of single letters when possible (except for common math notation)
