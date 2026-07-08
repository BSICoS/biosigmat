% Tests covering:
%   - Signal with no NaNs
%   - NaN gap handling (short and long gaps)
%   - Edge cases (all NaN, no NaN)
%   - Input validation
%   - Row vector input handling
%   - Multi-column signals with NaNs
%   - Multi-column all-NaN input handling

classdef nanfilterTest < NanFilterTestBase

    properties (TestParameter)
        validConformanceCaseId = {
            'tools.nan_filter.no_nan_equivalent_filter'
            'tools.nan_filter.short_nan_gap_interpolation'
            'tools.nan_filter.long_nan_gap_segmentation'
            'tools.nan_filter.row_vector_orientation'
            'tools.nan_filter.boundary_nan_preserved'
            'tools.nan_filter.too_short_segments_nan'
        }
    end

    methods (Test)
        function testBiosiglibConformanceCase(tc, validConformanceCaseId)
            tc.verifyBiosiglibNanFilteringCase( ...
                @nanfilter, validConformanceCaseId);
        end

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
