% Tests covering:
%   - Basic false positive removal
%   - Synthetic false positive insertion and removal
%   - Edge cases with few elements

classdef removefpTest < matlab.unittest.TestCase

    properties
        originalTk
        tolerance
    end

    methods (TestClassSetup)
        function addCodeToPath(~)
            addpath('../../src/hrv');
            addpath('../../src/tools');
        end
    end

    methods (TestMethodSetup)
        function loadFixtures(tc)
            % Load ECG timing data from fixture
            tkData = readtable('../../fixtures/ecg/ecg_tk.csv');
            tc.originalTk = tkData.tk;
            tc.tolerance = 0.01; % 10ms tolerance for timing differences
        end
    end

    methods (Test)
        function testBasicFalsePositiveRemoval(tc)
            tk = tc.originalTk(1:50);
            originalLength = length(tk);

            % Insert synthetic false positives (beats very close to existing ones)
            tkWithFPs = tk;
            fpIndices = [10, 20, 30]; % Insert FPs after these beats
            fpOffsets = [0.05, 0.08, 0.06]; % Very short intervals (50-80ms)

            for i = 1:length(fpIndices)
                idx = fpIndices(i);
                fpBeat = tk(idx) + fpOffsets(i);
                tkWithFPs = [tkWithFPs; fpBeat]; %#ok<AGROW>
            end

            % Sort the series with false positives
            tkWithFPs = sort(tkWithFPs);

            % Apply false positive removal
            tkCleaned = removefp(tkWithFPs);

            % Verify that false positives were removed
            tc.verifyEqual(length(tkCleaned), originalLength, ...
                'Should remove exactly the inserted false positives');

            % Verify that the cleaned series matches the original (within tolerance)
            tc.verifyEqual(tkCleaned, tk, 'AbsTol', tc.tolerance, ...
                'Cleaned series should match original after FP removal');
        end
    end
end
