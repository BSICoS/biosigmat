% Tests covering:
%   - Basic functionality with default adaptive algorithm
%   - Algorithm parameter validation
%   - Future: Multiple algorithm support

classdef pulsedetectionTest < matlab.unittest.TestCase
    properties (TestParameter)
        caseId = getBiosiglibConformanceCaseIds('ppg.pulsedetection')
    end

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
        function testConformance(tc, caseId)
            c = loadBiosiglibConformanceCase(caseId);
            signal = loadBiosiglibConformanceInput(c, 'dppg');
            fs = loadBiosiglibConformanceInput(c, 'sampling_frequency');
            names = {'method', 'adaptive_alpha_amp', 'adaptive_refract_period', ...
                'adaptive_tau_rr', 'reset_after'};
            matlabNames = {'Method', 'AdaptiveAlphaAmp', 'AdaptiveRefractPeriod', ...
                'AdaptiveTauRR', 'ResetAfter'};
            args = {};
            for k = 1:numel(names)
                if isfield(c.parameters, names{k})
                    value = c.parameters.(names{k});
                    if strcmp(names{k}, 'reset_after') && isempty(value)
                        value = Inf;
                    end
                    args = [args, {matlabNames{k}, value}]; %#ok<AGROW>
                end
            end
            [tD, threshold] = pulsedetection(signal, fs, args{:});
            actual = struct('t_d', tD, 'threshold', threshold);
            verifyBiosiglibExpectedOutputs(tc, actual, c);
        end

        function testBasicFunctionality(tc)
            [tD, threshold] = pulsedetection(tc.signalFiltered, tc.fs);

            % Expected values (hardcoded from test run with first 30 seconds)
            expectedTD = [0.4770; 1.2350; 1.9810; 2.7010; 3.3720];
            expectedNumPulses = 41;

            % Verify outputs are the correct size and type
            tc.verifyClass(tD, 'double', 'tD should be double array');
            tc.verifyClass(threshold, 'double', 'threshold should be double array');

            % Verify threshold has same length as signal
            tc.verifySize(threshold, size(tc.signalFiltered), 'Threshold size mismatch');

            % Verify number of detected pulses
            numDetectedPulses = sum(~isnan(tD));
            tc.verifyEqual(numDetectedPulses, expectedNumPulses, ...
                'Number of detected pulses does not match expected value');

            % Verify first 5 values (with tolerance for numerical precision)
            tolerance = 1e-3;

            actualTD = tD(~isnan(tD));
            tc.verifyEqual(actualTD(1:5), expectedTD, 'AbsTol', tolerance, ...
                'First 5 tD values do not match expected values');
        end

        function testAdaptiveMethodExplicit(tc)
            % Test explicit specification of adaptive method
            [tD1, threshold1] = pulsedetection(tc.signalFiltered, tc.fs);
            [tD2, threshold2] = pulsedetection(tc.signalFiltered, tc.fs, 'Method', 'adaptive');

            % Results should be identical
            tc.verifyEqual(tD1, tD2, 'Results with implicit and explicit adaptive method should match');
            tc.verifyEqual(threshold1, threshold2, 'Thresholds with implicit and explicit adaptive method should match');
        end

        function testAdaptiveParameters(tc)
            % Test with custom adaptive parameters
            [tD, threshold] = pulsedetection(tc.signalFiltered, tc.fs, ...
                'AdaptiveAlphaAmp', 0.3, 'AdaptiveRefractPeriod', 0.2, 'AdaptiveTauRR', 1.5);

            % Verify outputs are valid
            tc.verifyClass(tD, 'double', 'tD should be double array');
            tc.verifyClass(threshold, 'double', 'threshold should be double array');
            tc.verifySize(threshold, size(tc.signalFiltered), 'Threshold size mismatch');

            % Should detect some pulses
            numDetectedPulses = sum(~isnan(tD));
            tc.verifyGreaterThan(numDetectedPulses, 0, 'Should detect at least one pulse');
        end

        function testInvalidMethod(tc)
            % Test error handling for invalid method
            tc.verifyError(@() pulsedetection(tc.signalFiltered, tc.fs, 'Method', 'invalid'), ...
                'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Should error with invalid method');
        end

        function testNarrowPeakAtThresholdCrossing(tc)
            [tD, threshold] = pulsedetection([0; 0; 1; 0; 0], 10);
            tc.verifyEqual(tD, 0.2, 'AbsTol', 1e-14);
            tc.verifySize(threshold, [5, 1]);
        end

        function testDefaultResetIsDisabled(tc)
            [defaultTimes, defaultThreshold] = pulsedetection(tc.signalFiltered, tc.fs);
            [explicitTimes, explicitThreshold] = pulsedetection(tc.signalFiltered, tc.fs, 'ResetAfter', Inf);
            tc.verifyEqual(defaultTimes, explicitTimes);
            tc.verifyEqual(defaultThreshold, explicitThreshold);
        end

        function testLongerSignalPreservesEarlierAdaptiveState(tc)
            [shortTimes, shortThreshold] = pulsedetection(tc.signalFiltered, tc.fs);
            [longTimes, longThreshold] = pulsedetection(repmat(tc.signalFiltered, 3, 1), tc.fs);
            tc.verifyEqual(longTimes(longTimes < 25), shortTimes(shortTimes < 25));
            tc.verifyEqual(longThreshold(1:25*tc.fs), shortThreshold(1:25*tc.fs));
        end

        function testResetRecoversAfterGapAndAmplitudeDrop(tc)
            cycle = [zeros(40,1); 0; 1; 3; 5; 3; 1; 0; zeros(53,1)];
            signal = repmat(cycle, 20, 1);
            signal(601:1100) = NaN;
            signal(1101:end) = 0.05*signal(1101:end);
            tDWithoutReset = pulsedetection(signal, 100);
            tDWithReset = pulsedetection(signal, 100, 'ResetAfter', 2);
            tc.verifyFalse(any(tDWithoutReset > 11));
            tc.verifyEqual(tDWithReset(tDWithReset > 11), (11.43:1:19.43).', 'AbsTol', 1e-12);
            tc.verifyFalse(any(tDWithReset >= 6 & tDWithReset < 11));
        end

        function testResetRecoversWithoutExplicitNanGap(tc)
            cycle = [zeros(40,1); 0; 1; 3; 5; 3; 1; 0; zeros(53,1)];
            signal = repmat(cycle, 20, 1);
            signal(601:end) = 0.05*signal(601:end);
            tDWithoutReset = pulsedetection(signal, 100);
            tDWithReset = pulsedetection(signal, 100, 'ResetAfter', 2);
            tc.verifyFalse(any(tDWithoutReset >= 6));
            tc.verifyTrue(any(tDWithReset > 8));
        end

        function testLongSignalAtHighSamplingFrequency(tc)
            [tD, threshold] = pulsedetection(zeros(10001,1), 2500);
            tc.verifyEmpty(tD);
            tc.verifyEqual(threshold, zeros(10001,1));
        end

        function testAllMissingSignal(tc)
            [tD, threshold] = pulsedetection(nan(50,1), 100);
            tc.verifyEmpty(tD);
            tc.verifyTrue(all(isnan(threshold)));
        end

        % TODO: Add tests for future algorithms
    end
end
