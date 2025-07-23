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
                details = failedTests(i).Details;
                fprintf('  Details: %s\n', details.DiagnosticRecord.Report);
                if ~isempty(details.DiagnosticRecord.Stack)
                    fprintf('  Location: %s (line %d)\n', ...
                        details.DiagnosticRecord.Stack(1).file, ...
                        details.DiagnosticRecord.Stack(1).line);
                end
            end
        end
    end

    % Display total execution time
    totalTime = sum([results.Duration]);
    fprintf('\nTotal execution time: %.2f seconds\n', totalTime);

    % Display slowest tests for performance monitoring
    if ~isempty(results)
        [~, slowestIdx] = maxk([results.Duration], min(5, length(results)));
        fprintf('\n=== Slowest Tests ===\n');
        for i = 1:length(slowestIdx)
            idx = slowestIdx(i);
            fprintf('%.4f seconds - %s\n', results(idx).Duration, results(idx).Name);
        end
    end

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

            % Add status badge
            if all([results.Passed])
                fprintf(fid, '✅ **All tests passed!**\n\n');
            else
                fprintf(fid, '❌ **Some tests failed**\n\n');
            end

            fprintf(fid, '## Summary\n\n');
            fprintf(fid, '| Metric | Value |\n');
            fprintf(fid, '|--------|-------|\n');
            fprintf(fid, '| Total Tests | %d |\n', length(results));
            fprintf(fid, '| Passed | %d |\n', sum([results.Passed]));
            fprintf(fid, '| Failed | %d |\n', sum([results.Failed]));
            fprintf(fid, '| Incomplete | %d |\n', sum([results.Incomplete]));
            fprintf(fid, '| Success Rate | %.1f%% |\n', (sum([results.Passed])/length(results))*100);
            fprintf(fid, '| Total Duration | %.2f seconds |\n', sum([results.Duration]));

            % Add failed tests section if any
            failedTests = results(~[results.Passed]);
            if ~isempty(failedTests)
                fprintf(fid, '\n## Failed Tests\n\n');
                for i = 1:length(failedTests)
                    fprintf(fid, '- **%s** (%.4f seconds)\n', failedTests(i).Name, failedTests(i).Duration);
                    if ~isempty(failedTests(i).Details)
                        fprintf(fid, '  ```\n  %s\n  ```\n', failedTests(i).Details.DiagnosticRecord.Report);
                    end
                end
            end

            % Add performance information
            if ~isempty(results)
                [~, slowestIdx] = maxk([results.Duration], min(3, length(results)));
                fprintf(fid, '\n## Performance\n\n');
                fprintf(fid, '| Test | Duration |\n');
                fprintf(fid, '|------|----------|\n');
                for i = 1:length(slowestIdx)
                    idx = slowestIdx(i);
                    fprintf(fid, '| %s | %.4f seconds |\n', results(idx).Name, results(idx).Duration);
                end
            end

            fclose(fid);
        end
    end
catch
    % Ignore errors in summary generation
end
end
