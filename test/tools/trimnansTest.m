% trimnansTest.m - Test class for the trimnans function
% Tests covering:
%   - Basic functionality with different NaN combinations
%   - Edge cases with all NaN or no NaN signals

classdef trimnansTest < matlab.unittest.TestCase

    methods (TestClassSetup)
        function addCodeToPath(~)
            addpath('../../src/tools');
        end
    end

    methods (Test)
        function testBasicFunctionality(tc)
            signal = [NaN; NaN; 1; 2; NaN; 3; NaN; NaN];
            expected = [1; 2; NaN; 3];

            actual = trimnans(signal);

            tc.verifyEqual(actual, expected, 'Basic functionality with NaN at beginning and end failed');
        end

        function testNanAtBeginningOnly(tc)
            signal = [NaN; NaN; 1; 2; 3; 4];
            expected = [1; 2; 3; 4];

            actual = trimnans(signal);

            tc.verifyEqual(actual, expected, 'NaN at beginning only failed');
        end

        function testNanAtEndOnly(tc)
            signal = [1; 2; 3; 4; NaN; NaN];
            expected = [1; 2; 3; 4];

            actual = trimnans(signal);

            tc.verifyEqual(actual, expected, 'NaN at end only failed');
        end

        function testNanInMiddleOnly(tc)
            signal = [1; 2; NaN; NaN; 3; 4];
            expected = [1; 2; NaN; NaN; 3; 4];

            actual = trimnans(signal);

            tc.verifyEqual(actual, expected, 'NaN in middle only failed');
        end

        function testNoNan(tc)
            signal = [1; 2; 3; 4; 5];
            expected = [1; 2; 3; 4; 5];

            actual = trimnans(signal);

            tc.verifyEqual(actual, expected, 'No NaN values failed');
        end

        function testAllNan(tc)
            signal = [NaN; NaN; NaN; NaN];
            expected = [];

            actual = trimnans(signal);

            tc.verifyEqual(actual, expected, 'All NaN values failed');
        end

        function testSingleValidValue(tc)
            signal = [NaN; NaN; 5; NaN; NaN];
            expected = 5;

            actual = trimnans(signal);

            tc.verifyEqual(actual, expected, 'Single valid value failed');
        end

        function testRowVectorInput(tc)
            signal = [NaN, NaN, 1, 2, NaN, 3, NaN, NaN]; % Row vector
            expected = [1; 2; NaN; 3]; % Column vector

            actual = trimnans(signal);

            tc.verifyEqual(actual, expected, 'Row vector input failed');
        end
    end

end
