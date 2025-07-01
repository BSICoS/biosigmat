% Tests covering:
%   - Input validation for common real-world error cases
%   - Basic functionality with ECG signal from fixtures
%   - Special signal cases (all NaN, empty inputs)

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
        function testInputValidation(tc)
            ecg = tc.loadFixtureData();

            % Test insufficient arguments
            tc.verifyError(@() nanpwelch(), 'MATLAB:narginchk:notEnoughInputs');
            tc.verifyError(@() nanpwelch(ecg, 256, 128, 512), 'MATLAB:narginchk:notEnoughInputs');

            % Test too many arguments
            tc.verifyError(@() nanpwelch(ecg, 256, 128, 512, tc.fs, 50, 'extra'), ...
                'MATLAB:TooManyInputs');

            % Test empty input signal
            tc.verifyError(@() nanpwelch([], 256, 128, 512, tc.fs, []), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            % Test non-numeric input signal
            tc.verifyError(@() nanpwelch('invalid', 256, 128, 512, tc.fs, []), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            % Test matrix input (non-vector)
            matrix = rand(10, 10);
            tc.verifyError(@() nanpwelch(matrix, 256, 128, 512, tc.fs, []), ...
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
        end

        function testAllNaNSignal(tc)
            % Test behavior with signal containing only NaN values
            allNanSignal = NaN(1000, 1);

            [pxx, f] = nanpwelch(allNanSignal, 256, 128, 512, tc.fs, []);
            tc.verifyClass(pxx, 'double', 'Output pxx should be double');
            tc.verifyClass(f, 'double', 'Output f should be double');
            tc.verifyTrue(all(isnan(pxx)), 'All NaN signal should produce NaN output');
        end

        function testBasicFunctionality(tc)
            % Test basic functionality with ECG signal from fixtures
            ecg = tc.loadFixtureData();

            % Test with both output arguments
            [pxx, f] = nanpwelch(ecg, 256, 128, 512, tc.fs, []);
            tc.verifyClass(pxx, 'double', 'Output pxx should be double');
            tc.verifyClass(f, 'double', 'Output f should be double');
            tc.verifySize(pxx, [257, 1], 'Output pxx should be column vector of correct size');
            tc.verifySize(f, [257, 1], 'Output f should be column vector of correct size');
            tc.verifyTrue(all(pxx >= 0), 'Power spectral density should be non-negative');
            tc.verifyTrue(all(f >= 0), 'Frequency vector should be non-negative');

            % Test with single output argument
            pxx_single = nanpwelch(ecg, 256, 128, 512, tc.fs, []);
            tc.verifyClass(pxx_single, 'double', 'Single output pxx should be double');
            tc.verifySize(pxx_single, [257, 1], 'Single output pxx should be column vector of correct size');

            % Test with different window types
            window = hamming(256);
            tc.verifyWarningFree(@() nanpwelch(ecg, window, 128, 512, tc.fs, []), ...
                'Function should accept vector window');

            % Test with optional minDistance parameter
            tc.verifyWarningFree(@() nanpwelch(ecg, 256, 128, 512, tc.fs, 50), ...
                'Function should accept minDistance parameter');
            tc.verifyWarningFree(@() nanpwelch(ecg, 256, 128, 512, tc.fs, []), ...
                'Function should accept empty minDistance parameter');
        end
    end

end
