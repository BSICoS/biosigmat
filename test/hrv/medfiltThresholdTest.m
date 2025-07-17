% Tests covering:
%   - Basic threshold computation functionality
%   - Input validation for parameters

classdef medfiltThresholdTest < matlab.unittest.TestCase

    properties
        tk
        dtk
    end

    methods (TestClassSetup)
        function addCodeToPath(~)
            addpath('../../src/hrv');
        end
    end

    methods (TestMethodSetup)
        function loadFixtures(tc)
            tkData = readtable('../../fixtures/ecg/ecg_tk.csv');
            tc.tk = tkData.tk;
            tc.dtk = diff(tc.tk);
        end
    end

    methods (Test)
        function testBasicFuntionality(tc)
            % Create modified tk with 4 gaps
            tkWithGaps = tc.tk;
            tkWithGaps([10,20,30,40]) = [];
            dtkWithGaps = diff(tkWithGaps);

            threshold = medfiltThreshold(dtkWithGaps);

            % Verify threshold detects artificial gaps
            gapIndices = dtkWithGaps > threshold;
            tc.verifyEqual(sum(gapIndices), 4, 'Threshold should detect artificial gaps');
            tc.verifyEqual(length(dtkWithGaps), length(threshold), 'Threshold should detect artificial gaps');
        end

        function testInputValidation(tc)
            % Test empty input
            tc.verifyError(@() medfiltThreshold([]), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Empty input should raise validation error');

            % Test non-vector input
            tc.verifyError(@() medfiltThreshold([1,2;3,4]), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Non-vector input should raise validation error');

            % Test invalid window parameter
            tc.verifyError(@() medfiltThreshold([0.8, 0.82], 0), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Zero window should raise validation error');

            % Test invalid factor parameter
            tc.verifyError(@() medfiltThreshold([0.8, 0.82], 10, -1), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Negative factor should raise validation error');

            % Test invalid maxthreshold parameter
            tc.verifyError(@() medfiltThreshold([0.8, 0.82], 10, 1.5, -0.5), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Negative maxthreshold should raise validation error');
        end

        function testParameters(tc)
            % Test window parameter
            threshold1 = medfiltThreshold(tc.dtk, 3);
            tc.verifyEqual(length(threshold1), length(tc.dtk), 'Window parameter should work correctly');

            % Test factor parameter
            threshold2 = medfiltThreshold(tc.dtk, 3, 2);
            tc.verifyTrue(all(threshold2 > threshold1), 'Higher factor should produce higher thresholds');

            % Test maxthreshold parameter
            maxthreshold = 1.5;
            threshold3 = medfiltThreshold(tc.dtk, 3, 3, maxthreshold);
            tc.verifyTrue(all(threshold3 <= maxthreshold), 'Maxthreshold should cap the threshold values');
        end
    end
end