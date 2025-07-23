% interpgapTest.m - Test class for the interpgap function
% Tests covering:
%   - Basic functionality using header example
%   - Optional interpolation method parameter

classdef interpgapTest < matlab.unittest.TestCase

    methods (TestClassSetup)
        function addCodeToPath(~)
            addpath('../../src/tools');
        end
    end

    methods (Test)
        function testHeaderExample(tc)
            % Test using the example from the function header
            signal = [1, 2, NaN, 4, 5, NaN, NaN, 8, 9, 10]';
            maxgap = 1;

            % Expected result: interpolate single NaN and double NaN gaps
            expected = [1, 2, 3, 4, 5, NaN, NaN, 8, 9, 10]';

            % Execute function under test
            actual = interpgap(signal, maxgap);

            % Verify results with tolerance
            tc.verifyEqual(actual, expected, 'AbsTol', 1e-10, ...
                'Header example interpolation failed');
        end

        function testInterpolationMethod(tc)
            signal = [1, 3, NaN, 7, 9]';
            maxgap = 1;

            resultCubic = interpgap(signal, maxgap, 'cubic');
            expectedLinear = [1, 3, 5, 7, 9]';
            tc.verifyEqual(resultCubic, expectedLinear, 'AbsTol', 1e-10, ...
                'Linear interpolation (default) failed');

            resultSpline = interpgap(signal, maxgap, 'spline');
            tc.verifyEqual(resultSpline, expectedLinear, 'AbsTol', 1e-10, ...
                'Explicit linear interpolation failed');

            resultNearest = interpgap(signal, maxgap, 'nearest');
            expectedNearest = [1, 3, 7, 7, 9]';
            tc.verifyEqual(resultNearest, expectedNearest, 'AbsTol', 1e-10, ...
                'Nearest interpolation failed');

            resultsPchip = interpgap(signal, maxgap, 'pchip');
            tc.verifyEqual(resultsPchip, expectedLinear, 'AbsTol', 1e-10, ...
                'PCHIP interpolation failed');
        end
    end

end
