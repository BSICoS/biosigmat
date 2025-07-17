% runTestsCI.m
% Script to run all MATLAB tests in CI environment with GitHub Actions integration

function runTestsCI()
% Run all tests in a CI-friendly manner
% This version generates JUnit XML reports and coverage data for GitHub Actions

try
    % Add necessary paths
    addpath('test/common');
    addpath(genpath('src'));

    % Create test suite from test folder
    suite = testsuite('test', 'IncludeSubfolders', true);

    % Create test runner with detailed output
    runner = matlab.unittest.TestRunner.withTextOutput('OutputDetail', matlab.unittest.Verbosity.Detailed);

    % Add JUnit plugin for GitHub Actions integration
    junitPlugin = matlab.unittest.plugins.XMLPlugin.producingJUnitFormat('test-results.xml');
    runner.addPlugin(junitPlugin);

    % Add coverage plugin if src folder exists
    if exist('src', 'dir')
        coveragePlugin = matlab.unittest.plugins.CodeCoveragePlugin.forFolder('src', ...
            'Producing', matlab.unittest.plugins.codecoverage.CoberturaFormat('coverage.xml'));
        runner.addPlugin(coveragePlugin);
    end

    % Run the test suite
    results = runner.run(suite);

    % Display comprehensive summary
    fprintf('\n=== MATLAB Test Summary ===\n');
    fprintf('Total tests: %d\n', length(results));
    fprintf('Passed: %d\n', sum([results.Passed]));
    fprintf('Failed: %d\n', sum([results.Failed]));
    fprintf('Incomplete: %d\n', sum([results.Incomplete]));

    % Show failed tests details
    failedTests = results(~[results.Passed]);
    if ~isempty(failedTests)
        fprintf('\n=== Failed Tests ===\n');
        for i = 1:length(failedTests)
            fprintf('FAILED: %s\n', failedTests(i).Name);
            if ~isempty(failedTests(i).Details)
                fprintf('  Details: %s\n', failedTests(i).Details.DiagnosticRecord.Report);
            end
        end
    end

    % Display total execution time
    totalTime = sum([results.Duration]);
    fprintf('\nTotal execution time: %.2f seconds\n', totalTime);

    % Generate GitHub Actions summary
    if isCI()
        generateGitHubSummary(results);
    end

    % Exit with error code if any tests failed
    if any([results.Failed]) || any([results.Incomplete])
        error('One or more tests failed or were incomplete');
    end

    fprintf('\n✅ All tests passed successfully!\n');

catch ME
    fprintf('❌ Error running tests: %s\n', ME.message);
    if isCI()
        exit(1);
    else
        rethrow(ME);
    end
end
end

function result = isCI()
% Check if running in CI environment
result = ~isempty(getenv('CI')) || ~isempty(getenv('GITHUB_ACTIONS'));
end

function generateGitHubSummary(results)
% Generate GitHub Actions summary markdown
try
    summaryFile = getenv('GITHUB_STEP_SUMMARY');
    if ~isempty(summaryFile)
        fid = fopen(summaryFile, 'w');
        if fid ~= -1
            fprintf(fid, '# MATLAB Test Results\n\n');
            fprintf(fid, '## Summary\n\n');
            fprintf(fid, '| Metric | Value |\n');
            fprintf(fid, '|--------|-------|\n');
            fprintf(fid, '| Total Tests | %d |\n', length(results));
            fprintf(fid, '| Passed | %d |\n', sum([results.Passed]));
            fprintf(fid, '| Failed | %d |\n', sum([results.Failed]));
            fprintf(fid, '| Incomplete | %d |\n', sum([results.Incomplete]));
            fprintf(fid, '| Success Rate | %.1f%% |\n', (sum([results.Passed])/length(results))*100);

            % Add failed tests section if any
            failedTests = results(~[results.Passed]);
            if ~isempty(failedTests)
                fprintf(fid, '\n## Failed Tests\n\n');
                for i = 1:length(failedTests)
                    fprintf(fid, '- **%s**\n', failedTests(i).Name);
                    if ~isempty(failedTests(i).Details)
                        fprintf(fid, '  ```\n  %s\n  ```\n', failedTests(i).Details.DiagnosticRecord.Report);
                    end
                end
            end

            fclose(fid);
        end
    end
catch
    % Ignore errors in summary generation
end
end
