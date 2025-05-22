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

### Example:
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

## MATLAB-Specific Guidelines
- Use column vectors consistently
- Include appropriate error checking for function inputs
- Use meaningful variable names instead of single letters when possible (except for common math notation)
