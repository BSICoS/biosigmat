
% Tests covering:
%   - Number preservation after gap filling
%   - Timing accuracy within tolerance

classdef fillgapsTest < matlab.unittest.TestCase

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
            
            % Remove false positives from the original data (same as fillgaps does)
            tc.originalTk = tc.removefp(tc.originalTk);
            
            tc.tolerance = 0.05; % 50ms tolerance for timing differences
        end
    end

    methods (Test)
        function testRandomGapFilling(tc)
            tk = tc.originalTk(1:100);
            originalLength = length(tk);

            % Randomly remove 10-15% of the detections to create gaps
            rng(40);
            numToRemove = round(0.1 * originalLength) + randi(round(0.05 * originalLength));
            indicesToRemove = sort(randperm(originalLength, numToRemove));

            % Create gaps by removing random detections
            tkWithGaps = tk;
            tkWithGaps(indicesToRemove) = [];

            % Apply gap filling
            tn = fillgaps(tkWithGaps, false);

            % Verify that the number of corrected events matches the original
            tc.verifyEqual(length(tn), originalLength, ...
                'Number of corrected events should match original');

            % Verify that timing values are within tolerance
            timingDifferences = abs(tn - tk);
            tc.verifyTrue(all(timingDifferences <= tc.tolerance), ...
                sprintf('All timing differences should be within %.3f seconds tolerance', tc.tolerance));
        end

        function testConsecutiveRemovedBeats(tc)
            tk = tc.originalTk(1:50);
            originalLength = length(tk);

            % Remove consecutive beats to create larger gaps
            tkWithGaps = tk;
            tkWithGaps(10:12) = [];
            tkWithGaps(20:22) = [];

            % Apply gap filling
            tn = fillgaps(tkWithGaps, false);

            % Verify that the number of corrected events matches the original
            tc.verifyEqual(length(tn), originalLength, ...
                'Number of corrected events should match original after sequential gap filling');

            % Verify that timing values are within tolerance
            timingDifferences = abs(tn - tk);
            tc.verifyTrue(all(timingDifferences <= tc.tolerance), ...
                sprintf('All timing differences should be within %.3f seconds tolerance for sequential gaps', tc.tolerance));
        end

        function testBasicInput(tc)
            % Test with a few beat input that requires no gap filling
            tk = tc.originalTk(1:5);

            tn = fillgaps(tk, false);

            % Should return the same input when no gaps exist
            tc.verifyEqual(tn, tk, 'AbsTol', 1e-10, ...
                'Input with no gaps should return unchanged');
        end
    end

    methods (Access = private)
        function tk = removefp(~, tk)
            % REMOVEFP Remove false positive detections from HRV event series.
            % Copied from fillgaps.m to ensure consistent preprocessing

            tk = tk(:);
            dtk = diff(tk);

            % Calculate adaptive baseline for RR intervals
            baseline = medfiltThreshold(dtk, 30, 1, 1.5);

            % Identify intervals that are too short (false positives)
            fp = dtk<0.7*baseline;

            % Remove the second beat in each false positive pair
            tk(find(fp)+1) = [];
        end
    end
end
