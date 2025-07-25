function y = nanfiltfilt(b, a, x, maxgap)
% NANFILTFILT Implements filtfilt function with support for NaN values.
%
%   Y = NANFILTFILT(B, A, X, MAXGAP) filters the data in vector, matrix, or N-D
%   array, X, with the filter described by vectors A and B to create
%   the filtered data Y. The filter is described by the difference
%   equation:
%
%     a(1)*y(n) = b(1)*x(n) + b(2)*x(n-1) + ... + b(nb+1)*x(n-nb)
%                           - a(2)*y(n-1) - ... - a(na+1)*y(n-na).
%
%   The length of the input channels must be more than three times the
%   filter order, defined as filtord(B,A). This function applies zero-phase
%   digital filtering with to a signal X that may contain NaN values.
%   The algorithm divides the signal into segments separated by long NaN gaps (> MAXGAP)
%   and processes each segment independently. When X is a matrix, the filtering is
%   computed independently for each column and stored in the corresponding column of Y.
%   This approach eliminates border artifacts that can occur when filtering
%   signals with interpolated values across large gaps.
%
%   Algorithm:
%      1. For each column, identify NaN sequences and classify them as long (> MAXGAP)
%         or short (<= MAXGAP).
%      2. If no long NaN sequences exist, process the entire column with interpolation.
%      3. If long NaN sequences exist, divide the column into valid segments
%         separated by these long gaps.
%      4. Process each valid segment independently using filtfilt after interpolating
%         any short NaN gaps within the segment.
%      5. Restore the original long NaN gaps in the final result.
%
%   NANFILTFILT should not be used when the intent of a filter is to modify
%   signal phase, as is the case with differentiators and Hilbert filters.
%
%   Example:
%     % Filter a noisy signal with NaN gaps
%     fs = 1000;
%     t = 0:1/fs:1;
%     signal = sin(2*pi*50*t)' + 0.1*randn(length(t),1);
%     signal(100:150) = NaN;  % Add NaN gap
%     [b, a] = butter(4, 0.1);
%     filtered = nanfiltfilt(b, a, signal, 10);
%
%   See also: NANFILTER, FILTFILT, BUTTER
%
%   Status: Beta


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