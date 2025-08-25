% Tests covering:
%   - Basic functionality with PPG signal from fixtures

classdef pulsedelineationTest < matlab.unittest.TestCase
    properties
        signal
        signalFiltered
        fs
        Setup
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
            tc.signal = filtfilt(b, a, rawSignal);

            % Apply LPD (Low-Pass Differentiator) filter
            fpLPD = 7.8;        % Pass-band frequency (Hz)
            fcLPD = 8;          % Cut-off frequency (Hz)
            orderLPD = 100;     % Filter order (samples)

            [b, delay] = lpdfilter(tc.fs, fcLPD, 'PassFreq', fpLPD, 'Order', orderLPD);
            filteredSignal = filter(b, 1, tc.signal);
            tc.signalFiltered = [filteredSignal(delay+1:end); zeros(delay, 1)];

            % Compute pulse detection points
            nD = pulsedetection(tc.signalFiltered, tc.fs);

            % Set up pulse delineation parameters
            tc.Setup = struct();
            tc.Setup.wdw_nA = 250e-3;              % Window for onset detection (s)
            tc.Setup.wdw_nB = 150e-3;              % Window for offset detection (s)
            tc.Setup.nD = nD;                       % Pulse detection points
        end
    end

    methods (Test)
        function testBasicFunctionality(tc)
            [nA, nB, nM] = pulsedelineation(tc.signalFiltered, tc.fs, tc.Setup);

            % Expected values (hardcoded from test run with first 30 seconds)
            expectedNA = [0.4775; 1.2350; 1.9815; 2.7015; 3.3720];
            expectedNB = [0.4085; 1.1645; 1.9110; 2.6335; 3.3035];
            expectedNM = [0.4445; 1.2030; 1.9490; 2.6690; 3.3400];

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
    end
end
