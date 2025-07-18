% Tests covering:
%   - Vector input with different threshold combinations
%   - Invalid input handling
%   - Dimension mismatch validation

classdef ispeakyTest < matlab.unittest.TestCase

    methods (TestClassSetup)
        function addCodeToPath(~)
            addpath('../../src/tools');
        end
    end

    methods (Test)
        function testVectorWithDifferentThresholds(tc)
            % Test with a larger vector of synthetic values
            pkl = [20; 35; 45; 55; 65; 75; 85; 95];
            akl = [70; 80; 85; 90; 88; 92; 95; 98];

            % Test with moderate thresholds
            pklThreshold = 50;
            aklThreshold = 85;
            expected = [false; false; false; true; true; true; true; true];
            actual = ispeaky(pkl, akl, pklThreshold, aklThreshold);
            tc.verifyEqual(actual, expected, 'Moderate thresholds test failed');

            % Test with strict thresholds
            pklThreshold = 70;
            aklThreshold = 90;
            expected = [false; false; false; false; false; true; true; true];
            actual = ispeaky(pkl, akl, pklThreshold, aklThreshold);
            tc.verifyEqual(actual, expected, 'Strict thresholds test failed');

            % Test with lenient thresholds
            pklThreshold = 30;
            aklThreshold = 75;
            expected = [false; true; true; true; true; true; true; true];
            actual = ispeaky(pkl, akl, pklThreshold, aklThreshold);
            tc.verifyEqual(actual, expected, 'Lenient thresholds test failed');
        end

        function testSingleValues(tc)
            % Test with scalar inputs
            pkl = 60;
            akl = 90;
            pklThreshold = 50;
            aklThreshold = 85;

            expected = true;
            actual = ispeaky(pkl, akl, pklThreshold, aklThreshold);
            tc.verifyEqual(actual, expected, 'Single values test failed');
        end

        function testRowVectors(tc)
            % Test with row vectors
            pkl = [30, 50, 70];
            akl = [80, 90, 95];
            pklThreshold = 45;
            aklThreshold = 85;

            expected = [false, true, true];
            actual = ispeaky(pkl, akl, pklThreshold, aklThreshold);
            tc.verifyEqual(actual, expected, 'Row vectors test failed');
        end

        function testDimensionMismatch(tc)
            % Test dimension mismatch error
            pkl = [30; 50; 70];
            akl = [80; 90];  % Different size
            pklThreshold = 45;
            aklThreshold = 85;

            tc.verifyError(@() ispeaky(pkl, akl, pklThreshold, aklThreshold), ...
                'ispeaky:DimensionMismatch', ...
                'Should throw dimension mismatch error');
        end

        function testInvalidThresholds(tc)
            % Test invalid threshold values
            pkl = [50; 60];
            akl = [80; 90];

            % Test negative threshold
            tc.verifyError(@() ispeaky(pkl, akl, -10, 85), ...
                'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Should throw error for negative pkl threshold');

            % Test threshold > 100
            tc.verifyError(@() ispeaky(pkl, akl, 50, 150), ...
                'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Should throw error for akl threshold > 100');
        end
    end
end
