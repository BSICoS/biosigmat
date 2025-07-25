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
    varargout{1} = [];
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
    varargout{1} = [];
    return
end

% Detect special values (0, NaN, Inf, -Inf)
specialValues = [0, NaN, Inf, -Inf];
specialMasks = cell(1, 4);
specialMasks{1} = A == 0;       % Zeros
specialMasks{2} = isnan(A);     % NaNs
specialMasks{3} = A == Inf;     % Positive Infinity
specialMasks{4} = A == -Inf;    % Negative Infinity

% Create NaN padding for boundary detection algorithm
nanPadding = NaN([1, szA(2:end)]);

% Make a copy of A with zeros replaced by NaN (to process normal values)
AWithoutZeros = A;
AWithoutZeros(specialMasks{1}) = NaN;

% Process normal values
sequences = findSequencesByDiff(AWithoutZeros, nanPadding);

% Process special values (0, NaN, Inf, -Inf)
for i = 1:4
    % Only process if there are at least 2 occurrences of this special value
    if nnz(specialMasks{i}) > 1
        % Convert logical mask to double with NaNs for false values
        valueMask = double(specialMasks{i});
        valueMask(~specialMasks{i}) = NaN;

        % Process sequences of this special value
        tmp = findSequencesByDiff(valueMask, nanPadding);

        if ~isempty(tmp)
            % Combine with normal value results, replacing detected values with actual special values
            sequences = [sequences; repmat(specialValues(i), size(tmp, 1), 1), tmp(:, 2:end)]; %#ok<AGROW>
        end
    end
end

% Format output based on requested number of output arguments
if nargout < 2
    varargout = {sequences};
else
    % Split columns into separate output arguments
    varargout = num2cell(sequences(:, 1:nargout), 1);
end

end

function sequences = findSequencesByDiff(inputData, nanPadding)
% FINDSEQUENCESBYDIFF Find sequences of identical values using double differencing.
%
%   SEQUENCES = FINDSEQUENCESBYDIFF(INPUTDATA, NANPADDING) finds sequences of
%   identical values using a double differencing algorithm. SEQUENCES is a matrix
%   with sequence information [value, startIndices, endIndices, seqLengths].
%
%   Algorithm:
%     1. Pads input data with NaNs at boundaries
%     2. Uses double differencing to detect transitions between identical values
%     3. Identifies start/end points of sequences by analyzing difference patterns

% Calculate size of input data
szInput = size(inputData);

% Create padded structure (nanPadding-data-nanPadding)
paddedData = cat(1, nanPadding, inputData, nanPadding);

% Find sequences using double differencing along first dimension
diffIdx = diff(diff(paddedData, [], 1) == 0, [], 1);

% Find start and end positions of sequences
[startRows, startCols] = find(diffIdx == 1);
[endRows, endCols] = find(diffIdx == -1);

% If no sequences found, return empty result
if isempty(startRows)
    sequences = [];
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
sequences = [inputData(startIndices), startIndices, endIndices, seqLengths];

end
