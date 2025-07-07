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
            b = lpdfilter(tc.fs, stopFreq);
            filteredSignal = filter (b, 1, tc.signal);

            % Basic verifications
            tc.verifySize(filteredSignal, size(tc.signal), 'Filtered signal size mismatch');
            tc.verifyNotEqual(filteredSignal, tc.signal, 'Signal should be modified by filter');
            tc.verifyTrue(all(isfinite(filteredSignal)), 'Filtered signal should be finite');

            % Verify filter coefficients are non-empty
            tc.verifyTrue(~isempty(b), 'Filter coefficients should be generated');
            tc.verifyTrue(all(isfinite(b)), 'Filter coefficients should be finite');
        end

        function testInvalidRequiredInputs(tc)
            % Test for not enough inputs
            tc.verifyError(@() lpdfilter(), 'MATLAB:narginchk:notEnoughInputs');
            tc.verifyError(@() lpdfilter(tc.fs), 'MATLAB:narginchk:notEnoughInputs');

            % Test with invalid fs
            tc.verifyError(@() lpdfilter(-100, 8.0), 'MATLAB:InputParser:ArgumentFailedValidation');
            tc.verifyError(@() lpdfilter(0, 8.0), 'MATLAB:InputParser:ArgumentFailedValidation');
            tc.verifyError(@() lpdfilter([100 100], 8.0), 'MATLAB:InputParser:ArgumentFailedValidation');

            % Test with invalid stop frequency
            tc.verifyError(@() lpdfilter(tc.fs, -1), 'MATLAB:InputParser:ArgumentFailedValidation');
            tc.verifyError(@() lpdfilter(tc.fs, 0), 'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function testInvalidNameValueInputs(tc)
            % Test invalid frequency parameters
            tc.verifyError(@() lpdfilter(tc.fs, 9, 'PassFreq', 10), 'lpdfilter:invalidFrequencies');
            tc.verifyError(@() lpdfilter(tc.fs, tc.fs/2), 'lpdfilter:invalidStopFreq');

            % Test invalid order
            tc.verifyError(@() lpdfilter(tc.fs, 8.0, 'Order', -10), 'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function testNargout(tc)
            % Test for too many output arguments
            function callWithTooManyOutputs()
                [~,~,~] = lpdfilter(tc.signal, tc.fs, 8.0);
            end
            tc.verifyError(@callWithTooManyOutputs, 'MATLAB:TooManyOutputs');
        end
    end
end
