% Tests covering:
%   - Basic functionality with modulated sine wave
%   - NaN handling
%   - mindist parameter functionality

classdef tidalvolumeTest < matlab.unittest.TestCase

    properties (TestParameter)
        caseId = getBiosiglibConformanceCaseIds('resp.tidalvolume')
    end

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
        function testConformance(tc, caseId)
            c = loadBiosiglibConformanceCase(caseId);
            resp = loadBiosiglibConformanceInput(c, 'resp');
            fs = loadBiosiglibConformanceInput(c, 'sampling_frequency');
            args = {};
            if isfield(c.parameters, 'mindist')
                args = {c.parameters.mindist};
            end
            if isfield(c.parameters, 'max_gap')
                args = [args, {'MaxGap', c.parameters.max_gap}];
            end
            [v, u, l] = tidalvolume(resp, fs, args{:});
            verifyBiosiglibExpectedOutputs(tc, struct('tdvol', v, ...
                'upper_envelope', u, 'lower_envelope', l), c);
        end

        function testBasicFunctionality(tc)
            [tdvol, upper, lower] = tidalvolume(tc.signal, 1000);

            % Verify outputs are same length as input
            tc.verifyEqual(length(tdvol), length(tc.signal));
            tc.verifyEqual(length(upper), length(tc.signal));
            tc.verifyEqual(length(lower), length(tc.signal));
        end

        function testNanHandling(tc)
            signalWithNans = tc.signal;
            signalWithNans(950:970) = NaN;

            tdvolume = tidalvolume(signalWithNans, 1000);
            nanSignalIndices = isnan(signalWithNans);

            % The surrounding complete cycles support interpolation across this gap.
            tc.verifyTrue(all(isfinite(tdvolume(nanSignalIndices))), ...
                'Short gaps should be interpolated between supported cycles');
        end

        function testMindistParameter(tc)
            % Add noise to signal to trigger close zero crossings
            rng(42); % Set seed for reproducible results
            noisySignal = tc.signal + 0.1 * randn(size(tc.signal));

            % Extract envelopes with default mindist (0)
            [~, upper1, lower1] = tidalvolume(noisySignal, 1000);

            % Extract envelopes with larger mindist to filter close crossings
            mindist = 0.020;
            [~, upper2, lower2] = tidalvolume(noisySignal, 1000, mindist);

            % Verify outputs are same length
            tc.verifyEqual(length(upper1), length(noisySignal));
            tc.verifyEqual(length(upper2), length(noisySignal));
            tc.verifyEqual(length(lower1), length(noisySignal));
            tc.verifyEqual(length(lower2), length(noisySignal));

            % With mindist filtering, we expect smoother envelopes
            % (fewer extreme variations due to noise-induced close crossings)
            tc.verifyTrue(~isequaln(upper1, upper2) || ~isequaln(lower1, lower2), ...
                'Mindist parameter should affect the envelope extraction');
        end
    end
end