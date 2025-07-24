% Tests covering:
%   - Basic functionality with PPG signal from fixtures

classdef pulsedetectionTest < matlab.unittest.TestCase
    properties
        signal
        signalFiltered
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
            rawSignal = ppgData.sig;
            tc.fs = 1000;

            % Use only the first 30 seconds of the signal
            rawSignal = rawSignal(1:30*tc.fs);

            % Apply high-pass filter to remove baseline drift
            [b, a] = butter(4, 0.5 / (tc.fs/2), 'high');
            tc.signal = filtfilt(b, a, rawSignal);

            % Apply LPD (Low-Pass Differentiator) filter
            fpLPD = 7.8;        % Pass-band frequency (Hz)
            fcLPD = 8;          % Cut-off frequency (Hz)
            orderLPD = 100;     % Filter order (samples)

            % Generate LPD filter and apply it
            [b, delay] = lpdfilter(tc.fs, fcLPD, 'PassFreq', fpLPD, 'Order', orderLPD);
            filteredSignal = filter(b, 1, tc.signal);
            tc.signalFiltered = [filteredSignal(delay+1:end); zeros(delay, 1)];
        end
    end

    methods (Test)
        function testBasicFunctionality(tc)
            [nD, threshold] = pulsedetection(tc.signalFiltered, tc.fs);

            % Expected values (hardcoded from test run with first 30 seconds)
            expectedND = [0.4770; 1.2340; 1.9810; 2.7010; 3.3710];
            expectedNumPulses = 39;

            % Verify outputs are the correct size and type
            tc.verifyClass(nD, 'double', 'nD should be double array');
            tc.verifyClass(threshold, 'double', 'threshold should be double array');

            % Verify threshold has same length as signal
            tc.verifySize(threshold, size(tc.signalFiltered), 'Threshold size mismatch');

            % Verify number of detected pulses
            numDetectedPulses = sum(~isnan(nD));
            tc.verifyEqual(numDetectedPulses, expectedNumPulses, ...
                'Number of detected pulses does not match expected value');

            % Verify first 5 values (with tolerance for numerical precision)
            tolerance = 1e-3;

            actualND = nD(~isnan(nD));
            tc.verifyEqual(actualND(1:5), expectedND, 'AbsTol', tolerance, ...
                'First 5 nD values do not match expected values');
        end
    end
end
