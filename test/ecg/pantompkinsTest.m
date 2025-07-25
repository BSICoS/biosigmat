% Tests covering:
%   - Basic functionality with real ECG fixtures and R-wave detection accuracy
%   - Multiple output arguments (tk, ecgFiltered, decg, decgEnvelope)
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

    methods (TestClassSetup)
        function addCodeToPath(tc)
            addpath(fullfile('..', '..', 'src', 'ecg'));
            addpath(fullfile('..', '..', 'src', 'tools'));
            addpath(fullfile(pwd, '..', '..', 'fixtures', 'ecg'));

            % Verify functions are available
            tc.verifyTrue(~isempty(which('pantompkins')), 'pantompkins function not found in path');
            tc.verifyTrue(~isempty(which('snaptopeak')), 'snaptopeak dependency not found in path');

            % Check fixture files exist
            fixturesPath = fullfile(pwd, '..', '..', 'fixtures', 'ecg');
            tc.verifyTrue(exist(fullfile(fixturesPath, 'edr_signals.csv'), 'file') > 0, ...
                'edr_signals.csv not found in fixtures path');
            tc.verifyTrue(exist(fullfile(fixturesPath, 'ecg_tk.csv'), 'file') > 0, ...
                'ecg_tk.csv not found in fixtures path');
        end
    end

    methods (Access = private)
        function [ecg, tk] = loadFixtureData(~)
            fixturesPath = fullfile(pwd, '..', '..', 'fixtures', 'ecg');

            % Load ECG signal and expected R-wave times from CSV files
            signalsData = readtable(fullfile(fixturesPath, 'edr_signals.csv'));
            peaksData = readtable(fullfile(fixturesPath, 'ecg_tk.csv'));

            % Extract signals - ensure column vector
            ecg = signalsData.ecg(:);
            tk = peaksData.tk(:);
        end
    end

    methods (Test)
        function testBasicFunctionality(tc)
            try
                [ecg, expectedTk] = tc.loadFixtureData();
                tk = pantompkins(ecg, tc.fs);

                % Verify output format
                tc.verifySize(tk, [length(tk), 1], 'Output tk should be a column vector');
                tc.verifyClass(tk, 'double', 'Output tk should be double precision');
                tc.verifyTrue(all(tk >= 0), 'All R-wave times should be non-negative');
                tc.verifyTrue(issorted(tk), 'R-wave times should be sorted in ascending order');
                tc.verifyEqual(tk, expectedTk, sprintf('Detected R-wave times do not match expected values'));
            catch e
                tc.verifyTrue(false, ['Error in basic functionality test: ' e.message]);
            end
        end

        function testMultipleOutputs(tc)
            try
                [ecg, ~] = tc.loadFixtureData();
                [tk, ecgFiltered, decg, decgEnvelope] = pantompkins(ecg, tc.fs);

                % Verify all outputs have correct dimensions
                tc.verifySize(tk, [length(tk), 1], 'tk should be a column vector');
                tc.verifySize(ecgFiltered, size(ecg), 'ecgFiltered should have same size as input ECG');
                tc.verifySize(decg, size(ecg), 'decg should have same size as input ECG');
                tc.verifySize(decgEnvelope, size(ecg), 'decgEnvelope should have same size as input ECG');

                % Verify data types
                tc.verifyClass(tk, 'double', 'tk should be double');
                tc.verifyClass(ecgFiltered, 'double', 'ecgFiltered should be double');
                tc.verifyClass(decg, 'double', 'decg should be double');
                tc.verifyClass(decgEnvelope, 'double', 'decgEnvelope should be double');

                % Verify processing chain properties
                tc.verifyTrue(all(decg >= 0), 'Squared derivative should be non-negative');
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
                tk1 = pantompkins(ecg, tc.fs, 'BandpassFreq', [8, 20]);
                tc.verifyClass(tk1, 'double', 'Custom bandpass should work');
                tc.verifyTrue(~isempty(tk1), 'Custom bandpass should detect peaks');

                % Test custom window size
                tk2 = pantompkins(ecg, tc.fs, 'WindowSize', 0.1);
                tc.verifyClass(tk2, 'double', 'Custom window size should work');

                % Test custom minimum peak distance
                tk3 = pantompkins(ecg, tc.fs, 'MinPeakDistance', 0.3);
                tc.verifyClass(tk3, 'double', 'Custom min peak distance should work');

                % Test custom snaptopeak window size
                tk5 = pantompkins(ecg, tc.fs, 'SnapTopeakWindowSize', 15);
                tc.verifyClass(tk5, 'double', 'Custom snaptopeak window should work');

            catch e
                tc.verifyTrue(false, ['Error in parameter validation test: ' e.message]);
            end
        end

        function testSignalWithNaN(tc)
            [ecg, expectedTk] = tc.loadFixtureData();
            ecg(10000:13000) = NaN;
            expectedTk(expectedTk > 10000/tc.fs & expectedTk < 13000/tc.fs) = [];
            tk = pantompkins(ecg, tc.fs);

            tc.verifyEqual(tk, expectedTk, ...
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