# Code Style Guide

<div class="result" markdown>

:material-code-tags:{ .lg .middle } **Coding standards and style guidelines**

---

This document outlines the coding standards and style guidelines for the biosigmat project.

!!! tip "MATLAB Best Practices"
    Follow these MATLAB-specific conventions for optimal code quality:

    - :material-arrow-down: Use column vectors consistently
    - :material-shield-check: Include appropriate error checking for function inputs
    - :material-alphabetical-variant: Use meaningful variable names instead of single letters when possible (except for common math notation)
    - :material-group: Group related code blocks with comments


</div>

## :material-translate: Language Requirements

- :material-comment-text: All code comments must be written in English
- :material-function-variant: All variable, function, and file names must be in English  
- :material-book-open: Documentation must be written in English

<div class="grid cards" markdown>

-   :material-format-text:{ .lg .middle } **Short Names**

    ---

    Use **lowercase** for short variable and function names

    **Examples**: `signal`, `fs`, `pwelch`, `filtfilt`

-   :material-format-letter-case:{ .lg .middle } **Compound Names**

    ---

    Use **camelCase** only for longer or compound names

    **Examples**: `filteredSignal`, `inputParser`, `medfiltThreshold`

</div>

!!! tip "Naming Best Practices"
    - :material-tag-text: Use descriptive names that clearly indicate the purpose of the variable or function
    - :material-matlab: Follow MATLAB's built-in function naming style: short names in lowercase when possible



## :material-code-braces: Code Structure

!!! warning "Mandatory Structure"
    Every function must follow this exact structure for consistency and reliability.

### Required Elements

1. **Argument Validation**: Every function must begin by checking the number of input and output arguments using `narginchk` and `nargoutchk`.
2. **Input Parsing**: After argument count checks, use `inputParser` to handle and validate all inputs.
3. **Consistent Implementation**: This structure must be used consistently in all functions.

!!! note "Required Header Format"
    The header comment must follow this specific structure:

    - :material-function: Function name in uppercase followed by brief description
    - :material-text-long: Main usage description with parameter explanations integrated in the text
    - :material-plus-box: Additional usage forms (if applicable) in separate paragraphs
    - :material-code-block-tags: Example section with complete, runnable code including plotting/visualization
    - :material-link-variant: "See also" section with related functions
    - :material-close-circle: **No separate "Inputs" and "Outputs" sections** - integrate descriptions in the main text

### Function Template

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

## :material-test-tube: Test Structure

Test files must define a test class using MATLAB's unittest framework.

Follow these requirements for all test files:

- :material-file-code: Filename must be `functionNameTest.m` located under `test/` with matching subfolder
- :material-cog: Include a `methods (TestClassSetup)` block for shared setup (e.g., addpath)
- :material-function-variant: Define one test method per scenario inside `methods (Test)`
- :material-check-bold: Use `tc.verify*` assertions (`verifyEqual`, `verifyTrue`, `verifyWarning`, etc.)
- :material-tag: Name test methods starting with `test` and use descriptive comments

!!! success "Testing Requirements"
    Comprehensive testing ensures code reliability and maintainability.

Each test file must begin with a header comment summarizing the test scenarios covered:

```matlab
% Tests covering:
%   - Basic functionality
%   - Edge-case handling
%   - Special values (NaN, Inf)
```



## :material-school: Example Structure

- :material-file-document: Filename must be `functionNameExample.m` and be located under `examples/` with a matching subfolder to the function in `src/`
- :material-comment-text: Add comments throughout to explain each step and the purpose of the code blocks
- :material-play: The example should be runnable as-is and produce meaningful output or plots

!!! success "Documentation Through Examples"
    Each example file must demonstrate function usage in a clear, reproducible, and self-contained way.


Begin with a header comment summarizing what the example demonstrates:

```matlab
% BASELINEREMOVEEXAMPLE Example demonstrating baseline wander removal from ECG signals.
%
% This example demonstrates how to effectively remove baseline wander from real ECG
% signals using the baselineremove function. The process involves loading ECG signal
% data from a CSV file and applying baseline removal techniques to eliminate
% low-frequency artifacts that can interfere with ECG analysis. The example shows
% the comparison between original and processed signals through visualization,
% highlighting the effectiveness of the baseline removal algorithm in preserving
% the ECG morphology while eliminating unwanted baseline drift.


% ...function implementation...
```
