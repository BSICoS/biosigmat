% Tests covering:
%   - No NaNs (identity)
%   - Expansion around NaN segments (vector, preserves orientation)
%   - Column-wise processing for matrix inputs
%   - No expansion when seconds = 0
%   - Invalid input handling

classdef expandnansTest < matlab.unittest.TestCase

    methods (TestClassSetup)
        function addCodeToPath(~)
            addpath('../../src/tools');
        end
    end

    methods (Test)
        function testNoNansReturnsSame(tc)
            signal = (1:20)';
            fs = 10;
            seconds = 0.5;

            actual = expandnans(signal, fs, seconds);

            tc.verifyEqual(actual, signal);
        end

        function testVectorExpansionPreservesOrientation(tc)
            signal = 1:20; % row vector input
            fs = 10;
            seconds = 0.2; % cleanWindow = 2 samples

            signal(11) = NaN;
            actual = expandnans(signal, fs, seconds);

            expected = 1:20;
            expected(9:13) = NaN;

            tc.verifyTrue(isrow(actual), 'Output should preserve row-vector orientation');
            tc.verifyEqual(actual, expected);
        end

        function testMatrixProcessedColumnwise(tc)
            fs = 10;
            seconds = 0.1; % cleanWindow = 1 sample

            signal = repmat((1:12)', 1, 2);
            signal(5, 1) = NaN;  % should expand to 4:6 in col 1
            signal(9, 2) = NaN;  % should expand to 8:10 in col 2

            actual = expandnans(signal, fs, seconds);

            expected = signal;
            expected(4:6, 1) = NaN;
            expected(8:10, 2) = NaN;

            tc.verifyEqual(actual, expected);
        end

        function testSecondsZeroDoesNotExpand(tc)
            fs = 10;
            seconds = 0;

            signal = (1:20)';
            signal(10) = NaN;

            actual = expandnans(signal, fs, seconds);

            tc.verifyEqual(actual, signal);
        end

        function testInvalidInputs(tc)
            signal = (1:10)';

            tc.verifyError(@() expandnans(signal, 0, 0.1), 'MATLAB:InputParser:ArgumentFailedValidation');
            tc.verifyError(@() expandnans(signal, 10, -0.1), 'MATLAB:InputParser:ArgumentFailedValidation');
        end
    end
end
