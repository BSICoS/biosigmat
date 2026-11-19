% Tests covering:
%   - Basic functionality (lower and upper envelopes)
%   - Single-output behavior (lower envelope only)
%   - Empty detections handling
%   - Window parameter effect

classdef pulseenvelopesTest < matlab.unittest.TestCase
    properties
        ppg
        dppg
        fs
    end

    methods (TestClassSetup)
        function addCodeToPath(~)
            addpath(fullfile('..', '..', 'src', 'ppg'));
            addpath(fullfile('..', '..', 'src', 'tools'));
        end
    end

    methods (TestMethodSetup)
        function loadFixtures(tc)
            % Load PPG signal from fixtures
            ppgData = readtable(fullfile('..', '..', 'fixtures', 'ppg', 'ppg_signals.csv'));
            rawPpg = ppgData.sig;
            tc.fs = 1000;

            % Use only the first 30 seconds of the signal
            tc.ppg = rawPpg(1:30*tc.fs);

            % LPD filter for pulse detection
            fpLPD = 7.8;
            fcLPD = 8;
            orderLPD = 100;

            [b, delay] = lpdfilter(tc.fs, fcLPD, 'PassFreq', fpLPD, 'Order', orderLPD);
            dppgFiltered = filter(b, 1, tc.ppg);
            tc.dppg = [dppgFiltered(delay+1:end); zeros(delay, 1)];
        end
    end

    methods (Test)
        function testTwoOutputs(tc)
            tD = pulsedet(tc.dppg, tc.fs);
            [lowerEnv, upperEnv] = pulseenvelopes(tc.ppg, tc.fs, tD);

            tc.verifyClass(lowerEnv, 'double');
            tc.verifyClass(upperEnv, 'double');
            tc.verifySize(lowerEnv, size(tc.ppg(:)));
            tc.verifySize(upperEnv, size(tc.ppg(:)));

            validTD = tD(~isnan(tD));
            tc.verifyGreaterThan(numel(validTD), 1, 'Expected at least two detections in fixture segment');

            t = (0:length(tc.ppg)-1)'/tc.fs;
            firstTD = validTD(1);
            lastTD = validTD(end);

            tc.verifyTrue(all(isnan(lowerEnv(t < firstTD))), 'Lower envelope should be NaN before first detection');
            tc.verifyTrue(all(isnan(lowerEnv(t > lastTD))), 'Lower envelope should be NaN after last detection');
            tc.verifyTrue(all(isnan(upperEnv(t < firstTD))), 'Upper envelope should be NaN before first detection');
            tc.verifyTrue(all(isnan(upperEnv(t > lastTD))), 'Upper envelope should be NaN after last detection');
        end

        function testSingleOutputMatchesLowerEnvelope(tc)
            tD = pulsedet(tc.dppg, tc.fs);
            lowerOnly = pulseenvelopes(tc.ppg, tc.fs, tD);
            [lowerEnv, ~] = pulseenvelopes(tc.ppg, tc.fs, tD);

            tc.verifyEqual(lowerOnly, lowerEnv, 'Single-output call should return the lower envelope');
        end

        function testEmptyDetections(tc)
            warningId = 'pulseenvelopes:emptyDetections';
            tc.verifyWarning(@() pulseenvelopes(tc.ppg, tc.fs, []), warningId);

            warningState = warning('off', warningId);
            cleanup = onCleanup(@() warning(warningState));

            [lowerEnv, upperEnv] = pulseenvelopes(tc.ppg, tc.fs, []);
            tc.verifyTrue(all(isnan(lowerEnv)), 'Lower envelope should be all NaN for empty detections');
            tc.verifyTrue(all(isnan(upperEnv)), 'Upper envelope should be all NaN for empty detections');
        end

        function testWindowParameterEffect(tc)
            tD = pulsedet(tc.dppg, tc.fs);

            lower1 = pulseenvelopes(tc.ppg, tc.fs, tD, 'WindowB', 300e-3);
            lower2 = pulseenvelopes(tc.ppg, tc.fs, tD, 'WindowB', 50e-3);

            delta = lower1 - lower2;
            delta = delta(~isnan(delta));
            tc.verifyGreaterThan(nnz(abs(delta) > 0), 0, 'Changing WindowB should affect the lower envelope');
        end

        function testInsufficientAnchorsWarns(tc)
            % Create two detections that collapse to the same sample index after rounding
            signal = zeros(1000, 1);
            samplingRate = 1000;
            tD = [0.5001; 0.5002];

            % Lower envelope only: should warn about insufficient lower anchors
            tc.verifyWarning(@() pulseenvelopes(signal, samplingRate, tD), 'pulseenvelopes:insufficientLowerAnchors');

            % Two outputs: suppress lower warning and verify upper warning
            lowerWarnState = warning('off', 'pulseenvelopes:insufficientLowerAnchors');
            cleanupLower = onCleanup(@() warning(lowerWarnState));
            tc.verifyWarning(@() callTwoOutputs(signal, samplingRate, tD), 'pulseenvelopes:insufficientUpperAnchors');
            clear cleanupLower
        end
    end
end

function [lowerEnvelope, upperEnvelope] = callTwoOutputs(ppg, fs, tD)
[lowerEnvelope, upperEnvelope] = pulseenvelopes(ppg, fs, tD);
end
