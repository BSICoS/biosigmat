% Tests covering:
%   - Signal with no NaNs
%   - NaN gap handling (short and long gaps)
%   - Edge cases (all NaN, no NaN)
%   - Input validation
%   - Row vector input handling
%   - Multi-column signals with NaNs
%   - Multi-column all-NaN input handling

classdef nanfilterTest < NanFilterTestBase

    methods (Test)
        function testNoNanSignal(tc)
            tc.verifyNoNaNSignal(@nanfilter, @filter);
        end

        function testNanGaps(tc)
            tc.verifyShortNanGaps(@nanfilter);
            tc.verifyLongNanGaps(@nanfilter);
            tc.verifyMixedNanGaps(@nanfilter);
        end

        function testEdgeCases(tc)
            tc.verifyAllNanInput(@nanfilter);
            tc.verifyEmptyInput(@nanfilter);
        end

        function testInsufficientInputs(tc)
            tc.verifyInsufficientInputs(@nanfilter);
        end

        function testRowVectorInput(tc)
            tc.verifyRowVectorInput(@nanfilter);
        end

        function testMultiColumnWithNans(tc)
            tc.verifyMultiColumnWithNans(@nanfilter);
        end

        function testMultiColumnAllNaNSignal(tc)
            tc.verifyMultiColumnAllNaNSignal(@nanfilter);
        end

        function testMultiColumnNoNaNSignal(tc)
            tc.verifyMultiColumnNoNaNSignal(@nanfilter, @filter);
        end
    end

end
