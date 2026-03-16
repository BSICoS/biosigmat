% Tests covering:
%   - Spline output evaluation against the sampled instantaneous heart rate
%   - Modulating signal computation from fixture beat occurrence times

classdef ipfmTest < matlab.unittest.TestCase

    properties
        tn
        fs
    end

    methods (TestClassSetup)
        function addCodeToPath(~)
            addpath('../../src/hrv');
        end
    end

    methods (TestMethodSetup)
        function loadFixtures(tc)
            tkData = readtable('../../fixtures/ecg/ecg_tk.csv');
            tc.tn = tkData.tk(1:100);
            tc.fs = 4;
        end
    end

    methods (Test)
        function testSplineOrderNameValueWorksWithoutFs(tc)
            sp = ipfm(tc.tn, 'SplineOrder', 10);
            tm = (tc.tn(1):1/tc.fs:tc.tn(end))';
            ihr = ipfm(tc.tn, tc.fs, 'SplineOrder', 10);
            defaultIhr = ipfm(tc.tn, tc.fs);

            tc.verifyEqual(spval(sp, tm), ihr, 'AbsTol', 1e-10, ...
                'The spline returned without fs should evaluate to the sampled IHR');
            tc.verifyFalse(isequal(ihr, defaultIhr), ...
                'Changing the spline order should modify the sampled IHR for this fixture');
        end

        function testSplineEvaluationMatchesReturnedIHR(tc)
            sp = ipfm(tc.tn);
            ihr = ipfm(tc.tn, tc.fs);
            tm = (tc.tn(1):1/tc.fs:tc.tn(end))';
            expectedIhr = spval(sp, tm);

            tc.verifySize(ihr, size(expectedIhr), ...
                'Evaluated instantaneous heart rate should match the spline output size');
            tc.verifyEqual(ihr, expectedIhr, 'AbsTol', 1e-10, ...
                'Instantaneous heart rate should equal the spline evaluated on the uniform grid');
        end

        function testModulatingSignalMatchesReferenceComputation(tc)
            [ihr, m] = ipfm(tc.tn, tc.fs, 'SplineOrder', 10);
            [bLow, aLow] = butter(4, 0.03 * 2 / tc.fs, 'low');
            lowFrequencyComponent = filtfilt(bLow, aLow, ihr);
            expectedM = (ihr - lowFrequencyComponent) ./ lowFrequencyComponent;

            tc.verifyEqual(m, expectedM, 'AbsTol', 1e-10, ...
                'Modulating signal should follow the low-frequency normalization formula');
        end
    end
end