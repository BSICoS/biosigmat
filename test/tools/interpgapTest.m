% interpgapTest.m - Test class for the interpgap function
% Tests covering:
%   - Basic functionality
%   - Optional interpolation method parameter

classdef interpgapTest < matlab.unittest.TestCase

    methods (TestClassSetup)
        function addCodeToPath(~)
            addpath('../../src/tools');
        end
    end

    methods (Test)
        function testBasicFunctionality(tc)
            signal = [1, 2, NaN, 4, 5, NaN, NaN, 8, 9, 10]';
            maxgap = 1;

            expected = [1, 2, 3, 4, 5, NaN, NaN, 8, 9, 10]';

            actual = interpgap(signal, maxgap);

            % Verify results with tolerance
            tc.verifyEqual(actual, expected, 'AbsTol', 1e-10, ...
                'Basic functionality failed');
        end

        function testInterpolationMethod(tc)
            signal = [1, 3, 5, NaN, 9, 11, 13]';
            maxgap = 1;

            expectedLinear = [1, 3, 5, 7, 9, 11, 13]';

            resultSpline = interpgap(signal, maxgap, 'spline');
            tc.verifyEqual(resultSpline, expectedLinear, 'AbsTol', 1e-10, ...
                'Spline interpolation failed');

            resultsPchip = interpgap(signal, maxgap, 'pchip');
            tc.verifyEqual(resultsPchip, expectedLinear, 'AbsTol', 1e-10, ...
                'PCHIP interpolation failed');

            resultNearest = interpgap(signal, maxgap, 'nearest');
            expectedNearest = [1, 3, 5, 9, 9, 11, 13]';
            tc.verifyEqual(resultNearest, expectedNearest, 'AbsTol', 1e-10, ...
                'Nearest interpolation failed');
        end
    end

end
