classdef NanFilterTestBase < matlab.unittest.TestCase
    % NANFILTERTESTBASE Base class for nanfilter and nanfiltfilt tests
    %
    % This class contains common test methods and utilities for both nanfilter
    % and nanfiltfilt functions, following the DRY principle.

    properties
        b
        a
        x
    end

    methods (TestClassSetup)
        function addCodeToPath(~)
            addpath('../../src/tools');
        end
    end

    methods (TestMethodSetup)
        function createTestData(tc)
            [tc.b, tc.a] = butter(2, 0.5);
            tc.x = 1:40;
            tc.x = tc.x(:);
        end
    end

    methods (Access = protected)
        function verifyNoNaNSignal(tc, filterFunc, standardFunc)
            y = filterFunc(tc.b, tc.a, tc.x);
            expected = standardFunc(tc.b, tc.a, tc.x);

            tc.verifyEqual(y, expected, 'Basic filtering failed');
        end

        function verifyShortNanGaps(tc, filterFunc)
            tc.x(10) = NaN;
            tc.x(20:21) = NaN;
            maxgap = 3;

            y = filterFunc(tc.b, tc.a, tc.x, maxgap);

            tc.verifyTrue(all(~isnan(y)), 'Short NaN gaps should be interpolated');
        end

        function verifyLongNanGaps(tc, filterFunc)
            tc.x(20:24) = NaN;
            maxgap = 3;

            y = filterFunc(tc.b, tc.a, tc.x, maxgap);

            tc.verifyEqual(sum(isnan(y)), 5, 'Number of NaN values should be preserved');
        end

        function verifyMixedNanGaps(tc, filterFunc)
            tc.x(10) = NaN;
            tc.x(20:24) = NaN;
            maxgap = 3;

            y = filterFunc(tc.b, tc.a, tc.x, maxgap);

            tc.verifyEqual(sum(isnan(y)), 5, 'Long NaN gaps should be preserved while short gaps are filled');
        end

        function verifyAllNanInput(tc, filterFunc)
            xNaN = NaN(10, 1);
            y = filterFunc(tc.b, tc.a, xNaN);

            tc.verifyTrue(all(isnan(y)), 'All NaN input should return all NaN');
            tc.verifyEqual(size(y), size(xNaN), 'Output size should match input size');
        end

        function verifyEmptyInput(tc, filterFunc)
            y = filterFunc(tc.b, tc.a, []);
            tc.verifyEmpty(y, 'Empty input should return empty output');
        end

        function verifyInsufficientInputs(tc, filterFunc)
            f = @() filterFunc(tc.b, tc.a);
            tc.verifyError(f, 'MATLAB:narginchk:notEnoughInputs', 'Insufficient inputs did not throw expected error');
        end

        function verifyRowVectorInput(tc, filterFunc)
            tc.x(3) = NaN;
            tc.x = tc.x.';
            maxgap = 10;

            y = filterFunc(tc.b, tc.a, tc.x, maxgap);

            tc.verifyTrue(all(~isnan(y)), 'Row vector with short NaN gap should be processed correctly');
            tc.verifyEqual(size(y), size(tc.x), 'Output size should match input size');
        end

        function verifyMultiColumnWithNans(tc, filterFunc)
            numCols = 3;
            maxgap = 3;
            signalMat = repmat(tc.x, 1, numCols);
            signalMat(15:17, :) = NaN;
            signalMat(70:80, :) = NaN;
            filteredBurstsMat = filterFunc(tc.b, tc.a, signalMat, maxgap);
            tc.verifyTrue(all(isnan(filteredBurstsMat(70:80,:)), 'all'), 'Multi-column bursts: large NaN bursts not preserved');
            tc.verifyFalse(any(isnan(filteredBurstsMat(15:17,:)), 'all'), 'Multi-column bursts: small NaN bursts not interpolated');
        end

        function verifyMultiColumnAllNaNSignal(tc, filterFunc)
            numCols = 3;
            signalMat = NaN(10, numCols);
            filteredMat = filterFunc(tc.b, tc.a, signalMat);

            tc.verifyTrue(all(isnan(filteredMat), 'all'), 'Multi-column all NaN input should return all NaN');
            tc.verifyEqual(size(filteredMat), size(signalMat), 'Output size should match input size');
        end

        function verifyMultiColumnNoNaNSignal(tc, filterFunc, standardFunc)
            numCols = 3;
            signalMat = repmat(tc.x, 1, numCols);
            filteredMat = filterFunc(tc.b, tc.a, signalMat);
            expectedMat = standardFunc(tc.b, tc.a, signalMat);

            tc.verifyEqual(filteredMat, expectedMat, 'Multi-column filtering failed', 'AbsTol', 1e-6);
        end
    end

end
