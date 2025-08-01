% Tests covering:
%   - Basic functionality with ECG signal from fixtures
%   - Input validation for common real-world error cases
%   - Special signal cases (all NaN, empty inputs)
%   - Gap interpolation functionality with maxgap parameter

classdef nanpwelchTest < matlab.unittest.TestCase

    properties
        fs = 256;
    end

    methods (TestClassSetup)
        function addCodeToPath(tc)
            addpath(fullfile('..', '..', 'src', 'tools'));
            addpath(fullfile(pwd, '..', '..', 'fixtures', 'ecg'));

            % Verify functions are available
            tc.verifyTrue(~isempty(which('nanpwelch')), 'nanpwelch function not found in path');

            % Check fixture files exist
            fixturesPath = fullfile(pwd, '..', '..', 'fixtures', 'ecg');
            tc.verifyTrue(exist(fullfile(fixturesPath, 'edr_signals.csv'), 'file') > 0, ...
                'edr_signals.csv not found in fixtures path');
        end
    end

    methods (Access = private)
        function ecg = loadFixtureData(~)
            fixturesPath = fullfile(pwd, '..', '..', 'fixtures', 'ecg');
            signalsData = readtable(fullfile(fixturesPath, 'edr_signals.csv'));
            ecg = signalsData.ecg(:);
        end
    end

    methods (Test)
        function testBasicFunctionality(tc)
            ecg = tc.loadFixtureData();

            % Test with both output arguments
            [pxx, f] = nanpwelch(ecg, 256, 128, 512, tc.fs, []);
            tc.verifyClass(pxx, 'double', 'Output pxx should be double');
            tc.verifyClass(f, 'double', 'Output f should be double');
            tc.verifySize(pxx, [257, 1], 'Output pxx should be column vector of correct size');
            tc.verifySize(f, [257, 1], 'Output f should be column vector of correct size');
            tc.verifyTrue(all(pxx >= 0), 'Power spectral density should be non-negative');
            tc.verifyTrue(all(f >= 0), 'Frequency vector should be non-negative');

            % Test with different window types
            window = hamming(256);
            tc.verifyWarningFree(@() nanpwelch(ecg, window, 128, 512, tc.fs, []), ...
                'Function should accept vector window');

            % Test with optional maxgap parameter
            tc.verifyWarningFree(@() nanpwelch(ecg, 256, 128, 512, tc.fs, 50), ...
                'Function should accept maxgap parameter');
            tc.verifyWarningFree(@() nanpwelch(ecg, 256, 128, 512, tc.fs, []), ...
                'Function should accept empty maxgap parameter');
        end

        function testInputValidation(tc)
            ecg = tc.loadFixtureData();

            % Test insufficient arguments
            tc.verifyError(@() nanpwelch(), 'MATLAB:narginchk:notEnoughInputs');
            tc.verifyError(@() nanpwelch(ecg, 256, 128, 512), 'MATLAB:narginchk:notEnoughInputs');

            % Test too many arguments
            tc.verifyError(@() nanpwelch(ecg, 256, 128, 512, tc.fs, 50, 'extra'), ...
                'MATLAB:narginchk:tooManyInputs');

            % Test empty input signal
            tc.verifyError(@() nanpwelch([], 256, 128, 512, tc.fs, []), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            % Test non-numeric input signal
            tc.verifyError(@() nanpwelch('invalid', 256, 128, 512, tc.fs, []), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            % Test empty window
            tc.verifyError(@() nanpwelch(ecg, [], 128, 512, tc.fs, []), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            % Test negative values where they shouldn't be allowed
            tc.verifyError(@() nanpwelch(ecg, 256, -10, 512, tc.fs, []), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
            tc.verifyError(@() nanpwelch(ecg, 256, 128, 0, tc.fs, []), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
            tc.verifyError(@() nanpwelch(ecg, 256, 128, 512, 0, []), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
            tc.verifyError(@() nanpwelch(ecg, 256, 128, 512, tc.fs, -10), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            % Test window larger than signal
            shortSignal = ecg(1:100);
            tc.verifyError(@() nanpwelch(shortSignal, 256, 128, 512, tc.fs, []), ...
                'nanpwelch:windowTooLarge');
        end

        function testShortSignalWarnings(tc)
            ecg = tc.loadFixtureData();

            % Test signal that becomes too short after trimming NaN
            shortSignalWithNaN = [NaN(50, 1); ecg(1:50); NaN(100, 1)];
            tc.verifyWarning(@() nanpwelch(shortSignalWithNaN, 128, 64, 256, tc.fs, []), ...
                'nanpwelch:signalTooShort');

            % Test signal with segments all too short
            segmentedSignal = ecg(1:300);
            segmentedSignal(50:200) = NaN;  % Large gap creating short segments
            tc.verifyWarning(@() nanpwelch(segmentedSignal, 128, 64, 256, tc.fs, 10), ...
                'nanpwelch:noValidSegments');
        end

        function testAllNaNSignal(tc)
            allNanSignal = NaN(1000, 1);

            [pxx, f] = nanpwelch(allNanSignal, 256, 128, 512, tc.fs, []);
            tc.verifyClass(pxx, 'double', 'Output pxx should be double');
            tc.verifyClass(f, 'double', 'Output f should be double');
            tc.verifyTrue(all(isnan(pxx)), 'All NaN signal should produce NaN output');
        end

        function testSegmentCounting(tc)
            ecg = tc.loadFixtureData();
            testSignal = ecg(1:1000);

            % Test 1: Signal without NaN
            [pxx1, ~, segments1] = nanpwelch(testSignal, 128, 64, 256, tc.fs, []);
            tc.verifyEqual(size(segments1, 2), 14, 'Should have 14 segments');
            tc.verifyEqual(size(segments1, 1), length(pxx1), 'Segment PSD should match output length');

            % Test 2: Signal with one large gap in middle (should have 12 segments)
            signalLargeGap = testSignal;
            signalLargeGap(400:450) = NaN;  % 51-sample gap
            [~, ~, segments2] = nanpwelch(signalLargeGap, 128, 64, 256, tc.fs, 10);
            tc.verifyEqual(size(segments2, 2), 12, 'Large gap should create 12 segments');

            % Test 4: Signal with multiple small gaps (should have 14 segment, all interpolated)
            signalSmallGaps = testSignal;
            signalSmallGaps(100:102) = NaN;  % 3-sample gap
            signalSmallGaps(300:305) = NaN;  % 6-sample gap
            signalSmallGaps(500:508) = NaN;  % 9-sample gap
            [~, ~, segments4] = nanpwelch(signalSmallGaps, 128, 64, 256, tc.fs, 10);
            tc.verifyEqual(size(segments4, 2), 14, 'Multiple small gaps should be interpolated into 14 segments');

            % Test 5: Signal with multiple large gaps (should have 10 segments)
            signalMultipleLargeGaps = testSignal;
            signalMultipleLargeGaps(200:250) = NaN;  % 51-sample gap
            signalMultipleLargeGaps(600:670) = NaN;  % 71-sample gap
            [~, ~, segments5] = nanpwelch(signalMultipleLargeGaps, 128, 64, 256, tc.fs, 10);
            tc.verifyEqual(size(segments5, 2), 10, 'Multiple large gaps should create 10 segments');

            % Test 6: All NaN signal (should have 0 segments)
            allNanSignal = NaN(1000, 1);
            [~, ~, segments6] = nanpwelch(allNanSignal, 128, 64, 256, tc.fs, []);
            tc.verifyEmpty(segments6, 'All NaN signal should have empty segments matrix');
        end

        function testGapInterpolation(tc)
            ecg = tc.loadFixtureData();
            testSignal = ecg(1:1000);

            % Create signal with small gaps that should be interpolated
            signalWithSmallGaps = testSignal;
            signalWithSmallGaps(100:102) = NaN;  % 3-sample gap
            signalWithSmallGaps(200:204) = NaN;  % 5-sample gap

            % Test with maxgap = 10 (should interpolate both gaps)
            [pxx1, ~] = nanpwelch(signalWithSmallGaps, 256, 128, 512, tc.fs, 10);
            tc.verifyClass(pxx1, 'double', 'Output pxx should be double');
            tc.verifyTrue(all(~isnan(pxx1)), 'Small gaps should be interpolated');

            % Test with maxgap = 2 (should not interpolate 5-sample gap)
            [pxx2, ~] = nanpwelch(signalWithSmallGaps, 256, 128, 512, tc.fs, 2);
            tc.verifyClass(pxx2, 'double', 'Output pxx should be double');

            % Create signal with large gap that should not be interpolated
            signalWithLargeGap = testSignal;
            signalWithLargeGap(400:450) = NaN;  % 51-sample gap

            % Test with maxgap = 10 (should not interpolate large gap)
            [pxx3, ~] = nanpwelch(signalWithLargeGap, 256, 128, 512, tc.fs, 10);
            tc.verifyClass(pxx3, 'double', 'Output pxx should be double');
            tc.verifyTrue(all(~isnan(pxx3)), 'Should average across valid segments');
        end

        function testMatrixInputs(tc)
            ecg = tc.loadFixtureData();

            % Create matrix with multiple signals
            ecg2 = ecg + 0.1 * randn(size(ecg));
            ecg3 = ecg + 0.2 * randn(size(ecg));
            signalMatrix = [ecg, ecg2, ecg3];

            % Test basic matrix functionality
            [pxx, f, pxxSegments] = nanpwelch(signalMatrix, 256, 128, 512, tc.fs, []);
            tc.verifyClass(pxx, 'double', 'Output pxx should be double');
            tc.verifyClass(f, 'double', 'Output f should be double');
            tc.verifySize(pxx, [257, 3], 'Output pxx should be matrix with 3 columns');
            tc.verifySize(f, [257, 1], 'Output f should be column vector of correct size');
            tc.verifyTrue(all(pxx(:) >= 0), 'Power spectral density should be non-negative');
            tc.verifyTrue(all(f >= 0), 'Frequency vector should be non-negative');
            tc.verifyClass(pxxSegments, 'cell', 'Output pxxSegments should be cell array for matrix input');
            tc.verifySize(pxxSegments, [3, 1], 'pxxSegments should be 3x1 cell array');
            tc.verifyTrue(all(cellfun(@(x) isa(x, 'double'), pxxSegments)), 'Each cell should contain double array');

            % Test with NaN values in matrix
            matrixWithNaN = signalMatrix;
            matrixWithNaN(100:200, 1) = NaN;  % Add NaN to first column
            matrixWithNaN(300:400, 2) = NaN;  % Add NaN to second column

            [pxxNaN, fNaN] = nanpwelch(matrixWithNaN, 256, 128, 512, tc.fs, 50);
            tc.verifySize(pxxNaN, [257, 3], 'Matrix with NaN should produce matrix output');
            tc.verifySize(fNaN, [257, 1], 'Frequency output should be column vector');
            tc.verifyTrue(all(pxxNaN(:) >= 0), 'Power spectral density with NaN should be non-negative');
        end
    end

end
