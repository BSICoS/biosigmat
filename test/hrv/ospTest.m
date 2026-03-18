% Tests covering:
%   - Fixture-based decomposition of the HRV modulating signal
%   - Short-signal handling when the estimated model order exceeds the data length

classdef ospTest < matlab.unittest.TestCase

    properties
        tk
        respTime
        respSignal
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
            respData = readtable('../../fixtures/ecg/edr_signals.csv');

            tc.tk = tkData.tk(1:100);
            tc.respTime = respData.t;
            tc.respSignal = respData.resp;
            tc.fs = 4;
        end
    end

    methods (Test)
        function testFixtureBasedDecompositionReconstructsDelayedSignal(tc)
            [~, m] = ipfm(tc.tk, tc.fs);
            tm = (tc.tk(1):1/tc.fs:tc.tk(end))';
            resp = interp1(tc.respTime, detrend(tc.respSignal), tm, 'pchip');
            windowLength = min(256, length(resp));
            [respPxx, f] = pwelch(resp, hamming(windowLength), floor(windowLength / 2), [], tc.fs);

            [mResp, mUnrelated, delay] = osp(resp, respPxx, f, m, tc.fs);

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

        function testShortSignalsReturnNanOutputs(tc)
            [~, m] = ipfm(tc.tk, tc.fs);
            tm = (tc.tk(1):1/tc.fs:tc.tk(end))';
            resp = interp1(tc.respTime, detrend(tc.respSignal), tm, 'pchip');

            shortResp = resp(1:8);
            shortM = m(1:8);
            f = (0:0.1:tc.fs / 2)';
            respPxx = zeros(size(f));
            respPxx(2) = 1;

            [mResp, mUnrelated, delay] = osp(shortResp, respPxx, f, shortM, tc.fs);

            tc.verifyTrue(isnan(mResp), ...
                'Short signals should return NaN for the respiratory component.');
            tc.verifyTrue(isnan(mUnrelated), ...
                'Short signals should return NaN for the unrelated component.');
            tc.verifyGreaterThan(delay, length(shortResp), ...
                'The estimated delay should exceed the available data length in this scenario.');
        end
    end
end