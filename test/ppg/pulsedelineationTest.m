% Tests covering:
%   - Basic functionality with PPG signal from fixtures
%   - Custom parameters
%   - Empty detections
%   - Nargout-optimized behavior

classdef pulsedelineationTest < matlab.unittest.TestCase
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
            tc.tD = pulsedetection(tc.dppg, tc.fs);
        end
    end

    methods (Test)
        function testBasicFunctionality(tc)
            [tA, tB, tM] = pulsedelineation(tc.ppg, tc.fs, tc.tD);

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

            [tA, tB, tM] = pulsedelineation(tc.ppg, tc.fs, tc.tD, ...
                'WindowA', customWindowA, 'WindowB', customWindowB);

            % Verify outputs are valid
            tc.verifyClass(tA, 'double', 'tA should be double array');
            tc.verifyClass(tB, 'double', 'tB should be double array');
            tc.verifyClass(tM, 'double', 'tM should be double array');

            % Verify that we get reasonable results (not all NaN)
            tc.verifyTrue(sum(~isnan(tA)) > 0, 'Should detect at least one pulse onset');
            tc.verifyTrue(sum(~isnan(tB)) > 0, 'Should detect at least one pulse offset');
            tc.verifyTrue(sum(~isnan(tM)) > 0, 'Should detect at least one pulse midpoint');
        end

        function testEmptyDetectionPoints(tc)
            [tA, tB, tM] = pulsedelineation(tc.dppg, tc.fs, []);

            % Should return NaN arrays when no detection points provided
            tc.verifyTrue(isnan(tA), 'tA should be NaN when tD is empty');
            tc.verifyTrue(isnan(tB), 'tB should be NaN when tD is empty');
            tc.verifyTrue(isnan(tM), 'tM should be NaN when tD is empty');
        end

        function testNargoutOptimization(tc)
            % Test with nargout = 1 (only tA)
            tA = pulsedelineation(tc.ppg, tc.fs, tc.tD);
            tc.verifyClass(tA, 'double', 'tA should be double array');
            tc.verifyTrue(sum(~isnan(tA)) > 0, 'Should detect at least one pulse onset');

            % Test with nargout = 2 (tA and tB)
            [tA, tB] = pulsedelineation(tc.ppg, tc.fs, tc.tD);
            tc.verifyClass(tA, 'double', 'tA should be double array');
            tc.verifyClass(tB, 'double', 'tB should be double array');
            tc.verifyTrue(sum(~isnan(tA)) > 0, 'Should detect at least one pulse onset');
            tc.verifyTrue(sum(~isnan(tB)) > 0, 'Should detect at least one pulse offset');
        end
    end
end
