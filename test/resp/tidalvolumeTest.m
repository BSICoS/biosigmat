% Tests covering:
%   - Basic functionality with modulated sine wave
%   - NaN handling
%   - mindist parameter functionality

classdef tidalvolumeTest < matlab.unittest.TestCase

    properties
        signal
    end

    methods (TestClassSetup)
        function addToPath(~)
            addpath(fullfile('..', '..', 'src', 'resp'));
        end

        function setupTestSignal(tc)
            % Initialize test signal (modulated sine wave)
            t = 0:0.001:2;
            tc.signal = (sin(2*pi*5*t) .* (1 + 0.5*sin(2*pi*0.5*t)))';
        end
    end

    methods (Test)
        function testBasicFunctionality(tc)
            [tdvol, upper, lower] = tidalvolume(tc.signal);

            % Verify outputs are same length as input
            tc.verifyEqual(length(tdvol), length(tc.signal));
            tc.verifyEqual(length(upper), length(tc.signal));
            tc.verifyEqual(length(lower), length(tc.signal));
        end

        function testNanHandling(tc)
            signalWithNans = tc.signal;
            signalWithNans([50, 100, 150]) = NaN;

            tdvolume = tidalvolume(signalWithNans);
            nanSignalIndices = isnan(signalWithNans);

            % Verify NaNs in signal correspond to NaNs in tidal volume
            tc.verifyTrue(all(isnan(tdvolume(nanSignalIndices))), ...
                'Tidal volume should have NaNs where signal has NaNs');
        end

        function testMindistParameter(tc)
            % Extract envelopes with default mindist (0)
            [~, upper1, lower1] = tidalvolume(tc.signal);

            % Extract envelopes with larger mindist
            mindist = 20;
            [~, upper2, lower2] = tidalvolume(tc.signal, mindist);

            % Verify outputs are same length
            tc.verifyEqual(length(upper1), length(tc.signal));
            tc.verifyEqual(length(upper2), length(tc.signal));
            tc.verifyEqual(length(lower1), length(tc.signal));
            tc.verifyEqual(length(lower2), length(tc.signal));
        end
    end
end