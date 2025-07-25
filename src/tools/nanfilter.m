function y = nanfilter(b, a, x, maxgap)
% NANFILTER Implements filter function with support for NaN values.
%
% Y = NANFILTER(B, A, X, MAXGAP) This function applies digital filtering to a signal that contains
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
%   4. Process each valid segment independently using filter after interpolating
%      any short NaN gaps within the segment
%   5. Restore the original long NaN gaps in the final result
%
% This approach eliminates border artifacts that can occur when filtering
% signals with interpolated values across large gaps.
%
% EXAMPLE:
%   % Filter a noisy signal with NaN gaps
%   fs = 1000;
%   t = 0:1/fs:1;
%   signal = sin(2*pi*50*t)' + 0.1*randn(length(t),1);
%   signal(100:150) = NaN;  % Add NaN gap
%   [b, a] = butter(4, 0.1);
%   filtered = nanfilter(b, a, signal, 10);
%
% STATUS: Beta

% Check number of input and output arguments
narginchk(3, 4);
nargoutchk(0, 1);

% Parse and validate inputs using common parsing function
if nargin < 4
    [b, a, x, maxgap] = parseNanFiltering('nanfilter', b, a, x);
else
    [b, a, x, maxgap] = parseNanFiltering('nanfilter', b, a, x, maxgap);
end

% Use common NaN filtering logic
y = processNanSignal(b, a, x, maxgap, @filter);

end
