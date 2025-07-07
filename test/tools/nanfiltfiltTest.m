% Tests covering:
%   - Signal with no NaNs
%   - NaN gap handling (short and long gaps)
%   - Edge cases (all NaN, no NaN)
%   - Input validation
%   - Row vector input handling
%   - Multi-column signals with NaNs
%   - Multi-column all-NaN input handling

classdef nanfiltfiltTest < NanFilterTestBase

    methods (Test)
        function testNoNanSignal(tc)
            tc.verifyNoNaNSignal(@nanfiltfilt, @filtfilt);
        end

        function testNanGaps(tc)
            tc.verifyShortNanGaps(@nanfiltfilt);
            tc.verifyLongNanGaps(@nanfiltfilt);
            tc.verifyMixedNanGaps(@nanfiltfilt);
        end

        function testEdgeCases(tc)
            tc.verifyAllNanInput(@nanfiltfilt);
            tc.verifyEmptyInput(@nanfiltfilt);
        end

        function testInsufficientInputs(tc)
            tc.verifyInsufficientInputs(@nanfiltfilt);
        end

        function testRowVectorInput(tc)
            tc.verifyRowVectorInput(@nanfiltfilt);
        end

        function testMultiColumnWithNans(tc)
            tc.verifyMultiColumnWithNans(@nanfiltfilt);
        end

        function testMultiColumnAllNaNSignal(tc)
            tc.verifyMultiColumnAllNaNSignal(@nanfiltfilt);
        end

        function testMultiColumnNoNaNSignal(tc)
            tc.verifyMultiColumnNoNaNSignal(@nanfiltfilt, @filtfilt);
        end
    end

end
