% Tests covering:
%   - Basic functionality with PPG signal from fixtures

classdef pulsedelineationTest < matlab.unittest.TestCase
    properties
        ppg
        dppg
        fs
        nD
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
            tc.nD = pulsedetection(tc.dppg, tc.fs);
        end
    end

    methods (Test)
        function testBasicFunctionality(tc)
            % Test with default parameters
            [nA, nB, nM] = pulsedelineation(tc.ppg, tc.fs, tc.nD);

            % Expected values
            expectedNA = [0.5805; 1.3400; 2.0684; 2.7887; 3.4662];
            expectedNB = [0.4321; 1.1918; 1.9361; 2.6565; 3.3312];
            expectedNM = [0.4850; 1.2430; 1.9880; 2.7070; 3.3790];

            % Verify outputs are the correct size and type
            tc.verifyClass(nA, 'double', 'nA should be double array');
            tc.verifyClass(nB, 'double', 'nB should be double array');
            tc.verifyClass(nM, 'double', 'nM should be double array');

            % Verify first 5 values of each output (with tolerance for numerical precision)
            tolerance = 1e-3;

            actualNA = nA(~isnan(nA));
            tc.verifyEqual(actualNA(1:5), expectedNA, 'AbsTol', tolerance, ...
                'First 5 nA values do not match expected values');

            actualNB = nB(~isnan(nB));
            tc.verifyEqual(actualNB(1:5), expectedNB, 'AbsTol', tolerance, ...
                'First 5 nB values do not match expected values');

            actualNM = nM(~isnan(nM));
            tc.verifyEqual(actualNM(1:5), expectedNM, 'AbsTol', tolerance, ...
                'First 5 nM values do not match expected values');
        end

        function testCustomParameters(tc)
            % Test with custom window parameters
            customWindowA = 300e-3;
            customWindowB = 200e-3;

            [nA, nB, nM] = pulsedelineation(tc.ppg, tc.fs, tc.nD, ...
                'WindowA', customWindowA, 'WindowB', customWindowB);

            % Verify outputs are valid
            tc.verifyClass(nA, 'double', 'nA should be double array');
            tc.verifyClass(nB, 'double', 'nB should be double array');
            tc.verifyClass(nM, 'double', 'nM should be double array');

            % Verify that we get reasonable results (not all NaN)
            tc.verifyTrue(sum(~isnan(nA)) > 0, 'Should detect at least one pulse onset');
            tc.verifyTrue(sum(~isnan(nB)) > 0, 'Should detect at least one pulse offset');
            tc.verifyTrue(sum(~isnan(nM)) > 0, 'Should detect at least one pulse midpoint');
        end

        function testEmptyDetectionPoints(tc)
            % Test with empty nD array
            [nA, nB, nM] = pulsedelineation(tc.dppg, tc.fs, []);

            % Should return NaN arrays when no detection points provided
            tc.verifyTrue(isnan(nA), 'nA should be NaN when nD is empty');
            tc.verifyTrue(isnan(nB), 'nB should be NaN when nD is empty');
            tc.verifyTrue(isnan(nM), 'nM should be NaN when nD is empty');
        end
    end
end
