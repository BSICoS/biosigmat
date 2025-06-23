% Tests covering:
%   - Basic functionality with real ECG data from fixtures
%   - Peak refinement accuracy with randomly perturbed detections
%   - Edge case handling (empty inputs)
%   - Parameter validation (window size)
%   - Input validation (invalid positions, character inputs)

classdef snaptopeakTest < matlab.unittest.TestCase
    properties
        fs = 256;
    end

    methods (TestClassSetup)
        function addCodeToPath(tc)
            addpath(fullfile('..', '..', 'src', 'ecg'));
            addpath(fullfile('..', '..', 'src', 'tools'));
            addpath(fullfile(pwd, '..', '..', 'fixtures', 'ecg'));

            % Verify functions are available
            tc.verifyTrue(~isempty(which('snaptopeak')), 'snaptopeak function not found in path');

            % Check fixture files exist
            fixturesPath = fullfile(pwd, '..', '..', 'fixtures', 'ecg');
            tc.verifyTrue(exist(fullfile(fixturesPath, 'edr_signals.csv'), 'file') > 0, ...
                'edr_signals.csv not found in fixtures path');
            tc.verifyTrue(exist(fullfile(fixturesPath, 'ecg_tk.csv'), 'file') > 0, ...
                'ecg_tk.csv not found in fixtures path');
        end
    end

    methods (Access = private)
        function fixturesPath = getFixturesPath(~)
            fixturesPath = fullfile(pwd, '..', '..', 'fixtures', 'ecg');
        end

        function [ecg, tkSamples] = loadFixtureData(tc)
            fixturesPath = tc.getFixturesPath();

            % Load the signals and R-peaks from CSV files
            signalsData = readtable(fullfile(fixturesPath, 'edr_signals.csv'));
            peaksData = readtable(fullfile(fixturesPath, 'ecg_tk.csv'));

            ecg = signalsData.ecg(:);

            % Convert time-based detections to sample indices
            tkSamples = peaksData.tkSamples(:);
        end
    end

    methods (Test)
        function testPeakRefinementAccuracy(tc)
            [ecg, originalDetections] = tc.loadFixtureData();

            % Add random perturbations to original detections (±5 samples)
            rng(42);
            perturbations = randi([-5, 5], size(originalDetections));
            perturbedDetections = originalDetections + perturbations;

            perturbedDetections = max(1, min(length(ecg), perturbedDetections));
            refinedDetections = snaptopeak(ecg, perturbedDetections);

            % Verify that refined detections match with the original detections
            tc.verifyEqual(refinedDetections, originalDetections, ...
                'All refined detections must match with original detections');
        end

        function testEmptyInputs(tc)
            % Test with empty ECG signal
            tc.verifyError(@() snaptopeak([], 1), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Should error for empty ECG input');

            % Test with empty detections
            [ecg, ~] = tc.loadFixtureData();
            actual = snaptopeak(ecg, []);
            tc.verifyEmpty(actual, 'Empty detections input handling failed');
        end

        function testCustomWindowSize(tc)
            [ecg, tkSamples] = tc.loadFixtureData();

            refined1 = snaptopeak(ecg, tkSamples, 'WindowSize', 5);
            tc.verifySize(refined1, size(tkSamples), 'Small window output size should match input');

            % Test with large window
            refined2 = snaptopeak(ecg, tkSamples, 'WindowSize', 50);
            tc.verifySize(refined2, size(tkSamples), 'Large window output size should match input');

            % Both should produce valid results
            tc.verifyTrue(all(refined1 >= 1 & refined1 <= length(ecg)), ...
                'Small window detections should be within bounds');
            tc.verifyTrue(all(refined2 >= 1 & refined2 <= length(ecg)), ...
                'Large window detections should be within bounds');
        end

        function testInputValidation(tc)
            [ecg, ~] = tc.loadFixtureData();

            % Character ECG input
            tc.verifyError(@() snaptopeak('invalid', [1, 2]), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Should error for character ECG input');

            % Character detections input
            tc.verifyError(@() snaptopeak(ecg, 'invalid'), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Should error for character detections input');

            % Invalid window size
            tc.verifyError(@() snaptopeak(ecg, 100, 'WindowSize', -1), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Should error for negative window size');
        end

    end

end
