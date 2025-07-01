% runTests.m
% Script to run all MATLAB tests

% Create a test suite from the test folder
suite = testsuite('test', 'IncludeSubfolders', true);

% Run the test suite and display the results
results = run(suite);

% Display detailed results with timing information
fprintf('\n=== Test Results Summary ===\n');
fprintf('Total tests: %d\n', length(results));
fprintf('Passed: %d\n', sum([results.Passed]));
fprintf('Failed: %d\n', sum([results.Failed]));
fprintf('Incomplete: %d\n', sum([results.Incomplete]));

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
  classPassed = sum([results(testIndices).Passed]);
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

% Display total execution time
totalTime = sum([results.Duration]);
fprintf('\nTotal execution time: %.4f seconds\n', totalTime);

% Exit with an error code if any test fails (important for the pre-push hook)
if any([results.Failed])
  error('Some tests failed. Please fix them before pushing.');
end
