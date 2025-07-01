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

        function testLpdFilterDesignAtDifferentSamplingFrequencies(tc)
            % Test LPD filter design with 8Hz cutoff at different sampling frequencies
            % This test verifies that the filter is constructed correctly for both
            % low (26Hz) and high (1000Hz) sampling frequencies
            
            % Test parameters
            fs_low = 26;    % Low sampling frequency
            fs_high = 1000; % High sampling frequency
            
            % Create test signals at different sampling rates
            duration = 5; % seconds
            t_low = (0:1/fs_low:duration-1/fs_low)';
            t_high = (0:1/fs_high:duration-1/fs_high)';
            
            % Simple test signal: sum of sinusoids at different frequencies
            freq1 = 3; % Below cutoff
            freq2 = 15; % Above cutoff
            signal_low = sin(2*pi*freq1*t_low) + 0.5*sin(2*pi*freq2*t_low);
            signal_high = sin(2*pi*freq1*t_high) + 0.5*sin(2*pi*freq2*t_high);
            
            % Design filters with 8Hz cutoff frequency
            % For low fs: use PassFreq=7, StopFreq=9 (centered around 8Hz)
            % For high fs: use PassFreq=7.5, StopFreq=8.5 (centered around 8Hz)
            [~, coeff_low] = lpdfilter(signal_low, fs_low, ...
                'PassFreq', 7, 'StopFreq', 9, 'Order', 20);
            [~, coeff_high] = lpdfilter(signal_high, fs_high, ...
                'PassFreq', 7.5, 'StopFreq', 8.5, 'Order', 100);
            
            % Verify filter coefficients are valid
            tc.verifyTrue(all(isfinite(coeff_low)), ...
                'Low fs filter coefficients should be finite');
            tc.verifyTrue(all(isfinite(coeff_high)), ...
                'High fs filter coefficients should be finite');
            
            % Verify filter lengths match expected orders
            tc.verifyEqual(length(coeff_low), 21, ...
                'Low fs filter should have 21 coefficients (order 20 + 1)');
            tc.verifyEqual(length(coeff_high), 101, ...
                'High fs filter should have 101 coefficients (order 100 + 1)');
            
            % Test frequency response characteristics
            [h_low, w_low] = freqz(coeff_low, 1, 512);
            [h_high, w_high] = freqz(coeff_high, 1, 512);
            
            f_low = w_low * fs_low / (2*pi);
            f_high = w_high * fs_high / (2*pi);
            
            % Verify that the derivative nature of the filter is preserved
            % LPD filters should have near-zero DC response
            dc_response_low = abs(h_low(1));
            dc_response_high = abs(h_high(1));
            
            tc.verifyLessThan(dc_response_low, 0.1*max(abs(h_low)), ...
                'Low fs LPD filter should have low DC response');
            tc.verifyLessThan(dc_response_high, 0.1*max(abs(h_high)), ...
                'High fs LPD filter should have low DC response');
            
            % Find frequency response at passband frequencies
            % For low fs filter (PassFreq=7Hz)
            [~, idx_pass_low] = min(abs(f_low - 7));
            
            % For high fs filter (PassFreq=7.5Hz)
            [~, idx_pass_high] = min(abs(f_high - 7.5));
            
            % Verify that passband has higher response than stopband
            % (accounting for the derivative nature which enhances mid-frequencies)
            passband_response_low = abs(h_low(idx_pass_low));
            passband_response_high = abs(h_high(idx_pass_high));
            
            % For LPD filters, the response should be significant at the passband frequency
            tc.verifyGreaterThan(passband_response_low, 0.05*max(abs(h_low)), ...
                'Low fs filter should have significant response at passband frequency');
            tc.verifyGreaterThan(passband_response_high, 0.05*max(abs(h_high)), ...
                'High fs filter should have significant response at passband frequency');
            
            % Verify the filters have been designed (non-zero coefficients)
            tc.verifyGreaterThan(max(abs(coeff_low)), 0, ...
                'Low fs filter should have non-zero coefficients');
            tc.verifyGreaterThan(max(abs(coeff_high)), 0, ...
                'High fs filter should have non-zero coefficients');
            
            % Test that the scaling factor (fs/(2*pi)) has been applied correctly
            % The maximum coefficient magnitude should be reasonable for the sampling frequency
            max_coeff_low = max(abs(coeff_low));
            max_coeff_high = max(abs(coeff_high));
            
            tc.verifyGreaterThan(max_coeff_low, fs_low/(2*pi)/1000, ...
                'Low fs filter coefficients should reflect proper scaling');
            tc.verifyGreaterThan(max_coeff_high, fs_high/(2*pi)/1000, ...
                'High fs filter coefficients should reflect proper scaling');
        end
    end
end
