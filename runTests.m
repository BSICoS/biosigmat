% runTests.m
% Adds source folders to path, runs unit tests, and produces a JUnit report.

function runTests
% Determine the full path of this script
currentFile = mfilename('fullpath');
% Get the directory where this script lives (project_root/runTests.m)
scriptDir = fileparts(currentFile);
% Assume tests are under project_root/test/tools and code under project_root/src/tools
projectRoot = fileparts(scriptDir);

% Add source folder so that MATLAB can find your functions
addpath(fullfile(projectRoot, 'src', 'tools'));

import matlab.unittest.TestRunner;
import matlab.unittest.plugins.XMLPlugin;

% Create a test suite from all TestCase classes in test/tools
suite = testsuite(fullfile(projectRoot, 'test', 'tools'));

% Create a runner that prints text output with verbosity level 2
runner = TestRunner.withTextOutput('Verbosity', 2);

% Attach a plugin to produce a JUnit-format XML file
junitPlugin = XMLPlugin.producingJUnitFormat('junit_results.xml');
runner.addPlugin(junitPlugin);

% Run the suite
results = runner.run(suite);

% Display a table of results in the MATLAB console
disp(table(results));

% Exit with a nonzero status if any test failed
exitCode = sum([results.Failed]);
if exitCode > 0
  exit(exitCode);
else
  exit(0);
end
end
