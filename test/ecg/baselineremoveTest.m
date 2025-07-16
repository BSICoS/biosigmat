% Tests covering:
%   - Basic functionality with real ECG data from fixtures
%   - Error handling (invalid inputs, out-of-range fiducial points)
%   - Different window size effect

classdef baselineremoveTest < matlab.unittest.TestCase
    properties
        ecg
        rPeakSamples
        fs
    end


    methods (TestClassSetup)
        function addCodeToPath(~)
            addpath(fullfile('..', '..', 'src', 'ecg'));
            addpath(fullfile('..', '..', 'src', 'tools'));
            addpath(fullfile('..', '..', 'fixtures', 'ecg'));
        end
    end

    methods (TestMethodSetup)
        function loadFixtures(tc)
            edrData = readmatrix('../../fixtures/ecg/edr_signals.csv');
            tc.ecg = edrData(:, 2);

            tkData = readmatrix('../../fixtures/ecg/ecg_tk.csv');
            tc.rPeakSamples = tkData(:, 2);

            tc.fs = 256;
        end
    end

    methods (Test)
        function testBasicFunctionality(tc)
            prInterval = round(0.08 * tc.fs);
            fiducialPoints = tc.rPeakSamples - prInterval;
            fiducialPoints = fiducialPoints(fiducialPoints > 1 & fiducialPoints <= length(tc.ecg));

            [cleanedSignal, baseline, fiducialValues] = baselineremove(tc.ecg, fiducialPoints);

            % Verify function executed successfully
            tc.verifySize(cleanedSignal, size(tc.ecg), 'Output signal size mismatch');
            tc.verifySize(baseline, size(tc.ecg), 'Baseline size mismatch');
            tc.verifySize(fiducialValues, size(fiducialPoints), 'Fiducial values size mismatch');
            tc.verifyNotEqual(cleanedSignal, tc.ecg, 'Signal was not modified');
        end

        function testInvalidInputs(tc)
            signal = sin(1:100)';
            fiducialPoints = [25; 50; 75];

            % Test invalid fiducial points
            tc.verifyError(@() baselineremove(signal, [-1; 50]), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            % Test empty signal
            tc.verifyError(@() baselineremove([], fiducialPoints), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            % Test invalid window size
            tc.verifyError(@() baselineremove(signal, fiducialPoints, 'WindowSize', 0), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function testWindowSizeEffect(tc)
            % Use preloaded fixture data
            prInterval = round(0.08 * tc.fs);
            fiducialPoints = tc.rPeakSamples - prInterval;
            fiducialPoints = fiducialPoints(fiducialPoints > 1 & fiducialPoints <= length(tc.ecg));

            [clean1, ~] = baselineremove(tc.ecg, fiducialPoints, 'WindowSize', 3);
            [clean2, ~] = baselineremove(tc.ecg, fiducialPoints, 'WindowSize', 11);

            tc.verifyNotEqual(clean1, clean2, 'Window size had no effect');
        end
    end
end
