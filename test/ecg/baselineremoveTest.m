% Tests covering:
%   - Basic functionality with real ECG data from fixtures using R-peaks and offset
%   - Error handling (invalid inputs, negative offset, invalid window size)
%   - Different window size effect

classdef baselineremoveTest < matlab.unittest.TestCase
    properties
        ecg
        tk
        fs
        offset
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
            tc.tk = tkData(:, 2);

            tc.fs = 256;
            tc.offset = round(0.15 * tc.fs);
        end
    end

    methods (Test)
        function testBasicFunctionality(tc)
            [ecgDetrended, baseline] = baselineremove(tc.ecg, tc.tk, tc.offset);

            % Verify function executed successfully
            tc.verifySize(ecgDetrended, size(tc.ecg), 'Output signal size mismatch');
            tc.verifySize(baseline, size(tc.ecg), 'Baseline size mismatch');
            tc.verifyNotEqual(ecgDetrended, tc.ecg, 'Signal was not modified');
        end

        function testInvalidInputs(tc)
            % Test invalid tk indices
            tc.verifyError(@() baselineremove(tc.ecg, [-1; 50], tc.offset), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            % Test empty signal
            tc.verifyError(@() baselineremove([], tc.tk, tc.offset), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            % Test invalid offset
            tc.verifyError(@() baselineremove(tc.ecg, tc.tk, -1), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            % Test invalid window size
            tc.verifyError(@() baselineremove(tc.ecg, tc.tk, tc.offset, 0), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function testWindowSizeEffect(tc)
            clean1 = baselineremove(tc.ecg, tc.tk, tc.offset, 3);
            clean2 = baselineremove(tc.ecg, tc.tk, tc.offset, 11);

            tc.verifyNotEqual(clean1, clean2, 'Window size had no effect');
        end
    end
end
