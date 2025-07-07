function y = nanfiltfilt(b, a, x, maxgap)
% NANFILTFILT Implements filtfilt function with support for NaN values
%
% This function applies zero-phase digital filtering to a signal that contains
% NaN values. It uses segmented processing to avoid border artifacts that can
% occur when filtering across interpolated gaps. The algorithm divides the
% signal into segments separated by long NaN gaps (> maxgap) and processes
% each segment independently, preventing contamination between segments.
%
% Inputs:
%   b          - Numerator coefficients of the filter
%   a          - Denominator coefficients of the filter
%   x          - Input matrix with signals in columns that can include NaN values
%   maxgap     - Optional. Maximum gap size to interpolate. If not specified,
%                all NaN segments will be preserved regardless of their size.
%
% Outputs:
%   y          - Matrix of filtered signals in columns with NaN values preserved where appropriate
%
% Algorithm:
%   1. For each column, identify NaN sequences and classify them as long (> maxgap)
%      or short (<= maxgap)
%   2. If no long NaN sequences exist, process the entire column with interpolation
%   3. If long NaN sequences exist, divide the column into valid segments
%      separated by these long gaps
%   4. Process each valid segment independently using filtfilt after interpolating
%      any short NaN gaps within the segment
%   5. Restore the original long NaN gaps in the final result
%
% This approach eliminates border artifacts that can occur when filtering
% signals with interpolated values across large gaps.

% Argument validation
narginchk(3, 4);
nargoutchk(0, 1);

% Parse and validate inputs using common parsing function
if nargin < 4
    [b, a, x, maxgap] = parseNanFiltering('nanfiltfilt', b, a, x);
else
    [b, a, x, maxgap] = parseNanFiltering('nanfiltfilt', b, a, x, maxgap);
end

% Use common NaN filtering logic
y = processNanSignal(b, a, x, maxgap, @filtfilt);

end