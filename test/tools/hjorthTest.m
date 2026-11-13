% Tests covering:
%   - Synthetic signal without NaNs
%   - Signal with NaNs

classdef hjorthTest < matlab.unittest.TestCase

    properties (TestParameter)
        caseId = getBiosiglibConformanceCaseIds('tools.hjorth')
    end

    methods (TestClassSetup)
        function addCodeToPath(~)
            root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            addpath(fullfile(root, 'src', 'tools'));
            addpath(fullfile(root, 'test', 'common'));
        end
    end

    methods (Test)
        function testConformance(tc, caseId)
            c = loadBiosiglibConformanceCase(caseId);
            x = loadBiosiglibConformanceInput(c, 'signal');
            fs = loadBiosiglibConformanceInput(c, 'sampling_frequency');
            if isfield(c, 'expected_error')
                verifyBiosiglibExpectedError(tc, @() hjorth(x, fs), c);
                return;
            end
            [h0, h1, h2] = hjorth(x, fs);
            actual = struct('activity', h0, 'mobility', h1, 'complexity', h2);
            verifyBiosiglibExpectedOutputs(tc, actual, c);
        end

        function testIntegerInputs(tc)
            [h0, h1, h2] = hjorth(uint8([2, 1, 0]), uint16(1000));
            [a, b, c] = hjorth([2, 1, 0], 1000);
            tc.verifyEqual([h0, h1, h2], [a, b, c]);
        end

        function testBasicFunctionality(tc)
            fs = 1000;
            t = 0:1/fs:1;
            x = sin(2*pi*10*t) + randn(size(t))*0.1;

            [h0, h1, h2] = hjorth(x, fs);

            % Verify that all outputs are numeric and finite
            tc.verifyTrue(isnumeric(h0) && isfinite(h0), 'H0 should be numeric and finite');
            tc.verifyTrue(isnumeric(h1) && isfinite(h1), 'H1 should be numeric and finite');
            tc.verifyTrue(isnumeric(h2) && isfinite(h2), 'H2 should be numeric and finite');

            % Verify that all outputs are positive (Hjorth parameters should be positive)
            tc.verifyTrue(h0 > 0, 'H0 (activity) should be positive');
            tc.verifyTrue(h1 > 0, 'H1 (mobility) should be positive');
            tc.verifyTrue(h2 > 0, 'H2 (complexity) should be positive');
        end

        function testSignalWithNans(tc)
            fs = 1000;
            t = 0:1/fs:1;
            x = sin(2*pi*10*t) + randn(size(t))*0.1;

            % Introduce some NaNs
            x(100:200) = NaN;
            x(500:600) = NaN;

            [h0, h1, h2] = hjorth(x, fs);

            % Verify that all outputs are NaN
            tc.verifyTrue(isnan(h0), 'H0 should be NaN when signal contains NaNs');
            tc.verifyTrue(isnan(h1), 'H1 should be NaN when signal contains NaNs');
            tc.verifyTrue(isnan(h2), 'H2 should be NaN when signal contains NaNs');
        end
    end
end
