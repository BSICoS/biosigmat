% Tests covering:
%   - Signal with no NaNs
%   - NaN gap handling (short and long gaps)
%   - Edge cases (all NaN, no NaN)
%   - Input validation
%   - Row vector input handling
%   - Multi-column signals with NaNs
%   - Multi-column all-NaN input handling

classdef nanfiltfiltTest < NanFilterTestBase

    properties (TestParameter)
        validConformanceCaseId = {
            'tools.nan_filtfilt.no_nan_equivalent_filtfilt'
            'tools.nan_filtfilt.short_nan_gap_interpolation'
            'tools.nan_filtfilt.long_nan_gap_segmentation'
            'tools.nan_filtfilt.row_vector_orientation'
            'tools.nan_filtfilt.boundary_nan_preserved'
            'tools.nan_filtfilt.too_short_segments_nan'
        }
    end

    methods (Test)
        function testBiosiglibConformanceCase(tc, validConformanceCaseId)
            tc.verifyBiosiglibNanFilteringCase( ...
                @nanfiltfilt, validConformanceCaseId);
        end

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
