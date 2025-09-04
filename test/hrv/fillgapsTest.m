
% Tests covering:
%   - Number preservation after gap filling
%   - Large gap handling with NaN marking

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
            tc.originalTk = removefp(tc.originalTk);
            tc.tolerance = 0.05;
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

        function testLargeGapHandling(tc)
            tk = 0:0.8:60; % Regular 75 bpm baseline

            % Create gaps of different sizes
            tk(20:21) = [];    % Small gap (1.6s) - should be filled
            tk(38:42) = [];    % Medium gap (4s) - should be filled

            % Create a very large gap by inserting a long interval
            tkWithLargeGap = tk;
            % Insert a 15-second gap (exceeds maxgapDuration of 10s)
            tkWithLargeGap = [tkWithLargeGap(1:30), tkWithLargeGap(30) + 15, tkWithLargeGap(31:end) + 15];

            % Test with two outputs
            [~, dtn] = fillgaps(tkWithLargeGap, false);

            % Verify that very large gaps are marked as NaN
            tc.verifyTrue(any(isnan(dtn)), 'Large gaps should be marked as NaN in dtn');

            % Count NaN values
            nanCount = sum(isnan(dtn));
            tc.verifyTrue(nanCount == 1, 'Only one interval should be NaN');
        end
    end
end
