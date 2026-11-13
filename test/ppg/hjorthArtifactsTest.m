% Tests covering:
%   - Basic functionality with normalized PPG signal
%   - Optional parameters usage
%   - Input validation

classdef hjorthArtifactsTest < matlab.unittest.TestCase

    properties (TestParameter)
        caseId = getBiosiglibConformanceCaseIds('ppg.hjorth_artifacts')
    end

    methods (TestClassSetup)
        function addSourcePath(~)
            % Add required paths for testing
            root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            addpath(fullfile(root, 'src', 'ppg'));
            addpath(fullfile(root, 'src', 'tools'));
            addpath(fullfile(root, 'test', 'common'));
        end
    end

    methods (Test)
        function testConformance(tc, caseId)
            c = loadBiosiglibConformanceCase(caseId);
            ids = {'signal','sampling_frequency','window_duration','step_duration','margins'};
            args = cellfun(@(id) loadBiosiglibConformanceInput(c,id), ids, 'UniformOutput',false);
            names = {'min_segment_separation','median_filter_order','negative'};
            matlabNames = {'minSegmentSeparation','medfiltOrder','negative'};
            for k=1:numel(names)
                if isfield(c.parameters,names{k})
                    args = [args, {matlabNames{k},c.parameters.(names{k})}]; %#ok<AGROW>
                end
            end
            [mask,intervals] = hjorthArtifacts(args{:});
            starts = []; ends = [];
            if ~isempty(intervals), starts=intervals(:,1); ends=intervals(:,2); end
            actual = struct('artifact_mask',mask,'artifact_starts',starts,'artifact_ends',ends);
            verifyBiosiglibExpectedOutputs(tc,actual,c);
        end


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
