% Tests covering:
%   - Basic functionality for signal slicing
%   - Parameter validation
%   - Edge cases and error conditions
%   - Output format verification

classdef slicesignalTest < matlab.unittest.TestCase

    properties
        fs
        t
        x
    end

    methods (TestClassSetup)
        function addCodeToPath(~)
            addpath('../../src/tools');
        end
    end

    methods (TestMethodSetup)
        function setupTestSignals(tc)
            tc.fs = 1000;
            tc.t = (0:1/tc.fs:2)';
            tc.x = sin(2*pi*10*tc.t);
        end
    end

    methods (Test)
        function testSlicing(tc)
            [sliced, tcenter] = slicesignal(tc.x, 256, 128, tc.fs);

            % Verify output dimensions
            tc.verifyEqual(size(sliced, 2), length(tcenter), 'Number of time slices should match time vector length');
            tc.verifyEqual(size(sliced, 1), 256, 'Each slice should have the specified length');
            tc.verifyTrue(all(tcenter >= 0), 'All time values should be non-negative');
            tc.verifyTrue(iscolumn(tcenter), 'Time vector should be column vector');
        end

        function testWelch(tc)
            [sliced, tcenter] = slicesignal(tc.x, 256, 128, tc.fs);
            [pxx, f] = pwelch(sliced, [], [], [], tc.fs);

            % Verify output dimensions
            tc.verifyEqual(size(pxx, 2), length(tcenter), 'Number of time slices should match time vector length');
            tc.verifyTrue(all(pxx(:) >= 0), 'All PSD values should be non-negative');
            tc.verifyTrue(all(f >= 0), 'All frequencies should be non-negative');
            tc.verifyTrue(all(tcenter >= 0), 'All time values should be non-negative');
        end

        function testPeriodogram(tc)
            [sliced, tcenter] = slicesignal(tc.x, 256, 128, tc.fs);
            [pxx, f] = periodogram(sliced, [], [], tc.fs);

            % Verify output dimensions
            tc.verifyEqual(size(pxx, 2), length(tcenter), 'Number of time slices should match time vector length');
            tc.verifyTrue(all(pxx(:) >= 0), 'All PSD values should be non-negative');
            tc.verifyTrue(all(f >= 0), 'All frequencies should be non-negative');
            tc.verifyTrue(all(tcenter >= 0), 'All time values should be non-negative');
        end

        function testDifferentOverlapValues(tc)
            % Test with no overlap
            [sliceMatrix1, ~] = slicesignal(tc.x, 256, 0, tc.fs);

            % Test with 50% overlap
            [sliceMatrix2, ~] = slicesignal(tc.x, 256, 128, tc.fs);

            % Test with 75% overlap
            [sliceMatrix3, ~] = slicesignal(tc.x, 256, 192, tc.fs);

            % Higher overlap should give more time slices
            tc.verifyTrue(size(sliceMatrix1, 2) < size(sliceMatrix2, 2), 'Higher overlap should produce more time slices');
            tc.verifyTrue(size(sliceMatrix2, 2) < size(sliceMatrix3, 2), 'Higher overlap should produce more time slices');
        end

        function testInvalidOverlap(tc)
            % Test overlap >= slice length
            xTest = randn(1000, 1);

            tc.verifyError(@() slicesignal(xTest, 256, 256, tc.fs), ...
                'sliceSignal:invalidOverlap', 'Should error when overlap >= slice length');

            tc.verifyError(@() slicesignal(xTest, 256, 300, tc.fs), ...
                'sliceSignal:invalidOverlap', 'Should error when overlap > slice length');
        end

        function testSignalTooShort(tc)
            xShort = randn(100, 1);

            tc.verifyError(@() slicesignal(xShort, 256, 128, tc.fs), ...
                'sliceSignal:signalTooShort', 'Should error when signal is too short');
        end

        function testEmptyInput(tc)
            xEmpty = [];

            tc.verifyError(@() slicesignal(xEmpty, 256, 128, tc.fs), ...
                'MATLAB:InputParser:ArgumentFailedValidation', 'Should error with empty input');
        end

        function testInvalidParameters(tc)
            xTest = randn(1000, 1);

            tc.verifyError(@() slicesignal(xTest, 0, 128, tc.fs), ...
                'MATLAB:InputParser:ArgumentFailedValidation', 'Should error with zero slice length');

            tc.verifyError(@() slicesignal(xTest, -256, 128, tc.fs), ...
                'MATLAB:InputParser:ArgumentFailedValidation', 'Should error with negative slice length');

            tc.verifyError(@() slicesignal(xTest, 256, -128, tc.fs), ...
                'MATLAB:InputParser:ArgumentFailedValidation', 'Should error with negative overlap');

            tc.verifyError(@() slicesignal(xTest, 256, 128, 0), ...
                'MATLAB:InputParser:ArgumentFailedValidation', 'Should error with zero sampling rate');

            tc.verifyError(@() slicesignal(xTest, 256.5, 128, tc.fs), ...
                'MATLAB:InputParser:ArgumentFailedValidation', 'Should error with non-integer slice length');

            tc.verifyError(@() slicesignal(xTest, 256, 128.5, tc.fs), ...
                'MATLAB:InputParser:ArgumentFailedValidation', 'Should error with non-integer overlap');
        end

        function testTimeAxisConsistency(tc)
            [sliced, tcenter] = slicesignal(tc.x, 256, 128, tc.fs);

            % Check time axis properties
            tc.verifyTrue(tcenter(1) > 0, 'First time point should be positive');
            tc.verifyTrue(tcenter(end) < length(tc.x)/tc.fs, 'Last time point should be within signal duration');
            tc.verifyEqual(length(tcenter), size(sliced, 2), 'Time vector length should match number of slices');
        end

        function testMissingFsForTcenter(tc)
            function testFunc()
                [~, tcenter] = slicesignal(tc.x, 256, 128); %#ok<ASGLU>
            end
            tc.verifyError(@testFunc, ...
                'slicesignal:missingFs', 'Should error when requesting tcenter without fs');
        end

        function testUselastParameter(tc)
            xShort = randn(500, 1);

            % Without uselast (default)
            [sliced1, ~] = slicesignal(xShort, 256, 128, tc.fs);

            % With uselast = true
            [sliced2, ~] = slicesignal(xShort, 256, 128, tc.fs, true);

            % Should have more slices with uselast
            tc.verifyTrue(size(sliced2, 2) >= size(sliced1, 2), 'Uselast should produce more or equal slices');

            % Last slice should contain NaNs when uselast is true
            lastSlice = sliced2(:, end);
            tc.verifyTrue(any(isnan(lastSlice)), 'Last slice should contain NaN padding when uselast is true');
        end

        function testUselastWithShortSignal(tc)
            xVeryShort = randn(200, 1);

            % Should error without uselast
            tc.verifyError(@() slicesignal(xVeryShort, 256, 128, tc.fs), ...
                'sliceSignal:signalTooShort', 'Should error with short signal when uselast is false');

            % Should work with uselast = true
            [sliced, ~] = slicesignal(xVeryShort, 256, 128, tc.fs, true);
            tc.verifyEqual(size(sliced, 1), 256, 'Should return proper slice length');
            tc.verifyTrue(any(isnan(sliced(:))), 'Should contain NaN padding');
        end

    end

end
