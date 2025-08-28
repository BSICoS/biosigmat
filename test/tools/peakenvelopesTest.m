% Tests covering:
%   - Basic functionality with modulated sine wave
%   - NaN handling
%   - mindist parameter functionality

classdef peakenvelopesTest < matlab.unittest.TestCase

    properties
        signal
    end

    methods (TestClassSetup)
        function addToPath(~)
            addpath(fullfile(pwd, 'src'));
            addpath(fullfile(pwd, 'src', 'tools'));
        end

        function setupTestSignal(tc)
            % Initialize test signal (modulated sine wave)
            t = 0:0.001:2;
            tc.signal = (sin(2*pi*5*t) .* (1 + 0.5*sin(2*pi*0.5*t)))';
        end
    end

    methods (Test)
        function testBasicFunctionality(tc)
            [upper, lower, amplitude] = peakenvelopes(tc.signal);

            % Verify outputs are same length as input
            tc.verifyEqual(length(upper), length(tc.signal));
            tc.verifyEqual(length(lower), length(tc.signal));
            tc.verifyEqual(length(amplitude), length(tc.signal));

            % Verify upper and lower envelopes don't cross
            validIndices = ~isnan(upper) & ~isnan(lower);
            tc.verifyTrue(all(upper(validIndices) >= lower(validIndices)), ...
                'Upper envelope should always be >= lower envelope');

            % Verify amplitude is always positive where defined
            validAmplitudeIndices = ~isnan(amplitude);
            tc.verifyTrue(all(amplitude(validAmplitudeIndices) >= 0), ...
                'Amplitude should always be non-negative');
        end

        function testNanHandling(tc)
            signalWithNans = tc.signal;
            signalWithNans([50, 100, 150]) = NaN;

            [upper, lower, amplitude] = peakenvelopes(signalWithNans);

            % Verify NaNs in signal correspond to NaNs in outputs
            nanSignalIndices = isnan(signalWithNans);
            tc.verifyTrue(all(isnan(upper(nanSignalIndices))), ...
                'Upper envelope should have NaNs where signal has NaNs');
            tc.verifyTrue(all(isnan(lower(nanSignalIndices))), ...
                'Lower envelope should have NaNs where signal has NaNs');
            tc.verifyTrue(all(isnan(amplitude(nanSignalIndices))), ...
                'Amplitude should have NaNs where signal has NaNs');
        end

        function testMindistParameter(tc)
            % Extract envelopes with default mindist (0)
            [upper1, lower1] = peakenvelopes(tc.signal);

            % Extract envelopes with larger mindist
            mindist = 20;
            [upper2, lower2] = peakenvelopes(tc.signal, mindist);

            % Verify outputs are same length
            tc.verifyEqual(length(upper1), length(tc.signal));
            tc.verifyEqual(length(upper2), length(tc.signal));
            tc.verifyEqual(length(lower1), length(tc.signal));
            tc.verifyEqual(length(lower2), length(tc.signal));
        end
    end
end