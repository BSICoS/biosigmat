function varargout = findsequences(A)
% FINDSEQUENCES Find sequences of repeated (adjacent/consecutive) numeric values.
%
%   SEQUENCES = FINDSEQUENCES(A) finds sequences of repeated numeric values in A along the
%   first dimension. A should be numeric. SEQUENCES is a "m by 4" numeric matrix where
%   m is the number of sequences found.
%
%   Each sequence has 4 columns where:
%     1st col. - The value being repeated
%     2nd col. - The position of the first value of the sequence (startIndices)
%     3rd col. - The position of the last value of the sequence (endIndices)
%     4th col. - The length of the sequence (seqLengths)
%
%   Rows are grouped in this order: nonzero finite values, zeros, NaNs,
%   +Inf, and -Inf. Within each group, rows are ordered by start position.
%   For matrix inputs, this is by starting row, then by column.
%
%   [VALUES, INPOS, FIPOS, LEN] = FINDSEQUENCES(...) returns SEQUENCES as separate outputs.
%   If no sequences are found no value is returned. To convert positions into
%   subs/coordinates use IND2SUB.
%
%   Example:
%     % Find sequences of repeated values in a matrix
%     A = [20, 19,   3,   2, NaN, NaN;
%          20, 23,   1,   1,   1, NaN;
%          20,  7,   7, NaN,   1, NaN];
%
%     OUT = findsequences(A);
%     % OUT contains:
%     %   Value  startIndices  endIndices  seqLengths
%     %    20        1              3           3       % Three 20s in first column
%     %     1       14             15           2       % Two 1s (positions 14-15)
%     %   NaN       16             18           3       % Three NaNs (positions 16-18)
%
%     % Get separate outputs
%     [values, startPos, endPos, lengths] = findsequences(A);
%
%   See also IND2SUB, DIFF


% Argument validation
narginchk(1, 1);
nargoutchk(0, 4);

% Parse input arguments
parser = inputParser;
parser.FunctionName = 'findsequences';
addRequired(parser, 'A', @(x) isnumeric(x) && ismatrix(x));

parse(parser, A);

A = parser.Results.A;

% Input validation
if isempty(A) || isscalar(A)
    varargout = repmat({[]}, 1, max(1, nargout));
    return
end

% Get size of input array
szA = size(A);

% Ensure input is processed along first dimension
if nnz(szA ~= 1) == 1
    A = A(:);
    szA = size(A);
end

% Less than two elements along first dimension
if szA(1) < 2
    varargout = repmat({[]}, 1, max(1, nargout));
    return
end

% Detect all runs once, then preserve the established category order.
sequences = findSequencesByDiff(A);
values = sequences(:, 1);
zerosMask = values == 0;
nanMask = isnan(values);
sequences(zerosMask, 1) = 0;
sequences(nanMask, 1) = NaN;
sequences = [sequences(isfinite(values) & ~zerosMask, :); ...
             sequences(zerosMask, :); ...
             sequences(nanMask, :); ...
             sequences(values == Inf, :); ...
             sequences(values == -Inf, :)];

% Format output based on requested number of output arguments
if isempty(sequences)
    varargout = repmat({[]}, 1, max(1, nargout));
elseif nargout < 2
    varargout = {sequences};
else
    % Split columns into separate output arguments
    varargout = num2cell(sequences(:, 1:nargout), 1);
end

end

function sequences = findSequencesByDiff(inputData)
% FINDSEQUENCESBYDIFF Find sequences of identical values using adjacent equality.
%
%   SEQUENCES = FINDSEQUENCESBYDIFF(INPUTDATA) finds sequences of
%   identical values using an adjacent-equality mask. SEQUENCES is a matrix
%   with sequence information [value, startIndices, endIndices, seqLengths].
%
%   Algorithm:
%     1. Compares adjacent input values exactly
%     2. Pads and differences the equality mask to detect transitions
%     3. Identifies start/end points of sequences by analyzing difference patterns

% Calculate size of input data
szInput = size(inputData);

% Compare before differencing to avoid integer subtraction saturation.
left = inputData(1:end-1, :);
right = inputData(2:end, :);
equalPairs = (left == right) | (isnan(left) & isnan(right));
boundary = false(1, szInput(2));
diffIdx = diff([boundary; equalPairs; boundary], [], 1);

% Find start and end positions of sequences
[startRows, startCols] = find(diffIdx == 1);
[endRows, endCols] = find(diffIdx == -1);

% If no sequences found, return empty result
if isempty(startRows)
    sequences = zeros(0, 4);
    return;
end

% Ensure proper matching of start and end points
[startPoints, sortIdx] = sortrows([startRows, startCols], 1);
endPoints = [endRows, endCols];
endPoints = endPoints(sortIdx, :);

% Calculate sequence lengths
seqLengths = endPoints(:, 1) - startPoints(:, 1) + 1;

% Convert to linear indices
startIndices = sub2ind(szInput, startPoints(:, 1), startPoints(:, 2));
endIndices = sub2ind(szInput, endPoints(:, 1), endPoints(:, 2));

% Create output matrix [value, startIndices, endIndices, seqLengths]
sequences = [double(inputData(startIndices)), startIndices, endIndices, seqLengths];

end
