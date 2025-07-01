% Tests covering:
%   - Basic functionality
%   - Input validation (required and name-value pairs)
%   - NaN handling
%   - Optional parameter handling (coefficients, order, frequencies)
%   - Output format consistency
classdef lpdfilterTest < matlab.unittest.TestCase

    properties
        fs = 100; % Common sampling frequency for tests
        fsOrig = 1000; % Original sampling frequency of the fixture
        signal;
        t;
    end

    methods (TestClassSetup)
        function addPathsAndData(tc)
            % Add required paths
            addpath(fullfile(pwd, '..', '..', 'src', 'tools'));

            % Load real PPG data from fixtures
            data = readtable(fullfile(pwd, '..', '..', 'fixtures', 'ppg', 'ppg_signals.csv'));
            
            % Use 30 seconds of data
            duration = 30;
            tOrig = (0:duration*tc.fsOrig-1)'/tc.fsOrig;
            signalOrig = data.sig(1:length(tOrig));

            % Resample to the test frequency
            [tc.signal, tc.t] = resample(signalOrig, tOrig, tc.fs);
        end
    end

    methods (Test)
        function testBasicFunctionality(tc)
            % Define a stop frequency for testing
            stopFreq = 8.0;
            
            % Execute function under test with default parameters
            [filteredSignal, filterCoeff] = lpdfilter(tc.signal, tc.fs, stopFreq);

            % Basic verifications
            tc.verifySize(filteredSignal, size(tc.signal), 'Filtered signal size mismatch');
            tc.verifyNotEqual(filteredSignal, tc.signal, 'Signal should be modified by filter');
            tc.verifyTrue(all(isfinite(filteredSignal)), 'Filtered signal should be finite');

            % Verify filter coefficients are non-empty
            tc.verifyTrue(~isempty(filterCoeff), 'Filter coefficients should be generated');
            tc.verifyTrue(all(isfinite(filterCoeff)), 'Filter coefficients should be finite');
        end

        function testInvalidRequiredInputs(tc)
            % Test for not enough inputs
            tc.verifyError(@() lpdfilter(), 'MATLAB:narginchk:notEnoughInputs');
            tc.verifyError(@() lpdfilter(tc.signal), 'MATLAB:narginchk:notEnoughInputs');
            tc.verifyError(@() lpdfilter(tc.signal, tc.fs), 'MATLAB:narginchk:notEnoughInputs');
            
            % Test with invalid signal and fs
            tc.verifyError(@() lpdfilter([], tc.fs, 8.0), 'MATLAB:InputParser:ArgumentFailedValidation');
            tc.verifyError(@() lpdfilter('not-numeric', tc.fs, 8.0), 'MATLAB:InputParser:ArgumentFailedValidation');
            tc.verifyError(@() lpdfilter(tc.signal, -100, 8.0), 'MATLAB:InputParser:ArgumentFailedValidation');
            tc.verifyError(@() lpdfilter(tc.signal, 0, 8.0), 'MATLAB:InputParser:ArgumentFailedValidation');
            tc.verifyError(@() lpdfilter(tc.signal, [100 100], 8.0), 'MATLAB:InputParser:ArgumentFailedValidation');
            tc.verifyError(@() lpdfilter(tc.signal, tc.fs, -1), 'MATLAB:InputParser:ArgumentFailedValidation');
            tc.verifyError(@() lpdfilter(tc.signal, tc.fs, 0), 'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function testInvalidNameValueInputs(tc)
            % Test invalid frequency parameters
            tc.verifyError(@() lpdfilter(tc.signal, tc.fs, 9, 'PassFreq', 10), 'lpdfilter:invalidFrequencies');
            tc.verifyError(@() lpdfilter(tc.signal, tc.fs, tc.fs/2), 'lpdfilter:invalidStopFreq');

            % Test invalid order
            tc.verifyError(@() lpdfilter(tc.signal, tc.fs, 8.0, 'Order', 51), 'MATLAB:InputParser:ArgumentFailedValidation'); % Must be even
            tc.verifyError(@() lpdfilter(tc.signal, tc.fs, 8.0, 'Order', -10), 'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function testNaNHandling(tc)
            % Setup test data with NaN values
            signalWithNaNs = tc.signal;
            nanIndices = [1, 5, 25, 45, length(signalWithNaNs)];
            signalWithNaNs(nanIndices) = NaN;
            stopFreq = 8.0;
            
            % Execute function with pre-computed coefficients to test that path
            [~, coeffs] = lpdfilter(tc.signal, tc.fs, stopFreq);
            filteredSignal1 = lpdfilter(signalWithNaNs, tc.fs, stopFreq, 'Coefficients', coeffs);
            
            % Execute function without pre-computed coefficients to test that path
            filteredSignal2 = lpdfilter(signalWithNaNs, tc.fs, stopFreq);
            
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
            stopFreq = 8.0;
            
            % Execute function
            filteredSignal = lpdfilter(allNanSignal, tc.fs, stopFreq);
            
            % fillmissing with 'linear' on an all-NaN vector results in an all-NaN vector.
            % The subsequent filtering should also result in all-NaNs.
            tc.verifyTrue(all(isnan(filteredSignal)), 'All-NaN input should result in all-NaN output');
        end

        function testOptionalParameters(tc)
            % Test with custom parameters
            stopFreq = 8.0;
            [filteredSignal1, filterCoeff1] = lpdfilter(tc.signal, tc.fs, stopFreq);
            [filteredSignal2, filterCoeff2] = lpdfilter(tc.signal, tc.fs, stopFreq, ...
                'Order', 20, 'PassFreq', 5);

            % Verify results are different
            tc.verifyNotEqual(length(filterCoeff1), length(filterCoeff2), ...
                'Filter coefficients should differ with custom order');
            tc.verifyNotEqual(filteredSignal1, filteredSignal2, ...
                'Filtered signals should differ with different parameters');
        end

        function testColumnVectorOutput(tc)
            % Test row vector input
            rowSignal = [1, 2, 3, 4, 5];
            stopFreq = 8.0;
            filteredSignal = lpdfilter(rowSignal, tc.fs, stopFreq);
            tc.verifySize(filteredSignal, [length(rowSignal), 1], 'Output should be a column vector');
        end

        function testPreComputedCoefficients(tc)
            % Get filter coefficients from a first run
            stopFreq = 8.0;
            [~, filterCoeff] = lpdfilter(tc.signal, tc.fs, stopFreq);

            % Filter signal using pre-computed coefficients
            filteredSignal1 = lpdfilter(tc.signal, tc.fs, stopFreq, 'Coefficients', filterCoeff);

            % Filter signal computing coefficients again
            filteredSignal2 = lpdfilter(tc.signal, tc.fs, stopFreq);

            % Results should be identical
            tc.verifyEqual(filteredSignal1, filteredSignal2, ...
                'Using pre-computed coefficients should yield identical results');
        end

        function testShortSignalHandling(tc)
            % Create a signal shorter than 3x the default filter order
            shortSignal = tc.signal(1:10); % Default order is ~50
            stopFreq = 8.0;
            
            % Execute function
            filteredSignal = lpdfilter(shortSignal, tc.fs, stopFreq);
            
            % Verify output is valid
            tc.verifySize(filteredSignal, size(shortSignal), 'Filtered signal size mismatch for short input');
            tc.verifyTrue(all(isfinite(filteredSignal)), 'Short filtered signal should be finite');
        end

        function testNargout(tc)
            % Test for too many output arguments
            function callWithTooManyOutputs()
                [~,~,~] = lpdfilter(tc.signal, tc.fs, 8.0);
            end
            tc.verifyError(@callWithTooManyOutputs, 'MATLAB:TooManyOutputs');
        end

        function testAutoCalculatedParameters(tc)
            % Test that auto-calculated parameters work correctly
            stopFreq = 8.0;
            [filteredSignal, filterCoeff] = lpdfilter(tc.signal, tc.fs, stopFreq);
            
            % Verify results
            tc.verifyTrue(~isempty(filteredSignal), 'Filtered signal should not be empty');
            tc.verifyTrue(~isempty(filterCoeff), 'Filter coefficients should not be empty');
            tc.verifyTrue(all(isfinite(filterCoeff)), 'Filter coefficients should be finite');
        end

        function testLpdFilterDesignAtDifferentSamplingFrequencies(tc)
            % Test LPD filter design with 8Hz cutoff at different sampling frequencies
            % This test verifies that the filter is constructed correctly for both
            % low (26Hz) and high (1000Hz) sampling frequencies
            
            % Test parameters
            fsLow = 26;    % Low sampling frequency
            fsHigh = 1000; % High sampling frequency
            stopFreqLow = 9;  % Stop frequency for low fs
            stopFreqHigh = 8.5; % Stop frequency for high fs
            
            % Create test signals at different sampling rates
            duration = 30; % seconds
            tLow = (0:1/fsLow:duration-1/fsLow)';
            tHigh = (0:1/fsHigh:duration-1/fsHigh)';
            
            % Simple test signal: sum of sinusoids at different frequencies
            freq1 = 3; % Below cutoff
            freq2 = 15; % Above cutoff
            signalLow = sin(2*pi*freq1*tLow) + 0.5*sin(2*pi*freq2*tLow);
            signalHigh = sin(2*pi*freq1*tHigh) + 0.5*sin(2*pi*freq2*tHigh);
            
            % Design filters with specified cutoff frequencies
            [~, coeffLow] = lpdfilter(signalLow, fsLow, stopFreqLow, 'PassFreq', 7, 'Order', 20);
            [~, coeffHigh] = lpdfilter(signalHigh, fsHigh, stopFreqHigh, 'PassFreq', 7.5, 'Order', 100);
            
            % Verify filter coefficients are valid
            tc.verifyTrue(all(isfinite(coeffLow)), ...
                'Low fs filter coefficients should be finite');
            tc.verifyTrue(all(isfinite(coeffHigh)), ...
                'High fs filter coefficients should be finite');
            
            % Verify filter lengths match expected orders
            tc.verifyEqual(length(coeffLow), 21, ...
                'Low fs filter should have 21 coefficients (order 20 + 1)');
            tc.verifyEqual(length(coeffHigh), 101, ...
                'High fs filter should have 101 coefficients (order 100 + 1)');
            
            % Test frequency response characteristics
            [hLow, wLow] = freqz(coeffLow, 1, 512);
            [hHigh, wHigh] = freqz(coeffHigh, 1, 512);
            
            fLow = wLow * fsLow / (2*pi);
            fHigh = wHigh * fsHigh / (2*pi);
            
            % Verify that the derivative nature of the filter is preserved
            % LPD filters should have near-zero DC response
            dcResponseLow = abs(hLow(1));
            dcResponseHigh = abs(hHigh(1));
            
            tc.verifyLessThan(dcResponseLow, 0.1*max(abs(hLow)), ...
                'Low fs LPD filter should have low DC response');
            tc.verifyLessThan(dcResponseHigh, 0.1*max(abs(hHigh)), ...
                'High fs LPD filter should have low DC response');
            
            % Find frequency response at passband frequencies
            % For low fs filter (PassFreq=7Hz)
            [~, idxPassLow] = min(abs(fLow - 7));
            
            % For high fs filter (PassFreq=7.5Hz)
            [~, idxPassHigh] = min(abs(fHigh - 7.5));
            
            % Verify that passband has higher response than stopband
            % (accounting for the derivative nature which enhances mid-frequencies)
            passbandResponseLow = abs(hLow(idxPassLow));
            passbandResponseHigh = abs(hHigh(idxPassHigh));
            
            % For LPD filters, the response should be significant at the passband frequency
            tc.verifyGreaterThan(passbandResponseLow, 0.05*max(abs(hLow)), ...
                'Low fs filter should have significant response at passband frequency');
            tc.verifyGreaterThan(passbandResponseHigh, 0.05*max(abs(hHigh)), ...
                'High fs filter should have significant response at passband frequency');
            
            % Verify the filters have been designed (non-zero coefficients)
            tc.verifyGreaterThan(max(abs(coeffLow)), 0, ...
                'Low fs filter should have non-zero coefficients');
            tc.verifyGreaterThan(max(abs(coeffHigh)), 0, ...
                'High fs filter should have non-zero coefficients');
            
            % Test that the scaling factor (fs/(2*pi)) has been applied correctly
            % The maximum coefficient magnitude should be reasonable for the sampling frequency
            maxCoeffLow = max(abs(coeffLow));
            maxCoeffHigh = max(abs(coeffHigh));
            
            tc.verifyGreaterThan(maxCoeffLow, fsLow/(2*pi)/1000, ...
                'Low fs filter coefficients should reflect proper scaling');
            tc.verifyGreaterThan(maxCoeffHigh, fsHigh/(2*pi)/1000, ...
                'High fs filter coefficients should reflect proper scaling');
        end
    end
end
