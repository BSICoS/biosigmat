% RUNEXAMPLESTEST - Test script to verify all examples run without errors
%
% This script automatically discovers and executes all example files in the
% examples directory to ensure they run without errors. Figures are created
% invisibly during testing and the default visibility is restored at the end.
%
% The script searches for all .m files in the examples/ directory and its
% subdirectories, then runs each one to verify it executes without errors.

function runExamplesTest()

narginchk(0, 0);
nargoutchk(0, 0);

% Get project root directory and change to it (navigate up from scripts/local/ to project root)
projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
cd(projectRoot);
projectRootCleanup = onCleanup(@() cd(projectRoot));

fprintf('Running examples test...\n');
fprintf('========================\n\n');

% Force figure visibility back on when the script finishes so interactive
% example runs after this test behave normally.
restoredVisibility = 'on';
visibilityCleanup = onCleanup(@() set(0, 'DefaultFigureVisible', restoredVisibility));

% Set figures to be invisible during testing
set(0, 'DefaultFigureVisible', 'off');

% Initialize test results
testResults = repmat(struct('name', '', 'status', '', 'error', '', 'time', 0), 0, 1);
totalTests = 0;
passedTests = 0;

% Start total execution timer
totalStartTime = tic;

% Automatically discover all example files
exampleFiles = findExampleFiles();

% Display discovered examples
fprintf('Discovered %d example files:\n', length(exampleFiles));
for i = 1:length(exampleFiles)
    fprintf('  %d. %s\n', i, exampleFiles{i});
end
fprintf('\n');

try
    % Run each example
    for i = 1:length(exampleFiles)
        exampleFile = exampleFiles{i};

        totalTests = totalTests + 1;

        fprintf('Testing: %s\n', exampleFile);

        try
            testResults(totalTests) = runSingleExample(exampleFile);

            % If we get here, the example ran successfully
            fprintf('  Result: PASSED\n');
            fprintf('  Execution time: %.3f seconds\n\n', testResults(totalTests).time);
            passedTests = passedTests + 1;

        catch ME
            testResults(totalTests) = struct('name', exampleFile, 'status', 'FAILED', 'error', ME.message, 'time', NaN);

            % Example failed
            fprintf('  Result: FAILED\n');
            fprintf('  Execution time: N/A\n');
            fprintf('  Error: %s\n\n', ME.message);
        end
    end

catch ME
    rethrow(ME);
end

% Calculate total execution time
totalTime = toc(totalStartTime);

% Print summary
fprintf('Examples Test Summary:\n');
fprintf('=====================\n');
fprintf('Total examples tested: %d\n', totalTests);
fprintf('Passed: %d\n', passedTests);
fprintf('Failed: %d\n', totalTests - passedTests);
fprintf('Total execution time: %.3f seconds\n', totalTime);

if passedTests == totalTests
    fprintf('\nAll examples ran successfully! ✓\n');
else
    fprintf('\nSome examples failed. Check the output above for details.\n');

    % Print details of failed tests
    fprintf('\nFailed examples:\n');
    for i = 1:totalTests
        if strcmp(testResults(i).status, 'FAILED')
            if isnan(testResults(i).time)
                timeLabel = 'N/A';
            else
                timeLabel = sprintf('%.3f seconds', testResults(i).time);
            end
            fprintf('  - %s: %s (%s)\n', testResults(i).name, testResults(i).error, timeLabel);
        end
    end
end

% Print execution time breakdown
fprintf('\nExecution Time Breakdown:\n');
fprintf('=========================\n');
for i = 1:totalTests
    result = testResults(i);
    status = result.status;
    if strcmp(status, 'PASSED')
        statusIcon = '✓';
    else
        statusIcon = '✗';
    end
    if isnan(result.time)
        timeLabel = 'N/A';
    else
        timeLabel = sprintf('%.3f seconds', result.time);
    end
    fprintf('  %s %s: %s\n', statusIcon, result.name, timeLabel);
end
fprintf('  Total: %.3f seconds\n', totalTime);

fprintf('\nFigure visibility restored to: %s\n', restoredVisibility);
fprintf('You can now run examples normally and figures will be displayed.\n');

clear visibilityCleanup projectRootCleanup;

end

function testResult = runSingleExample(exampleFile)
% RUNSINGLEEXAMPLE Execute one example file in an isolated function workspace.

narginchk(1, 1);
nargoutchk(1, 1);

parser = inputParser;
addRequired(parser, 'exampleFile', @(value) ischar(value) || (isstring(value) && isscalar(value)));
parse(parser, exampleFile);

exampleFile = char(parser.Results.exampleFile);
exampleStartTime = tic;

[exampleDir, exampleFunction, ~] = fileparts(exampleFile);
originalDir = pwd;
dirCleanup = onCleanup(@() cd(originalDir));
figureCleanup = onCleanup(@() close('all'));

cd(exampleDir);

% Execute the script in this local function workspace so it cannot overwrite
% loop counters or result variables in runExamplesTest.
evalc(exampleFunction);

testResult = struct('name', exampleFile, 'status', 'PASSED', 'error', '', 'time', toc(exampleStartTime));

clear dirCleanup figureCleanup;
end

function exampleFiles = findExampleFiles()
% FINDEXAMPLEFILES Automatically discover example and workflow files
%
% Returns a cell array of relative paths to files ending in 'Example.m' or
% 'Workflow.m' found in the examples directory and its subdirectories.

narginchk(0, 0);
nargoutchk(1, 1);

exampleFiles = {};

% Check if examples directory exists
if ~exist('examples', 'dir')
    warning('Examples directory not found!');
    return;
end

% Search for files ending in Example.m
examplePattern = fullfile('examples', '**', '*Example.m');
exampleFilesList = dir(examplePattern);

% Search for files ending in Workflow.m
workflowPattern = fullfile('examples', '**', '*Workflow.m');
workflowFilesList = dir(workflowPattern);

% Combine both lists
allFiles = [exampleFilesList; workflowFilesList];

% Build cell array of relative file paths
for i = 1:length(allFiles)
    % Construct relative path from current directory
    relativePath = fullfile(allFiles(i).folder, allFiles(i).name);
    % Convert to relative path from current working directory
    relativePath = strrep(relativePath, [pwd, filesep], '');
    % Normalize file separators
    relativePath = strrep(relativePath, '\', '/');

    exampleFiles{end+1} = relativePath; %#ok<AGROW>
end

% Sort the files for consistent ordering
exampleFiles = sort(exampleFiles);
end
