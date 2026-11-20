% Tests covering:
%   - Basic functionality with PPG signal from fixtures
%   - Custom parameters
%   - Empty detections
%   - Nargout-optimized behavior

classdef pulsedelTest < matlab.unittest.TestCase
    properties (TestParameter)
        caseId = getBiosiglibConformanceCaseIds('ppg.pulsedel')
    end

    properties
        ppg
        dppg
        fs
        tD
    end

    methods (TestClassSetup)
        function addCodeToPath(~)
            addpath(fullfile('..', '..', 'src', 'ppg'));
            addpath(fullfile('..', '..', 'src', 'tools'));
        end
    end

    methods (TestMethodSetup)
        function loadFixtures(tc)
            ppgData = readtable(fullfile('..', '..', 'fixtures', 'ppg', 'ppg_signals.csv'));
            rawSignal = ppgData.sig;
            tc.fs = 1000;

            rawSignal = rawSignal(1:30*tc.fs);
            [b, a] = butter(4, 0.5 / (tc.fs/2), 'high');
            tc.ppg = filtfilt(b, a, rawSignal);

            % Apply LPD (Low-Pass Differentiator) filter
            fpLPD = 7.8;        % Pass-band frequency (Hz)
            fcLPD = 8;          % Cut-off frequency (Hz)
            orderLPD = 100;     % Filter order (samples)

            [b, delay] = lpdfilter(tc.fs, fcLPD, 'PassFreq', fpLPD, 'Order', orderLPD);
            tc.dppg = filter(b, 1, tc.ppg);
            tc.dppg = [tc.dppg(delay+1:end); zeros(delay, 1)];

            % Compute pulse detection points for use in tests
            tc.tD = pulsedet(tc.dppg, tc.fs);
        end
    end

    methods (Test)
        function testConformance(tc, caseId)
            c = loadBiosiglibConformanceCase(caseId);
            ppg = loadBiosiglibConformanceInput(c, 'ppg');
            fs = loadBiosiglibConformanceInput(c, 'sampling_frequency');
            tD = loadBiosiglibConformanceInput(c, 't_d');
            dppg = loadBiosiglibConformanceInput(c, 'dppg');
            [a, b, m, o] = pulsedel(ppg, fs, tD, dppg);
            verifyBiosiglibExpectedOutputs(tc, struct('t_a', a, 't_b', b, ...
                't_m', m, 't_o', o), c);
        end

        function testMissingDerivative(tc)
            tc.verifyError(@() requestOnset(tc.ppg, tc.fs, tc.tD), ...
                'pulsedel:MissingDerivative');
        end

        function testDetectionAlignment(tc)
            detections = [tc.tD(2), NaN, tc.tD(1), tc.tD(2)];
            [a, b, m, o] = pulsedel(tc.ppg, tc.fs, detections, tc.dppg);
            for output = {a, b, m, o}
                tc.verifySize(output{1}, [4, 1]);
                tc.verifyTrue(isnan(output{1}(2)));
                tc.verifyEqual(output{1}(1), output{1}(4));
                tc.verifyGreaterThan(output{1}(1), output{1}(3));
            end
            tc.verifyError(@() pulsedel(tc.ppg, tc.fs, -0.1/tc.fs), ...
                'pulsedel:DetectionOutOfBounds');
        end

        function testBasicFunctionality(tc)
            [tA, tB, tM] = pulsedel(tc.ppg, tc.fs, tc.tD);

            % Expected values
            expectedTA = [0.5805; 1.3400; 2.0684; 2.7887; 3.4662];
            expectedTB = [0.4321; 1.1918; 1.9361; 2.6565; 3.3312];
            expectedTM = [0.4850; 1.2430; 1.9880; 2.7070; 3.3790];

            % Verify outputs are the correct size and type
            tc.verifyClass(tA, 'double', 'tA should be double array');
            tc.verifyClass(tB, 'double', 'tB should be double array');
            tc.verifyClass(tM, 'double', 'tM should be double array');

            % Verify first 5 values of each output (with tolerance for numerical precision)
            tolerance = 1e-3;

            actualTA = tA(~isnan(tA));
            tc.verifyEqual(actualTA(1:5), expectedTA, 'AbsTol', tolerance, ...
                'First 5 tA values do not match expected values');

            actualTB = tB(~isnan(tB));
            tc.verifyEqual(actualTB(1:5), expectedTB, 'AbsTol', tolerance, ...
                'First 5 tB values do not match expected values');

            actualTM = tM(~isnan(tM));
            tc.verifyEqual(actualTM(1:5), expectedTM, 'AbsTol', tolerance, ...
                'First 5 tM values do not match expected values');
        end

        function testCustomParameters(tc)
            customWindowA = 300e-3;
            customWindowB = 200e-3;

            [tA, tB, tM] = pulsedel(tc.ppg, tc.fs, tc.tD, ...
                'WindowA', customWindowA, 'WindowB', customWindowB);

            % Verify outputs are valid
            tc.verifyClass(tA, 'double', 'tA should be double array');
            tc.verifyClass(tB, 'double', 'tB should be double array');
            tc.verifyClass(tM, 'double', 'tM should be double array');

            % Verify that we get reasonable results (not all NaN)
            tc.verifyTrue(sum(~isnan(tA)) > 0, 'Should detect at least one apex');
            tc.verifyTrue(sum(~isnan(tB)) > 0, 'Should detect at least one basal point');
            tc.verifyTrue(sum(~isnan(tM)) > 0, 'Should detect at least one pulse midpoint');
        end

        function testEmptyDetectionPoints(tc)
            [tA, tB, tM] = pulsedel(tc.dppg, tc.fs, []);

            tc.verifySize(tA, [0, 1]);
            tc.verifySize(tB, [0, 1]);
            tc.verifySize(tM, [0, 1]);
        end

        function testNargoutOptimization(tc)
            % Test with nargout = 1 (only tA)
            tA = pulsedel(tc.ppg, tc.fs, tc.tD);
            tc.verifyClass(tA, 'double', 'tA should be double array');
            tc.verifyTrue(sum(~isnan(tA)) > 0, 'Should detect at least one apex');

            % Test with nargout = 2 (tA and tB)
            [tA, tB] = pulsedel(tc.ppg, tc.fs, tc.tD);
            tc.verifyClass(tA, 'double', 'tA should be double array');
            tc.verifyClass(tB, 'double', 'tB should be double array');
            tc.verifyTrue(sum(~isnan(tA)) > 0, 'Should detect at least one apex');
            tc.verifyTrue(sum(~isnan(tB)) > 0, 'Should detect at least one basal point');
        end
    end
end


function requestOnset(ppg, fs, tD)
% REQUESTONSET Request all four outputs without providing the derivative.
%
%   REQUESTONSET(PPG, FS, TD) exercises the missing-derivative error.
[~, ~, ~, ~] = pulsedel(ppg, fs, tD);
end
