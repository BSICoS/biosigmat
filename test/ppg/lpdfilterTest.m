% Tests covering:
%   - Basic functionality
%   - Input validation (required and name-value pairs)
%   - NaN handling
%   - Optional parameter handling (coefficients, order, frequencies)
%   - Output format consistency
classdef lpdfilterTest < matlab.unittest.TestCase

    properties
        fs = 100; % Common sampling frequency for tests
        fs_orig = 1000; % Original sampling frequency of the fixture
        signal;
        t;
    end

    methods (TestClassSetup)
        function addPathsAndData(testCase)
            % Add required paths
            addpath(fullfile(pwd, '..', '..', 'src', 'ppg'));

            % Load real PPG data from fixtures
            data = readtable(fullfile(pwd, '..', '..', 'fixtures', 'ppg', 'ppg_signals.csv'));
            
            % Use 30 seconds of data
            duration = 30;
            t_orig = (0:duration*testCase.fs_orig-1)'/testCase.fs_orig;
            signal_orig = data.sig(1:length(t_orig));

            % Resample to the test frequency
            [testCase.signal, testCase.t] = resample(signal_orig, t_orig, testCase.fs);
        end
    end

    methods (Test)
        function testBasicFunctionality(testCase)
            % Execute function under test with default parameters
            [filteredSignal, filterCoeff] = lpdfilter(testCase.signal, testCase.fs);

            % Basic verifications
            testCase.verifySize(filteredSignal, size(testCase.signal), 'Filtered signal size mismatch');
            testCase.verifyNotEqual(filteredSignal, testCase.signal, 'Signal should be modified by filter');
            testCase.verifyTrue(all(isfinite(filteredSignal)), 'Filtered signal should be finite');

            % Verify filter characteristics (default order is fs/2)
            expectedOrder = round(testCase.fs/2);
            if mod(expectedOrder, 2) ~= 0, expectedOrder = expectedOrder + 1; end
            testCase.verifyEqual(length(filterCoeff), expectedOrder + 1, ...
                'Filter length should match default order');
        end

        function testInvalidRequiredInputs(testCase)
            % Test with invalid signal and fs
            testCase.verifyError(@() lpdfilter([], testCase.fs), 'MATLAB:InputParser:ArgumentFailedValidation');
            testCase.verifyError(@() lpdfilter('not-numeric', testCase.fs), 'MATLAB:InputParser:ArgumentFailedValidation');
            testCase.verifyError(@() lpdfilter(testCase.signal, -100), 'MATLAB:InputParser:ArgumentFailedValidation');
            testCase.verifyError(@() lpdfilter(testCase.signal, 0), 'MATLAB:InputParser:ArgumentFailedValidation');
            testCase.verifyError(@() lpdfilter(testCase.signal, [100 100]), 'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function testInvalidNameValueInputs(testCase)
            % Test invalid frequency parameters
            testCase.verifyError(@() lpdfilter(testCase.signal, testCase.fs, 'PassFreq', 10, 'StopFreq', 9), 'lpdfilter:invalidFrequencies');
            testCase.verifyError(@() lpdfilter(testCase.signal, testCase.fs, 'StopFreq', testCase.fs/2), 'lpdfilter:invalidStopFreq');

            % Test invalid order
            testCase.verifyError(@() lpdfilter(testCase.signal, testCase.fs, 'Order', 51), 'MATLAB:InputParser:ArgumentFailedValidation'); % Must be even
            testCase.verifyError(@() lpdfilter(testCase.signal, testCase.fs, 'Order', -10), 'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function testNaNHandling(testCase)
            % Setup test data with NaN values
            signalWithNaNs = testCase.signal;
            nanIndices = [5, 25, 45];
            signalWithNaNs(nanIndices) = NaN;

            % Execute function
            filteredSignal = lpdfilter(signalWithNaNs, testCase.fs);

            % Verify NaN positions are preserved
            testCase.verifyTrue(all(isnan(filteredSignal(nanIndices))), ...
                'NaN values should be preserved in the output');
            testCase.verifyFalse(any(isnan(filteredSignal(setdiff(1:length(testCase.signal), nanIndices)))), ...
                'No new NaNs should be introduced');
        end

        function testOptionalParameters(testCase)
            % Test with custom parameters
            [filteredSignal1, filterCoeff1] = lpdfilter(testCase.signal, testCase.fs);
            [filteredSignal2, filterCoeff2] = lpdfilter(testCase.signal, testCase.fs, ...
                'Order', 20, 'PassFreq', 5, 'StopFreq', 10);

            % Verify results are different
            testCase.verifyNotEqual(length(filterCoeff1), length(filterCoeff2), ...
                'Filter coefficients should differ with custom order');
            testCase.verifyNotEqual(filteredSignal1, filteredSignal2, ...
                'Filtered signals should differ with different parameters');
        end

        function testColumnVectorOutput(testCase)
            % Test row vector input
            row_signal = [1, 2, 3, 4, 5];
            filteredSignal = lpdfilter(row_signal, testCase.fs);
            testCase.verifySize(filteredSignal, [length(row_signal), 1], 'Output should be a column vector');
        end

        function testPreComputedCoefficients(testCase)
            % Get filter coefficients from a first run
            [~, filterCoeff] = lpdfilter(testCase.signal, testCase.fs);

            % Filter signal using pre-computed coefficients
            filteredSignal1 = lpdfilter(testCase.signal, testCase.fs, 'Coefficients', filterCoeff);

            % Filter signal computing coefficients again
            filteredSignal2 = lpdfilter(testCase.signal, testCase.fs);

            % Results should be identical
            testCase.verifyEqual(filteredSignal1, filteredSignal2, ...
                'Using pre-computed coefficients should yield identical results');
        end
    end
end
