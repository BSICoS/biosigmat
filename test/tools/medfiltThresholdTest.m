% Tests covering:
%   - Basic threshold computation functionality
%   - Input validation for parameters

classdef medfiltThresholdTest < matlab.unittest.TestCase

    properties
        tk
        dtk
    end

    properties (TestParameter)
        validConformanceCaseId = {
            'tools.medfilt_threshold.normal_outlier'
            'tools.medfilt_threshold.window_larger_than_signal'
            'tools.medfilt_threshold.even_window_behavior'
            'tools.medfilt_threshold.odd_window_behavior'
            'tools.medfilt_threshold.row_vector_orientation'
            'tools.medfilt_threshold.max_threshold_cap'
            'tools.medfilt_threshold.include_nan_window'
        }
        expectedErrorCaseId = {
            'tools.medfilt_threshold.invalid_window_one'
            'tools.medfilt_threshold.invalid_single_sample'
        }
    end

    methods (TestClassSetup)
        function addCodeToPath(tc)
            testDirectory = fileparts(mfilename('fullpath'));
            repositoryRoot = fileparts(fileparts(testDirectory));
            originalPath = path;
            tc.addTeardown(@() path(originalPath));
            addpath(fullfile(repositoryRoot, 'src', 'tools'));
            addpath(fullfile(repositoryRoot, 'test', 'common'));
        end
    end

    methods (TestMethodSetup)
        function loadFixtures(tc)
            testDirectory = fileparts(mfilename('fullpath'));
            repositoryRoot = fileparts(fileparts(testDirectory));
            tkData = readtable(fullfile( ...
                repositoryRoot, 'fixtures', 'ecg', 'medicom_mtd_r_wave_timing.csv'));
            tc.tk = tkData.r_wave_times;
            tc.dtk = diff(tc.tk);
        end
    end

    methods (Test)
        function testBiosiglibConformanceCase(tc, validConformanceCaseId)
            caseDefinition = loadBiosiglibConformanceCase(validConformanceCaseId);
            x = loadBiosiglibConformanceInput(caseDefinition, 'x');
            parameters = caseDefinition.parameters;

            threshold = medfiltThreshold( ...
                x, parameters.window, parameters.factor, parameters.max_threshold);

            actualOutputs = struct('threshold', threshold);
            verifyBiosiglibExpectedOutputs(tc, actualOutputs, caseDefinition);
        end

        function testBiosiglibExpectedError(tc, expectedErrorCaseId)
            caseDefinition = loadBiosiglibConformanceCase(expectedErrorCaseId);
            x = loadBiosiglibConformanceInput(caseDefinition, 'x');
            parameters = caseDefinition.parameters;

            verifyBiosiglibExpectedError(tc, ...
                @() medfiltThreshold( ...
                    x, parameters.window, parameters.factor, parameters.max_threshold), ...
                caseDefinition);
        end

        function testBasicFuntionality(tc)
            % Create modified tk with 4 gaps
            tkWithGaps = tc.tk;
            tkWithGaps([10,20,30,40]) = [];
            dtkWithGaps = diff(tkWithGaps);

            threshold = medfiltThreshold(dtkWithGaps, 50, 1.5, 1.5);

            % Verify threshold detects artificial gaps
            gapIndices = dtkWithGaps > threshold;
            tc.verifyEqual(sum(gapIndices), 4, 'Threshold should detect artificial gaps');
            tc.verifyEqual(length(dtkWithGaps), length(threshold), 'Threshold should detect artificial gaps');
        end

        function testInputValidation(tc)
            % Test insufficient input arguments
            tc.verifyError(@() medfiltThreshold([0.8, 0.82]), 'MATLAB:narginchk:notEnoughInputs', ...
                'Insufficient input arguments should raise error');

            tc.verifyError(@() medfiltThreshold([0.8, 0.82], 50), 'MATLAB:narginchk:notEnoughInputs', ...
                'Insufficient input arguments should raise error');

            tc.verifyError(@() medfiltThreshold([0.8, 0.82], 50, 1.5), 'MATLAB:narginchk:notEnoughInputs', ...
                'Insufficient input arguments should raise error');

            % Test empty input
            tc.verifyError(@() medfiltThreshold([], 50, 1.5, 1.5), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Empty input should raise validation error');

            % Test non-vector input
            tc.verifyError(@() medfiltThreshold([1,2;3,4], 50, 1.5, 1.5), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Non-vector input should raise validation error');

            % Test invalid window parameter
            tc.verifyError(@() medfiltThreshold([0.8, 0.82], 0, 1.5, 1.5), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Zero window should raise validation error');

            % Test invalid factor parameter
            tc.verifyError(@() medfiltThreshold([0.8, 0.82], 10, -1, 1.5), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Negative factor should raise validation error');

            % Test invalid maxthreshold parameter
            tc.verifyError(@() medfiltThreshold([0.8, 0.82], 10, 1.5, -0.5), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Negative maxthreshold should raise validation error');
        end

        function testParameters(tc)
            % Test window parameter
            threshold1 = medfiltThreshold(tc.dtk, 3, 1.5, 1.5);
            tc.verifyEqual(length(threshold1), length(tc.dtk), 'Window parameter should work correctly');

            % Test factor parameter
            threshold2 = medfiltThreshold(tc.dtk, 3, 2, 1.5);
            tc.verifyTrue(all(threshold2 > threshold1), 'Higher factor should produce higher thresholds');

            % Test maxthreshold parameter
            maxthreshold = 1.5;
            threshold3 = medfiltThreshold(tc.dtk, 3, 3, maxthreshold);
            tc.verifyTrue(all(threshold3 <= maxthreshold), 'Maxthreshold should cap the threshold values');
        end
    end
end
