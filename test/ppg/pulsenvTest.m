% Tests covering:
%   - Basic functionality (lower and upper envelopes)
%   - Single-output behavior (lower envelope only)
%   - Empty detections handling
%   - Window parameter effect

classdef pulsenvTest < matlab.unittest.TestCase
    properties (TestParameter)
        caseId = getBiosiglibConformanceCaseIds('ppg.pulsenv')
    end

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
        function testConformance(tc, caseId)
            c = loadBiosiglibConformanceCase(caseId);
            ppg = loadBiosiglibConformanceInput(c, 'ppg');
            fs = loadBiosiglibConformanceInput(c, 'sampling_frequency');
            inputs = c.inputs;
            if iscell(inputs)
                ids = cellfun(@(x) x.id, inputs, 'UniformOutput', false);
            else
                ids = {inputs.id};
            end
            if ismember('t_d', ids)
                args = {loadBiosiglibConformanceInput(c, 't_d')};
            else
                args = {'tA', loadBiosiglibConformanceInput(c, 't_a'), ...
                    'tB', loadBiosiglibConformanceInput(c, 't_b')};
            end
            if isfield(c.parameters, 'max_gap')
                args = [args, {'MaxGap', c.parameters.max_gap}];
            end
            [lo, hi] = pulsenv(ppg, fs, args{:});
            verifyBiosiglibExpectedOutputs(tc, struct('lower_envelope', lo, ...
                'upper_envelope', hi), c);
        end

        function testRejectTimeVector(tc)
            tc.verifyError(@() pulsenv([1; 2; 3], [0; 1; 2], []), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function testTwoOutputs(tc)
            tD = pulsedet(tc.dppg, tc.fs);
            [lowerEnv, upperEnv] = pulsenv(tc.ppg, tc.fs, tD);

            tc.verifyClass(lowerEnv, 'double');
            tc.verifyClass(upperEnv, 'double');
            tc.verifySize(lowerEnv, size(tc.ppg(:)));
            tc.verifySize(upperEnv, size(tc.ppg(:)));

            [tA, tB] = pulsedel(tc.ppg, tc.fs, tD);
            [fromB, fromA] = pulsenv(tc.ppg, tc.fs, 'tA', tA, 'tB', tB);
            tc.verifyEqual(lowerEnv, fromB);
            tc.verifyEqual(upperEnv, fromA);
        end

        function testSingleOutputMatchesLowerEnvelope(tc)
            tD = pulsedet(tc.dppg, tc.fs);
            lowerOnly = pulsenv(tc.ppg, tc.fs, tD);
            [lowerEnv, ~] = pulsenv(tc.ppg, tc.fs, tD);

            tc.verifyEqual(lowerOnly, lowerEnv, 'Single-output call should return the lower envelope');
        end

        function testEmptyDetections(tc)
            warningId = 'pulsenv:emptyDetections';
            tc.verifyWarning(@() pulsenv(tc.ppg, tc.fs, []), warningId);

            warningState = warning('off', warningId);
            cleanup = onCleanup(@() warning(warningState));

            [lowerEnv, upperEnv] = pulsenv(tc.ppg, tc.fs, []);
            tc.verifyTrue(all(isnan(lowerEnv)), 'Lower envelope should be all NaN for empty detections');
            tc.verifyTrue(all(isnan(upperEnv)), 'Upper envelope should be all NaN for empty detections');
        end

        function testWindowParameterEffect(tc)
            tD = pulsedet(tc.dppg, tc.fs);

            lower1 = pulsenv(tc.ppg, tc.fs, tD, 'WindowB', 300e-3);
            lower2 = pulsenv(tc.ppg, tc.fs, tD, 'WindowB', 50e-3);

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
            tc.verifyWarning(@() pulsenv(signal, samplingRate, tD), 'pulsenv:insufficientLowerAnchors');

            % Two outputs: suppress lower warning and verify upper warning
            lowerWarnState = warning('off', 'pulsenv:insufficientLowerAnchors');
            cleanupLower = onCleanup(@() warning(lowerWarnState));
            tc.verifyWarning(@() callTwoOutputs(signal, samplingRate, tD), 'pulsenv:insufficientUpperAnchors');
            clear cleanupLower
        end
    end
end

function [lowerEnvelope, upperEnvelope] = callTwoOutputs(ppg, fs, tD)
[lowerEnvelope, upperEnvelope] = pulsenv(ppg, fs, tD);
end
