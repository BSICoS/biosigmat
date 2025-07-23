% runTests.m
% Script to run all MATLAB tests or a specific subset
%
% Usage:
%   runTests()              - Run all tests
%   runTests('tools')       - Run tests from the tools folder
%   runTests('nanfiltfilt') - Run tests for a specific function
%   runTests('tools/nanfiltfilt') - Run specific test class

function runTests(varargin)
% Parse input arguments
if nargin == 0
    % Run all tests
    testPattern = 'test';
    includeSubfolders = true;
    fprintf('Running all tests...\n');
else
    testPattern = varargin{1};
    includeSubfolders = true;

    % Check if pattern is a specific test class or folder
    if contains(testPattern, '/')
        % Specific test class like 'tools/nanfiltfilt'
        parts = split(testPattern, '/');
        testPath = fullfile('test', parts{1}, [parts{2} 'Test.m']);
        fprintf('Running tests for: %s\n', testPattern);
    else
        % Folder or function name
        % First try as a folder in test directory
        testPath = fullfile('test', testPattern);
        if ~exist(testPath, 'dir')
            % Try as a specific test file
            testPath = fullfile('test', 'tools', [testPattern 'Test.m']);
            if ~exist(testPath, 'file')
                % Try in other subdirectories (ecg, hrv)
                testPath = fullfile('test', 'ecg', [testPattern 'Test.m']);
                if ~exist(testPath, 'file')
                    testPath = fullfile('test', 'hrv', [testPattern 'Test.m']);
                    if ~exist(testPath, 'file')
                        error('Test pattern "%s" not found. Check folder or function name.', testPattern);
                    end
                end
            end
        end
        fprintf('Running tests matching pattern: %s\n', testPattern);
    end
    testPattern = testPath;
end

% Add the common test directory to the path for shared test utilities
addpath('test/common');

% Create a test suite from the specified pattern
suite = testsuite(testPattern, 'IncludeSubfolders', includeSubfolders);

if isempty(suite)
    warning('No tests found matching pattern: %s', testPattern);
    return;
end

% Run the test suite and display the results
results = run(suite);

% Display timing information grouped by test file
fprintf('\n=== Individual Test Timings ===\n');

% Group tests by test class
testGroups = containers.Map();
for i = 1:length(results)
    % Extract test class name (part before the first '/')
    testName = results(i).Name;
    slashIndex = find(testName == '/', 1);
    if ~isempty(slashIndex)
        testClass = testName(1:slashIndex-1);
    else
        testClass = testName;
    end

    if isKey(testGroups, testClass)
        testGroups(testClass) = [testGroups(testClass), i];
    else
        testGroups(testClass) = i;
    end
end

% Display results grouped by test class
testClasses = keys(testGroups);
testClasses = sort(testClasses);

for j = 1:length(testClasses)
    testClass = testClasses{j};
    testIndices = testGroups(testClass);

    % Calculate total time and status for this test class
    classTime = sum([results(testIndices).Duration]);
    classFailed = sum([results(testIndices).Failed]);
    classIncomplete = sum([results(testIndices).Incomplete]);

    % Determine overall class status
    if classFailed > 0
        classStatus = 'FAILED';
    elseif classIncomplete > 0
        classStatus = 'INCOMPLETE';
    else
        classStatus = 'PASSED';
    end

    % Display test class summary with test count
    fprintf('%-64s | %-10s | %2d tests | %.4f seconds\n', ...
        testClass, classStatus, length(testIndices), classTime);

    % Display individual tests within this class (indented)
    for k = 1:length(testIndices)
        i = testIndices(k);
        status = 'UNKNOWN';
        if results(i).Passed
            status = 'PASSED';
        elseif results(i).Failed
            status = 'FAILED';
        elseif results(i).Incomplete
            status = 'INCOMPLETE';
        end

        fprintf('    %-60s | %-10s | %.4f seconds\n', ...
            results(i).Name, status, results(i).Duration);
    end

    % Add a blank line between test classes for better readability
    if j < length(testClasses)
        fprintf('\n');
    end
end

% Display detailed results with timing information
fprintf('\n=== Test Results Summary ===\n');
fprintf('Total tests: %d\n', length(results));
fprintf('Passed: %d\n', sum([results.Passed]));
fprintf('Failed: %d\n', sum([results.Failed]));
fprintf('Incomplete: %d\n', sum([results.Incomplete]));

% Display total execution time
totalTime = sum([results.Duration]);
fprintf('\nTotal execution time: %.4f seconds\n', totalTime);

% Exit with an error code if any test fails (important for the pre-push hook)
if any([results.Failed])
    error('Some tests failed. Please fix them before pushing.');
end
