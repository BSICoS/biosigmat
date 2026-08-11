% Tests covering:
%   - Shared hrv.osp conformance cases
%   - Fixture-based decomposition of the HRV modulating signal
%   - MATLAB-specific coverage of NaN handling in the respiration signal

classdef ospTest < matlab.unittest.TestCase

    properties (TestParameter)
        caseId = getBiosiglibConformanceCaseIds('hrv.osp')
    end

    properties
        tk
        respTime
        respSignal
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
            respData = readtable('../../fixtures/ecg/medicom_mtd_ecg_respiration.csv');

            tc.tk = tkData.r_wave_times(1:100);
            tc.respTime = respData.time;
            tc.respSignal = respData.respiration;
            tc.fs = 4;
        end
    end

    methods (Test)
        function testBiosiglibConformanceCase(tc, caseId)
            caseDefinition = loadBiosiglibConformanceCase(caseId);

            if isfield(caseDefinition, 'expected_error')
                verifyBiosiglibExpectedError(tc, ...
                    @() executeBiosiglibOspCase(caseDefinition), ...
                    caseDefinition);
                return;
            end

            outputs = executeBiosiglibOspCase(caseDefinition);
            verifyBiosiglibExpectedOutputs(tc, outputs, caseDefinition);
        end

        function testFixtureBasedDecompositionReconstructsDelayedSignal(tc)
            [~, m] = ipfm(tc.tk, tc.fs);
            tm = (tc.tk(1):1/tc.fs:tc.tk(end))';
            resp = interp1(tc.respTime, detrend(tc.respSignal), tm, 'pchip');
            windowLength = min(256, length(resp));
            [respPxx, f] = pwelch(resp, hamming(windowLength), floor(windowLength / 2), [], tc.fs);

            [mResp, mUnrelated, delay] = osp(m, resp, respPxx, f, tc.fs);

            tc.verifyEqual(length(mResp), length(m(delay:end)), ...
                'The respiratory component should match the delayed signal length.');
            tc.verifyEqual(length(mUnrelated), length(m(delay:end)), ...
                'The unrelated component should match the delayed signal length.');
            tc.verifyEqual(mResp + mUnrelated, m(delay:end), 'AbsTol', 1e-10, ...
                'The decomposition should reconstruct the delayed modulating signal.');

            v = hankel(resp(1:delay), resp(delay:end));
            v = v';
            relativeProjection = norm(v' * mUnrelated) / max(norm(v' * m(delay:end)), eps);
            tc.verifyLessThan(relativeProjection, 1e-8, ...
                'The residual should be approximately orthogonal to the respiratory subspace.');
        end

        function testRespNanReturnsEmptyOutputs(tc)
            [~, m] = ipfm(tc.tk, tc.fs);
            tm = (tc.tk(1):1/tc.fs:tc.tk(end))';
            resp = interp1(tc.respTime, detrend(tc.respSignal), tm, 'pchip');
            windowLength = min(256, length(resp));
            [respPxx, f] = pwelch(resp, hamming(windowLength), floor(windowLength / 2), [], tc.fs);

            respWithNan = resp;
            respWithNan(7) = nan;
            [mRespFromResp, mUnrelatedFromResp, delayFromResp] = osp(m, respWithNan, respPxx, f, tc.fs);

            tc.verifyEmpty(mRespFromResp, ...
                'NaN in resp should return an empty respiratory component.');
            tc.verifyEmpty(mUnrelatedFromResp, ...
                'NaN in resp should return an empty unrelated component.');
            tc.verifyEmpty(delayFromResp, ...
                'NaN in the input signal should return an empty delay.');
        end
    end
end

function outputs = executeBiosiglibOspCase(caseDefinition)
m = loadBiosiglibConformanceInput(caseDefinition, 'm');
resp = loadBiosiglibConformanceInput(caseDefinition, 'resp');
respPxx = loadBiosiglibConformanceInput(caseDefinition, 'resp_pxx');
f = loadBiosiglibConformanceInput(caseDefinition, 'f');
fs = loadBiosiglibConformanceInput(caseDefinition, 'fs');
arguments = {};
if isfield(caseDefinition.parameters, 'min_resp_frequency')
    arguments = {'MinRespFrequency', ...
        caseDefinition.parameters.min_resp_frequency};
end

[mResp, mUnrelated, delay] = osp( ...
    m, resp, respPxx, f, fs, arguments{:});
outputs = struct( ...
    'm_resp', mResp, ...
    'm_unrelated', mUnrelated, ...
    'delay', delay);
end
