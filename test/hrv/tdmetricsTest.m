% Tests covering:
%   - Placeholder test for tdmetrics function

classdef tdmetricsTest < matlab.unittest.TestCase

    methods (TestClassSetup)
        function addCodeToPath(~)
            % Add source path for the function under test
            addpath('../../src/hrv');
        end
    end

    methods (Test)
        function testPlaceholder(tc)
            % Placeholder test to ensure tdmetrics function runs without errors
            tm = [0.8, 0.85, 0.82, 0.78, 0.81];
            Output = tdmetrics(tm);
            tc.verifyNotEmpty(Output, 'Output should not be empty');
        end
    end
end
