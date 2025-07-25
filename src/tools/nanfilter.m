function y = nanfilter(b, a, x, maxgap)
% NANFILTER Implements filter function with support for NaN values.
%
%   Y = NANFILTER(B, A, X) filters the data in vector, matrix, or N-D
%   array, X, with the filter described by vectors A and B to create
%   the filtered data Y with NaN values preserved.
%
%   Y = NANFILTER(B, A, X, MAXGAP) allows specifying a maximum gap size MAXGAP.
%
%   Algorithm:
%     1. For each column, identify NaN sequences and classify them as long (> MAXGAP)
%        or short (<= MAXGAP).
%     2. If no long NaN sequences exist, process the entire column with interpolation.
%     3. If long NaN sequences exist, divide the column into valid segments.
%     4. Process each valid segment independently using filter after interpolating
%        any short NaN gaps within the segment.
%     5. Restore the original long NaN gaps in the final result.
%
%   Example:
%     % Filter a noisy signal with NaN gaps
%     fs = 1000;
%     t = 0:1/fs:1;
%     signal = sin(2*pi*50*t)' + 0.1*randn(length(t),1);
%     signal(100:150) = NaN;  % Add NaN gap
%
%     % Design and apply filter
%     [b, a] = butter(4, 0.1);
%     filtered = nanfilter(b, a, signal, 10);
%
%   See also FILTER, NANFILTFILT, INTERPGAP


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
