function y = nanfiltfilt(b, a, x, maxgap)
% NANFILTFILT Implements filtfilt function with support for NaN values.
%
%   Y = NANFILTFILT(B, A, X) zero-phase filters the data in vector, matrix,
%   or N-D array, X, with the filter described by vectors A and B to create
%   the filtered data Y with NaN values preserved.
%
%   The filter is described by the difference equation:
%
%     a(1)*y(n) = b(1)*x(n) + b(2)*x(n-1) + ... + b(nb+1)*x(n-nb)
%                           - a(2)*y(n-1) - ... - a(na+1)*y(n-na).
%
%   The length of the input channels must be more than three times the
%   filter order, defined as filtord(B,A).
%
%   Y = NANFILTFILT(B, A, X, MAXGAP) allows specifying a maximum gap size MAXGAP.
%
%   Algorithm:
%     1. For each column, classify NaN sequences as boundary gaps, internal
%        short gaps (<= MAXGAP), or preserved internal long gaps (> MAXGAP).
%     2. Preserve boundary and long internal gaps as NaN and use them to
%        split the signal into candidate finite segments.
%     3. Interpolate short internal gaps within each candidate segment.
%     4. Process filterable segments independently using filtfilt.
%     5. Leave segments too short for MATLAB-style filtfilt as NaN.
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
%
%     % Design and apply filter
%     [b, a] = butter(4, 0.1);
%     filtered = nanfiltfilt(b, a, signal, 10);
%
%   See also NANFILTER, FILTFILT, BUTTER


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
filterOrder = max(length(b) - 1, length(a) - 1);
minimumSegmentLength = 3 * filterOrder + 1;
y = processNanSignal(b, a, x, maxgap, @filtfilt, minimumSegmentLength);

end
