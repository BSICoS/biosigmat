% Tests covering:
%   - Shared hrv.ipfm conformance cases
%   - Spline output evaluation against the sampled instantaneous heart rate
%   - Modulating signal computation from fixture beat occurrence times

classdef ipfmTest < matlab.unittest.TestCase

    properties (TestParameter)
        caseId = getBiosiglibConformanceCaseIds('hrv.ipfm')
    end

    properties
        tn
        fs
    end

    methods (TestClassSetup)
        function addCodeToPath(tc)
            testDirectory = fileparts(mfilename('fullpath'));
            repositoryRoot = fileparts(fileparts(testDirectory));
            originalPath = path;
            tc.addTeardown(@() path(originalPath));
            addpath(fullfile(repositoryRoot, 'src', 'hrv'));
            addpath(fullfile(repositoryRoot, 'test', 'common'));
        end
    end

    methods (TestMethodSetup)
        function loadFixtures(tc)
            tkData = readtable('../../fixtures/ecg/medicom_mtd_r_wave_timing.csv');
            tc.tn = tkData.r_wave_times(1:100);
            tc.fs = 4;
        end
    end

    methods (Test)
        function testBiosiglibConformanceCase(tc, caseId)
            caseDefinition = loadBiosiglibConformanceCase(caseId);

            if isfield(caseDefinition, 'expected_error')
                verifyBiosiglibExpectedError(tc, ...
                    @() executeBiosiglibIpFmCase(caseDefinition), ...
                    caseDefinition);
                return;
            end

            outputs = executeBiosiglibIpFmCase(caseDefinition);
            verifyBiosiglibExpectedOutputs(tc, outputs, caseDefinition);
        end

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

        function testSamplingFrequencyDependsOnRequestedOutputs(tc)
            ihr = ipfm(tc.tn, 0.05);

            tc.verifyTrue(all(isfinite(ihr) & ihr > 0));
            tc.verifyError(@() requestModulatingSignal(tc.tn, 0.05), ...
                'biosigmat:ipfm:SamplingFrequency');
        end
    end
end

function outputs = executeBiosiglibIpFmCase(caseDefinition)
tn = loadBiosiglibConformanceInput(caseDefinition, 'tn');
fs = loadBiosiglibConformanceInput(caseDefinition, 'fs');
arguments = {};
if isfield(caseDefinition.parameters, 'spline_order')
    arguments = {'SplineOrder', caseDefinition.parameters.spline_order};
end

requestedOutputs = string(caseDefinition.requested_outputs);
if any(requestedOutputs == "m")
    [ihr, m] = ipfm(tn, fs, arguments{:});
    outputs = struct('ihr', ihr, 'm', m);
else
    ihr = ipfm(tn, fs, arguments{:});
    outputs = struct('ihr', ihr);
end
end

function requestModulatingSignal(tn, fs)
[~, ~] = ipfm(tn, fs);
end
