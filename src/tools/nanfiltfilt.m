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

% Input validation
parser = inputParser;
parser.FunctionName = 'nanfiltfilt';
addRequired(parser, 'b', @(v) isnumeric(v) && isvector(v));
addRequired(parser, 'a', @(v) isnumeric(v) && isvector(v));
addRequired(parser, 'x', @(v) ismatrix(v));
addOptional(parser, 'maxgap', 0, @(v) isempty(v) || (isnumeric(v) && isscalar(v) && v >= 0));

if nargin < 4
    parse(parser, b, a, x);
else
    parse(parser, b, a, x, maxgap);
end

b = parser.Results.b;
a = parser.Results.a;
x = parser.Results.x;
maxgap = parser.Results.maxgap;

% Use common NaN filtering logic
y = processNanSignal(b, a, x, maxgap, @filtfilt);

end