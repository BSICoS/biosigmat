% runTests.m
% Script to run all MATLAB tests

% Create a test suite from the test folder
suite = testsuite('test', 'IncludeSubfolders', true);

% Run the test suite and display the results
results = run(suite);

% Exit with an error code if any test fails (important for the pre-push hook)
if any([results.Failed])
  error('Some tests failed. Please fix them before pushing.');
end
