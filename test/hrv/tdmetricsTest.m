% Tests covering:
%   - Placeholder test for tdmetrics function

classdef tdmetricsTest < matlab.unittest.TestCase

    properties
        dtk
    end

    methods (TestClassSetup)
        function addCodeToPath(~)
            addpath('../../src/hrv');
        end
    end

    methods (TestMethodSetup)
        function loadFixtures(tc)
            tkData = readtable('../../fixtures/ecg/ecg_tk.csv');
            tk = tkData.tk;
            tc.dtk = diff(tk);
        end
    end

    methods (Test)
        function testBasicFuntionality(tc)
            Output = tdmetrics(tc.dtk);

            % Verify metrics match expected results
            tc.verifyEqual(Output.mhr, 85.34, 'AbsTol', 0.01, 'Mean heart rate mismatch');
            tc.verifyEqual(Output.sdnn, 40.26, 'AbsTol', 0.01, 'SDNN mismatch');
            tc.verifyEqual(Output.sdsd, 18.62, 'AbsTol', 0.01, 'SDSD mismatch');
            tc.verifyEqual(Output.rmssd, 18.55, 'AbsTol', 0.01, 'RMSSD mismatch');
            tc.verifyEqual(Output.pNN50, 1.47, 'AbsTol', 0.01, 'pNN50 mismatch');
        end
    end
end
