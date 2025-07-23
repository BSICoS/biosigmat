% RUNEXAMPLESTEST - Test script to verify all examples run without errors
%
% This script automatically discovers and executes all example files in the
% examples directory to ensure they run without errors. Figures are created
% invisibly during testing and the default visibility is restored at the end.
%
% The script searches for all .m files in the examples/ directory and its
% subdirectories, then runs each one to verify it executes without errors.

function runExamplesTest()

fprintf('Running examples test...\n');
fprintf('========================\n\n');

% Store original figure visibility setting
originalVisibility = get(0, 'DefaultFigureVisible');

% Set figures to be invisible during testing
set(0, 'DefaultFigureVisible', 'off');

% Initialize test results
testResults = struct();
totalTests = 0;
passedTests = 0;

% Start total execution timer
totalStartTime = tic;

% Automatically discover all example files
exampleFiles = findExampleFiles();

% Store current directory to restore later
originalDir = pwd;

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

        % Start timer for this example
        exampleStartTime = tic;

        try
            % Change to the directory containing the example
            [exampleDir, ~, ~] = fileparts(exampleFile);
            cd(exampleDir);

            % Get the filename without path
            [~, exampleFunction, ~] = fileparts(exampleFile);

            % Run the example and capture output to suppress it
            evalc(exampleFunction);

            % Calculate execution time
            exampleTime = toc(exampleStartTime);

            % If we get here, the example ran successfully
            fprintf('  Result: PASSED\n');
            fprintf('  Execution time: %.3f seconds\n\n', exampleTime);
            testResults.(sprintf('test%d', i)) = struct('name', exampleFile, 'status', 'PASSED', 'error', '', 'time', exampleTime);
            passedTests = passedTests + 1;

            % Close any figures that might have been created
            close all;

        catch ME
            % Calculate execution time even for failed examples
            exampleTime = toc(exampleStartTime);

            % Example failed
            fprintf('  Result: FAILED\n');
            fprintf('  Execution time: %.3f seconds\n', exampleTime);
            fprintf('  Error: %s\n\n', ME.message);
            testResults.(sprintf('test%d', i)) = struct('name', exampleFile, 'status', 'FAILED', 'error', ME.message, 'time', exampleTime);

            % Close any figures that might have been created
            close all;
        end

        % Return to original directory
        cd(originalDir);
    end

catch ME
    % Restore original directory in case of unexpected error
    cd(originalDir);
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
        testField = sprintf('test%d', i);
        if strcmp(testResults.(testField).status, 'FAILED')
            fprintf('  - %s: %s (%.3f seconds)\n', testResults.(testField).name, testResults.(testField).error, testResults.(testField).time);
        end
    end
end

% Print execution time breakdown
fprintf('\nExecution Time Breakdown:\n');
fprintf('=========================\n');
for i = 1:totalTests
    testField = sprintf('test%d', i);
    result = testResults.(testField);
    status = result.status;
    if strcmp(status, 'PASSED')
        statusIcon = '✓';
    else
        statusIcon = '✗';
    end
    fprintf('  %s %s: %.3f seconds\n', statusIcon, result.name, result.time);
end
fprintf('  Total: %.3f seconds\n', totalTime);

% Restore original figure visibility setting
set(0, 'DefaultFigureVisible', originalVisibility);

fprintf('\nFigure visibility restored to: %s\n', originalVisibility);
fprintf('You can now run examples normally and figures will be displayed.\n');

end

function exampleFiles = findExampleFiles()
% FINDEXAMPLEFILES Automatically discover example and workflow files
%
% Returns a cell array of relative paths to files ending in 'Example.m' or
% 'Workflow.m' found in the examples directory and its subdirectories.

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
