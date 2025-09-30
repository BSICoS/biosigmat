% Tests covering:
%   - Basic functionality with normalized PPG signal
%   - Optional parameters usage
%   - Input validation

classdef hjorthArtifactsTest < matlab.unittest.TestCase

    methods (TestClassSetup)
        function addSourcePath(~)
            % Add required paths for testing
            addpath('../../src/ppg');
            addpath('../../src/tools');
        end
    end

    methods (Test)

        function testBasicFunctionality(tc)
            % Load PPG signal from fixtures
            ppgData = readtable('../../fixtures/ppg/ppg_signals.csv');
            ppg = ppgData.sig;
            fs = 1000;

            % Normalize signal as in the example
            ppg = normalize(ppg);

            % Define parameters following the example
            seg = 4;
            step = 3;
            marginH0 = [5, 1];
            marginH1 = [0.5 0.5];
            marginH2 = [1, 2];
            margins = [marginH0; marginH1; marginH2];

            % Test the function
            [artifactVector, artifactMatrix] = hjorthArtifacts(ppg, fs, seg, step, margins);

            % Verify output types and dimensions
            tc.verifyClass(artifactVector, 'double', 'Artifact vector should be numeric (double)');
            tc.verifyTrue(all(ismember(artifactVector, [0, 1])), 'Artifact vector should contain only 0s and 1s');
            tc.verifyEqual(length(artifactVector), length(ppg), 'Artifact vector should match signal length');
            tc.verifyTrue(isnumeric(artifactMatrix), 'Artifact matrix should be numeric');

            % Verify artifact matrix format (should be Nx2 with time values)
            if ~isempty(artifactMatrix)
                tc.verifyEqual(size(artifactMatrix, 2), 2, 'Artifact matrix should have 2 columns');
                tc.verifyTrue(all(artifactMatrix(:,1) <= artifactMatrix(:,2)), 'Start times should be <= end times');
                tc.verifyTrue(all(artifactMatrix(:) >= 0), 'All times should be non-negative');
            end
        end

        function testOptionalParameters(tc)
            % Load PPG signal from fixtures
            ppgData = readtable('../../fixtures/ppg/ppg_signals.csv');
            ppg = ppgData.sig;
            fs = 1000;

            % Normalize signal
            ppg = normalize(ppg);

            % Define parameters
            seg = 4;
            step = 3;
            marginH0 = [5, 1];
            marginH1 = [0.5 0.5];
            marginH2 = [1, 2];
            margins = [marginH0; marginH1; marginH2];

            % Test with optional parameters
            [artifactVector, artifactMatrix] = hjorthArtifacts(ppg, fs, seg, step, margins, ...
                'minSegmentSeparation', 1, 'medfiltOrder', 15, 'negative', false, 'plotflag', false);

            % Verify outputs
            tc.verifyClass(artifactVector, 'double', 'Artifact vector should be numeric (double)');
            tc.verifyTrue(all(ismember(artifactVector, [0, 1])), 'Artifact vector should contain only 0s and 1s');
            tc.verifyEqual(length(artifactVector), length(ppg), 'Artifact vector should match truncated signal length');
            tc.verifyTrue(isnumeric(artifactMatrix), 'Artifact matrix should be numeric');
        end

        function testInputValidation(tc)
            % Valid inputs
            ppg = randn(1000, 1);
            fs = 1000;
            seg = 4;
            step = 3;
            margins = [5, 1; 0.5, 0.5; 1, 2];

            % Test invalid signal input
            tc.verifyError(@() hjorthArtifacts([], fs, seg, step, margins), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            % Test invalid fs input
            tc.verifyError(@() hjorthArtifacts(ppg, 0, seg, step, margins), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            % Test invalid margins size
            invalidMargins = [5, 1; 0.5, 0.5]; % Only 2 rows instead of 3
            tc.verifyError(@() hjorthArtifacts(ppg, fs, seg, step, invalidMargins), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
        end

    end
end
