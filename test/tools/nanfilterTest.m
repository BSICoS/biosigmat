% Tests covering:
%   - Basic functionality with filter
%   - NaN gap handling (short and long gaps)
%   - Edge cases (all NaN, no NaN)
%   - Multi-column processing
%   - Parameter validation

classdef nanfilterTest < matlab.unittest.TestCase

    methods (TestClassSetup)
        function addCodeToPath(~)
            addpath('../../src/tools');
        end
    end

    methods (Test)
        function testBasicFunctionality(tc)
            % Test basic filtering without NaN values
            x = [1; 2; 3; 4; 5];
            [b, a] = butter(2, 0.5);

            y = nanfilter(b, a, x, 10);
            expected = filter(b, a, x);

            tc.verifyEqual(y, expected, 'RelTol', 1e-12, 'Basic filtering failed');
        end

        function testShortNanGaps(tc)
            % Test filtering with short NaN gaps that should be interpolated
            x = [1; 2; NaN; 4; 5; 6; NaN; NaN; 9; 10];
            [b, a] = butter(2, 0.5);
            maxgap = 5;

            y = nanfilter(b, a, x, maxgap);

            tc.verifyTrue(all(~isnan(y)), 'Short NaN gaps should be interpolated');
        end

        function testLongNanGaps(tc)
            % Test filtering with long NaN gaps that should be preserved
            x = [1; 2; 3; NaN; NaN; NaN; NaN; NaN; NaN; 7; 8; 9];
            [b, a] = butter(2, 0.5);
            maxgap = 3;

            y = nanfilter(b, a, x, maxgap);

            tc.verifyTrue(any(isnan(y)), 'Long NaN gaps should be preserved');
            tc.verifyEqual(sum(isnan(y)), 6, 'Number of NaN values should be preserved');
        end

        function testMixedNanGaps(tc)
            % Test filtering with both short and long NaN gaps
            x = [1; 2; NaN; 4; 5; NaN; NaN; NaN; NaN; NaN; 10; 11; NaN; 13; 14];
            [b, a] = butter(2, 0.5);
            maxgap = 2;

            y = nanfilter(b, a, x, maxgap);

            % Short gaps should be filled, long gaps preserved
            tc.verifyTrue(sum(isnan(y)) < sum(isnan(x)), 'Some NaN gaps should be filled');
            tc.verifyTrue(sum(isnan(y)) > 0, 'Long NaN gaps should be preserved');
        end

        function testAllNanInput(tc)
            % Test with input that is all NaN
            x = NaN(10, 1);
            [b, a] = butter(2, 0.5);

            y = nanfilter(b, a, x, 5);

            tc.verifyTrue(all(isnan(y)), 'All NaN input should return all NaN');
            tc.verifyEqual(size(y), size(x), 'Output size should match input size');
        end

        function testMultiColumnProcessing(tc)
            % Test processing of multiple columns independently
            x = [1, 10; 2, 20; NaN, 30; 4, NaN; 5, 50];
            [b, a] = butter(2, 0.5);
            maxgap = 1;

            y = nanfilter(b, a, x, maxgap);

            % Both columns should be processed
            tc.verifyTrue(all(~isnan(y(:))), 'All short NaN gaps should be filled');
            tc.verifyEqual(size(y), size(x), 'Output size should match input size');
        end

        function testMaxgapNotSpecified(tc)
            % Test warning when maxgap is not specified
            x = [1; 2; NaN; 4; 5];
            [b, a] = butter(2, 0.5);

            % Should issue warning
            tc.verifyWarning(@() nanfilter(b, a, x), 'nanfilter:maxgapNotSpecified');
        end

        function testParameterValidation(tc)
            % Test input parameter validation
            x = [1; 2; 3; 4; 5];
            [b, a] = butter(2, 0.5);

            % Test invalid b parameter
            tc.verifyError(@() nanfilter('invalid', a, x, 5), 'MATLAB:InputParser:ArgumentFailedValidation');

            % Test invalid a parameter
            tc.verifyError(@() nanfilter(b, 'invalid', x, 5), 'MATLAB:InputParser:ArgumentFailedValidation');

            % Test invalid maxgap parameter
            tc.verifyError(@() nanfilter(b, a, x, -1), 'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function testEmptyInput(tc)
            % Test with empty input
            x = [];
            [b, a] = butter(2, 0.5);

            y = nanfilter(b, a, x, 5);

            tc.verifyEmpty(y, 'Empty input should return empty output');
        end

        function testRowVectorInput(tc)
            % Test with row vector input
            x = [1, 2, NaN, 4, 5];
            [b, a] = butter(2, 0.5);
            maxgap = 10; % Large enough to interpolate the single NaN

            y = nanfilter(b, a, x, maxgap);

            % With maxgap = 10, the single NaN should be interpolated and filtered
            tc.verifyTrue(all(~isnan(y)), 'Row vector with short NaN gap should be processed correctly');
            tc.verifyEqual(size(y), size(x), 'Output size should match input size');
        end
    end

end
