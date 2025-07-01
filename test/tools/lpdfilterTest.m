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
        function addPathsAndData(tc)
            % Add required paths
            addpath(fullfile(pwd, '..', '..', 'src', 'ppg'));

            % Load real PPG data from fixtures
            data = readtable(fullfile(pwd, '..', '..', 'fixtures', 'ppg', 'ppg_signals.csv'));
            
            % Use 30 seconds of data
            duration = 30;
            t_orig = (0:duration*tc.fs_orig-1)'/tc.fs_orig;
            signal_orig = data.sig(1:length(t_orig));

            % Resample to the test frequency
            [tc.signal, tc.t] = resample(signal_orig, t_orig, tc.fs);
        end
    end

    methods (Test)
        function testBasicFunctionality(tc)
            % Execute function under test with default parameters
            [filteredSignal, filterCoeff] = lpdfilter(tc.signal, tc.fs);

            % Basic verifications
            tc.verifySize(filteredSignal, size(tc.signal), 'Filtered signal size mismatch');
            tc.verifyNotEqual(filteredSignal, tc.signal, 'Signal should be modified by filter');
            tc.verifyTrue(all(isfinite(filteredSignal)), 'Filtered signal should be finite');

            % Verify filter characteristics (default order is fs/2)
            expectedOrder = round(tc.fs/2);
            if mod(expectedOrder, 2) ~= 0, expectedOrder = expectedOrder + 1; end
            tc.verifyEqual(length(filterCoeff), expectedOrder + 1, ...
                'Filter length should match default order');
        end

        function testInvalidRequiredInputs(tc)
            % Test for not enough inputs
            tc.verifyError(@() lpdfilter(), 'MATLAB:narginchk:notEnoughInputs');
            tc.verifyError(@() lpdfilter(tc.signal), 'MATLAB:narginchk:notEnoughInputs');
            
            % Test with invalid signal and fs
            tc.verifyError(@() lpdfilter([], tc.fs), 'MATLAB:InputParser:ArgumentFailedValidation');
            tc.verifyError(@() lpdfilter('not-numeric', tc.fs), 'MATLAB:InputParser:ArgumentFailedValidation');
            tc.verifyError(@() lpdfilter(tc.signal, -100), 'MATLAB:InputParser:ArgumentFailedValidation');
            tc.verifyError(@() lpdfilter(tc.signal, 0), 'MATLAB:InputParser:ArgumentFailedValidation');
            tc.verifyError(@() lpdfilter(tc.signal, [100 100]), 'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function testInvalidNameValueInputs(tc)
            % Test invalid frequency parameters
            tc.verifyError(@() lpdfilter(tc.signal, tc.fs, 'PassFreq', 10, 'StopFreq', 9), 'lpdfilter:invalidFrequencies');
            tc.verifyError(@() lpdfilter(tc.signal, tc.fs, 'StopFreq', tc.fs/2), 'lpdfilter:invalidStopFreq');

            % Test invalid order
            tc.verifyError(@() lpdfilter(tc.signal, tc.fs, 'Order', 51), 'MATLAB:InputParser:ArgumentFailedValidation'); % Must be even
            tc.verifyError(@() lpdfilter(tc.signal, tc.fs, 'Order', -10), 'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function testNaNHandling(tc)
            % Setup test data with NaN values
            signalWithNaNs = tc.signal;
            nanIndices = [1, 5, 25, 45, length(signalWithNaNs)];
            signalWithNaNs(nanIndices) = NaN;
            
            % Execute function with pre-computed coefficients to test that path
            [~, coeffs] = lpdfilter(tc.signal, tc.fs);
            filteredSignal1 = lpdfilter(signalWithNaNs, tc.fs, 'Coefficients', coeffs);
            
            % Execute function without pre-computed coefficients to test that path
            filteredSignal2 = lpdfilter(signalWithNaNs, tc.fs);
            
            % Verify results are identical
            tc.verifyEqual(filteredSignal1, filteredSignal2, ...
                'Results should be identical with and without pre-computed coefficients');

            % Verify NaN positions are preserved
            tc.verifyTrue(all(isnan(filteredSignal1(nanIndices))), ...
                'NaN values should be preserved in the output');
            % Verify that other values are not NaN
            nonNanIndices = setdiff(1:length(signalWithNaNs), nanIndices);
            tc.verifyTrue(all(isfinite(filteredSignal1(nonNanIndices))), ...
                'No new NaNs should be introduced');
        end

        function testAllNaNInput(tc)
            % Create an all-NaN signal
            allNanSignal = NaN(size(tc.signal));
            
            % Execute function
            filteredSignal = lpdfilter(allNanSignal, tc.fs);
            
            % fillmissing with 'linear' on an all-NaN vector results in an all-NaN vector.
            % The subsequent filtering should also result in all-NaNs.
            tc.verifyTrue(all(isnan(filteredSignal)), 'All-NaN input should result in all-NaN output');
        end

        function testOptionalParameters(tc)
            % Test with custom parameters
            [filteredSignal1, filterCoeff1] = lpdfilter(tc.signal, tc.fs);
            [filteredSignal2, filterCoeff2] = lpdfilter(tc.signal, tc.fs, ...
                'Order', 20, 'PassFreq', 5, 'StopFreq', 10);

            % Verify results are different
            tc.verifyNotEqual(length(filterCoeff1), length(filterCoeff2), ...
                'Filter coefficients should differ with custom order');
            tc.verifyNotEqual(filteredSignal1, filteredSignal2, ...
                'Filtered signals should differ with different parameters');
        end

        function testColumnVectorOutput(tc)
            % Test row vector input
            row_signal = [1, 2, 3, 4, 5];
            filteredSignal = lpdfilter(row_signal, tc.fs);
            tc.verifySize(filteredSignal, [length(row_signal), 1], 'Output should be a column vector');
        end

        function testPreComputedCoefficients(tc)
            % Get filter coefficients from a first run
            [~, filterCoeff] = lpdfilter(tc.signal, tc.fs);

            % Filter signal using pre-computed coefficients
            filteredSignal1 = lpdfilter(tc.signal, tc.fs, 'Coefficients', filterCoeff);

            % Filter signal computing coefficients again
            filteredSignal2 = lpdfilter(tc.signal, tc.fs);

            % Results should be identical
            tc.verifyEqual(filteredSignal1, filteredSignal2, ...
                'Using pre-computed coefficients should yield identical results');
        end

        function testShortSignalHandling(tc)
            % Create a signal shorter than 3x the default filter order
            shortSignal = tc.signal(1:10); % Default order is ~50
            
            % Execute function
            filteredSignal = lpdfilter(shortSignal, tc.fs);
            
            % Verify output is valid
            tc.verifySize(filteredSignal, size(shortSignal), 'Filtered signal size mismatch for short input');
            tc.verifyTrue(all(isfinite(filteredSignal)), 'Short filtered signal should be finite');
        end

        function testNargout(tc)
            % Test for too many output arguments
            function callWithTooManyOutputs()
                [~,~,~] = lpdfilter(tc.signal, tc.fs);
            end
            tc.verifyError(@callWithTooManyOutputs, 'MATLAB:TooManyOutputs');
        end
    end
end
