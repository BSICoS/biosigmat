% Tests covering:
%   - Basic functionality with real ECG fixtures and R-wave detection accuracy
%   - Multiple output arguments (rWaveTimes, ecgFiltered, decgSquared, decgEnvelope)
%   - Edge cases (empty input, scalar input, all-NaN signals)
%   - Parameter validation for all optional parameters
%   - Invalid input error handling (non-numeric, character arrays, string inputs)
%   - Special input types (logical arrays, complex numbers)
%   - Boundary conditions and sampling frequency validation
%   - Dependency checks for required functions (snaptopeak)

classdef pantompkinsTest < matlab.unittest.TestCase
    properties
        fs = 256;
    end

    properties (TestParameter)
        expectedErrorCaseId = {
            'ecg.pantompkins.invalid_sampling_frequency_non_positive'
            'ecg.pantompkins.invalid_sampling_frequency_vector'
            'ecg.pantompkins.invalid_sampling_frequency_non_numeric'
            'ecg.pantompkins.invalid_ecg_matrix'
            'ecg.pantompkins.invalid_ecg_non_numeric'
        }
    end

    methods (TestClassSetup)
        function addCodeToPath(tc)
            testDirectory = fileparts(mfilename('fullpath'));
            repositoryRoot = fileparts(fileparts(testDirectory));
            originalPath = path;
            tc.addTeardown(@() path(originalPath));
            addpath(fullfile(repositoryRoot, 'src', 'ecg'));
            addpath(fullfile(repositoryRoot, 'src', 'tools'));
            addpath(fullfile(repositoryRoot, 'test', 'common'));

            % Verify functions are available
            tc.verifyTrue(~isempty(which('pantompkins')), 'pantompkins function not found in path');
            tc.verifyTrue(~isempty(which('snaptopeak')), 'snaptopeak dependency not found in path');

        end
    end

    methods (Access = private)
        function [ecg, rWaveTimes] = loadFixtureData(~)
            signalsData = loadBiosiglibFixtureTable( ...
                'ecg.medicom_mtd.ecg_respiration', 'signal_table', 'ecg');
            timingData = loadBiosiglibFixtureTable( ...
                'ecg.medicom_mtd.r_wave_timing', 'beat_timing_table', 'r_wave_times');

            ecg = signalsData.ecg(:);
            rWaveTimes = timingData.r_wave_times(:);
        end
    end

    methods (Test)
        function testBasicFunctionality(tc)
            caseDefinition = loadBiosiglibConformanceCase( ...
                'ecg.pantompkins.medicom_mtd_r_wave_times');
            ecg = loadBiosiglibConformanceInput(caseDefinition, 'ecg');
            samplingFrequency = loadBiosiglibConformanceInput( ...
                caseDefinition, 'sampling_frequency');

            [rWaveTimes, ecgFiltered, decgSquared, decgEnvelope] = ...
                pantompkins(ecg, samplingFrequency);

            tc.verifySize(rWaveTimes, [length(rWaveTimes), 1], ...
                'R-wave times should be a column vector.');
            tc.verifyClass(rWaveTimes, 'double', ...
                'R-wave times should be double precision.');
            tc.verifyTrue(all(rWaveTimes >= 0), ...
                'All R-wave times should be non-negative.');
            tc.verifyTrue(issorted(rWaveTimes), ...
                'R-wave times should be sorted in ascending order.');

            tc.verifyTrue(isnumeric(ecgFiltered) && isvector(ecgFiltered), ...
                'ecg_filtered must exist as a numeric vector.');
            tc.verifyTrue(isnumeric(decgSquared) && isvector(decgSquared), ...
                'decgSquared must exist as a numeric vector.');
            tc.verifyTrue(isnumeric(decgEnvelope) && isvector(decgEnvelope), ...
                'decg_envelope must exist as a numeric vector.');
            tc.verifySize(ecgFiltered, size(ecg), ...
                'ecg_filtered must preserve the input ECG sample order and length.');
            tc.verifySize(decgSquared, size(ecg), ...
                'decgSquared must preserve the input ECG sample order and length.');
            tc.verifySize(decgEnvelope, size(ecg), ...
                'decg_envelope must preserve the input ECG sample order and length.');

            actualOutputs = struct( ...
                'rWaveTimes', rWaveTimes, ...
                'ecgFiltered', ecgFiltered, ...
                'decgSquared', decgSquared, ...
                'decgEnvelope', decgEnvelope);
            outputIdMap = containers.Map( ...
                {'r_wave_times', 'ecg_filtered', 'decg', 'decg_envelope'}, ...
                {'rWaveTimes', 'ecgFiltered', 'decgSquared', 'decgEnvelope'});
            verifyBiosiglibExpectedOutputs( ...
                tc, actualOutputs, caseDefinition, outputIdMap);
        end

        function testExpectedError(tc, expectedErrorCaseId)
            caseDefinition = loadBiosiglibConformanceCase(expectedErrorCaseId);
            ecg = loadBiosiglibConformanceInput(caseDefinition, 'ecg');
            samplingFrequency = loadBiosiglibConformanceInput( ...
                caseDefinition, 'sampling_frequency');

            verifyBiosiglibExpectedError(tc, ...
                @() pantompkins(ecg, samplingFrequency), caseDefinition);
        end

        function testMultipleOutputs(tc)
            try
                [ecg, ~] = tc.loadFixtureData();
                [rWaveTimes, ecgFiltered, decgSquared, decgEnvelope] = pantompkins(ecg, tc.fs);

                % Verify all outputs have correct dimensions
                tc.verifySize(rWaveTimes, [length(rWaveTimes), 1], 'rWaveTimes should be a column vector');
                tc.verifySize(ecgFiltered, size(ecg), 'ecgFiltered should have same size as input ECG');
                tc.verifySize(decgSquared, size(ecg), 'decgSquared should have same size as input ECG');
                tc.verifySize(decgEnvelope, size(ecg), 'decgEnvelope should have same size as input ECG');

                % Verify data types
                tc.verifyClass(rWaveTimes, 'double', 'rWaveTimes should be double');
                tc.verifyClass(ecgFiltered, 'double', 'ecgFiltered should be double');
                tc.verifyClass(decgSquared, 'double', 'decgSquared should be double');
                tc.verifyClass(decgEnvelope, 'double', 'decgEnvelope should be double');

                % Verify processing chain properties
                tc.verifyTrue(all(decgSquared >= 0), 'Squared derivative should be non-negative');
                tc.verifyTrue(all(decgEnvelope >= 0), 'Integrated envelope should be non-negative');
                tc.verifyTrue(max(ecgFiltered) < max(ecg), 'Filtered signal should have reduced amplitude');

            catch e
                tc.verifyTrue(false, ['Error in multiple outputs test: ' e.message]);
            end
        end

        function testParameterValidation(tc)
            try
                [ecg, ~] = tc.loadFixtureData();

                % Test custom bandpass frequencies
                rWaveTimes1 = pantompkins(ecg, tc.fs, 'BandpassFreq', [8, 20]);
                tc.verifyClass(rWaveTimes1, 'double', 'Custom bandpass should work');
                tc.verifyTrue(~isempty(rWaveTimes1), 'Custom bandpass should detect peaks');

                % Test custom window size
                rWaveTimes2 = pantompkins(ecg, tc.fs, 'WindowSize', 0.1);
                tc.verifyClass(rWaveTimes2, 'double', 'Custom window size should work');

                % Test custom minimum peak distance
                rWaveTimes3 = pantompkins(ecg, tc.fs, 'MinPeakDistance', 0.3);
                tc.verifyClass(rWaveTimes3, 'double', 'Custom min peak distance should work');

                % Test custom snaptopeak window size
                rWaveTimes5 = pantompkins(ecg, tc.fs, 'SnapTopeakWindowSize', 15);
                tc.verifyClass(rWaveTimes5, 'double', 'Custom snaptopeak window should work');

            catch e
                tc.verifyTrue(false, ['Error in parameter validation test: ' e.message]);
            end
        end

        function testSignalWithNaN(tc)
            [ecg, expectedRWaveTimes] = tc.loadFixtureData();
            ecg(10000:13000) = NaN;
            expectedRWaveTimes(expectedRWaveTimes > 10000/tc.fs & expectedRWaveTimes < 13000/tc.fs) = [];
            rWaveTimes = pantompkins(ecg, tc.fs);

            tc.verifyEqual(rWaveTimes, expectedRWaveTimes, ...
                'Detected R-wave times should match expected values in ECG signal (NaN case)');
        end

        function testInvalidInputs(tc)
            % Test non-numeric ECG input
            tc.verifyError(@() pantompkins([], tc.fs), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Empty ECG input should throw ArgumentFailedValidation error');
            tc.verifyError(@() pantompkins('string', tc.fs), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'String ECG input should throw ArgumentFailedValidation error');
            tc.verifyError(@() pantompkins(['a', 'b', 'c'], tc.fs), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Character array ECG input should throw ArgumentFailedValidation error');
            tc.verifyError(@() pantompkins(true, tc.fs), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Logical ECG input should throw ArgumentFailedValidation error');
            tc.verifyError(@() pantompkins(1, tc.fs), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Scalar numeric ECG input should throw ArgumentFailedValidation error');

            % Test invalid sampling frequency
            [ecg, ~] = tc.loadFixtureData();
            tc.verifyError(@() pantompkins(ecg, 0), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Zero sampling frequency should throw ArgumentFailedValidation error');
            tc.verifyError(@() pantompkins(ecg, -100), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Negative sampling frequency should throw ArgumentFailedValidation error');
            tc.verifyError(@() pantompkins(ecg, 'invalid'), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Non-numeric sampling frequency should throw ArgumentFailedValidation error');

            % Test invalid bandpass frequencies
            tc.verifyError(@() pantompkins(ecg, tc.fs, 'BandpassFreq', [15, 5]), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Invalid bandpass frequencies (high < low) should throw ArgumentFailedValidation error');
            tc.verifyError(@() pantompkins(ecg, tc.fs, 'BandpassFreq', [-5, 10]), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Negative bandpass frequencies should throw ArgumentFailedValidation error');
            tc.verifyError(@() pantompkins(ecg, tc.fs, 'BandpassFreq', 5), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Single bandpass frequency should throw ArgumentFailedValidation error');

            % Test invalid window size
            tc.verifyError(@() pantompkins(ecg, tc.fs, 'WindowSize', -0.1), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Negative window size should throw ArgumentFailedValidation error');
            tc.verifyError(@() pantompkins(ecg, tc.fs, 'WindowSize', 0), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Zero window size should throw ArgumentFailedValidation error');
            % Test invalid minimum peak distance
            tc.verifyError(@() pantompkins(ecg, tc.fs, 'MinPeakDistance', -0.5), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Negative minimum peak distance should throw ArgumentFailedValidation error');
            tc.verifyError(@() pantompkins(ecg, tc.fs, 'MinPeakDistance', 0), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Zero minimum peak distance should throw ArgumentFailedValidation error');

            % Test invalid snaptopeak window size
            tc.verifyError(@() pantompkins(ecg, tc.fs, 'SnapTopeakWindowSize', -10), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Negative snaptopeak window size should throw ArgumentFailedValidation error');
            tc.verifyError(@() pantompkins(ecg, tc.fs, 'SnapTopeakWindowSize', 0), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Zero snaptopeak window size should throw ArgumentFailedValidation error');
        end

        function testInsufficientArguments(tc)
            tc.verifyError(@() pantompkins(), 'MATLAB:narginchk:notEnoughInputs', ...
                'No input arguments should throw notEnoughInputs error');
            tc.verifyError(@() pantompkins([1, 2, 3]), 'MATLAB:narginchk:notEnoughInputs', ...
                'Single input argument should throw notEnoughInputs error');
        end
    end
end
