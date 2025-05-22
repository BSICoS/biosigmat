function varargout = findsequences(inputArray, dimension)
% findsequences Find sequences of repeated (adjacent/consecutive) numeric values
%
% Finds sequences of repeated numeric values in an array along the specified dimension.
%
% Inputs:
%   inputArray - The array to search for sequences (must be numeric)
%   dimension - The dimension along which to search (optional)
%
% Outputs:
%   When using single output:
%     OUT is a "m x 4" numeric matrix where m is the number of sequences found.
%     Each sequence has 4 columns:
%       - 1st col.: the value being repeated
%       - 2nd col.: the position of the first value of the sequence
%       - 3rd col.: the position of the last value of the sequence
%       - 4th col.: the length of the sequence
%
%   When using multiple outputs:
%     [VALUES, INPOS, FIPOS, LEN] = findsequences(...)
%     Returns the columns of OUT as separate outputs
%
%   If no sequences are found, no value is returned.
%   To convert positions into subs/coordinates use IND2SUB
%
% Examples:
%
%     % There are sequences of 20s, 1s and NaNs (column-wise)
%     A = [  20,  19,   3,   2, NaN, NaN
%            20,  23,   1,   1,   1, NaN
%            20,   7,   7, NaN,   1, NaN]
%
%     OUT = findsequences(A)
%     OUT =
%            20        1          3        3
%             1       14         15        2
%           NaN       16         18        3
%
%     % 3D sequences: NaN, 6 and 0
%     A        = [  1, 4
%                 NaN, 5
%                   3, 6];
%     A(:,:,2) = [  0, 0
%                 NaN, 0
%                   0, 6];
%     A(:,:,3) = [  1, 0
%                   2, 5
%                   3, 6];
%
%     OUT = findsequences(A,3)
%     OUT =
%             6     6    18     3
%             0    10    16     2
%           NaN     2     8     2
%

% Check input arguments
error(nargchk(1, 2, nargin));

% Check output arguments
error(nargoutchk(0, 4, nargout));

% Validate input array
if ~isnumeric(inputArray)
    error('findseq:fmtA', 'inputArray should be numeric');
elseif isempty(inputArray) || isscalar(inputArray)
    varargout{1} = [];
    return;
elseif islogical(inputArray)
    inputArray = double(inputArray);
end

% Determine dimension to operate on
arraySize = size(inputArray);
if nargin == 1 || isempty(dimension)
    % First non-singleton dimension
    dimension = find(arraySize ~= 1, 1, 'first');
elseif ~(isnumeric(dimension) && dimension > 0 && rem(dimension, 1) == 0) || dimension > numel(arraySize)
    error('findseq:fmtDim', 'dimension should be a scalar positive integer <= ndims(inputArray)');
end

% Check if there are less than two elements along dimension
if arraySize(dimension) == 1
    varargout{1} = [];
    return;
end

% Handle vector input
if nnz(arraySize ~= 1) == 1
    inputArray = inputArray(:);
    dimension = 1;
    arraySize = size(inputArray);
end

% Detect special values: 0, NaN, Inf and -Inf
otherValues = cell(1, 4);
otherValues{1} = inputArray == 0;
otherValues{2} = isnan(inputArray);
otherValues{3} = inputArray == Inf;
otherValues{4} = inputArray == -Inf;
specialValues = [0, NaN, Inf, -Inf];

% Remove zeros from main array (will be handled separately)
inputArray(otherValues{1}) = NaN;

% Create NaN padding
nanPadding = NaN([arraySize(1:dimension-1), 1, arraySize(dimension+1:end)]);

% Get sequences of normal values
outputSequences = findSequencesByRunLengthEncoding(inputArray, nanPadding, dimension, arraySize);

% Get sequences of special values (0, NaN, Inf and -Inf)
for valueIdx = 1:4
    if nnz(otherValues{valueIdx}) > 1
        % Convert logical to double and apply NaN padding
        otherValues{valueIdx} = double(otherValues{valueIdx});
        otherValues{valueIdx}(~otherValues{valueIdx}) = NaN;

        % Find sequences of this special value
        tempSequences = findSequencesByRunLengthEncoding(otherValues{valueIdx}, nanPadding, dimension, arraySize);

        % Add to output if any sequences found
        if ~isempty(tempSequences)
            outputSequences = [outputSequences; [repmat(specialValues(valueIdx), size(tempSequences, 1), 1) tempSequences(:, 2:end)]];
        end
    end
end

% Distribute output based on number of requested outputs
if nargout < 2
    varargout = {outputSequences};
else
    varargout = num2cell(outputSequences(:, 1:nargout), 1);
end

end

function outputSequences = findSequencesByRunLengthEncoding(dataArray, padding, dimension, sizeData)
% findSequencesByRunLengthEncoding Helper function to find sequences using run length encoding
%
% Inputs:
%   dataArray - The data array to search for sequences
%   padding - NaN padding to assist with sequence detection
%   dimension - The dimension along which to search
%   sizeData - Size of the data array
%
% Outputs:
%   outputSequences - Matrix containing sequence information

% Create a "sandwich" with NaN padding at both ends
sandwich = cat(dimension, padding, dataArray, padding);

% Find chunks using run length encoding approach
diffMatrix = diff(diff(sandwich, [], dimension) == 0, [], dimension);

% Find positions where sequences start and end
[startRows, startCols] = find(diffMatrix == 1);
[endRows, endCols] = find(diffMatrix == -1);

% Make sure rows/columns correspond (relevant if dimension > 1)
[startCoords, sortIdx] = sortrows([startRows, startCols], 1);
endCoords = [endRows, endCols];
endCoords = endCoords(sortIdx, :);

% Calculate length of sequences
if dimension < 3
    sequenceLength = endCoords(:, dimension) - startCoords(:, dimension) + 1;
else
    middleDimProduct = prod(sizeData(2:dimension-1));
    sequenceLength = (endCoords(:, 2) - startCoords(:, 2)) / middleDimProduct + 1;
end

% Convert to linear indices
startPositions = sub2ind(sizeData, startCoords(:, 1), startCoords(:, 2));
endPositions = sub2ind(sizeData, endCoords(:, 1), endCoords(:, 2));

% Assemble output matrix
outputSequences = [dataArray(startPositions), ...  % Values
    startPositions, ...              % Initial positions
    endPositions, ...                % Final positions
    sequenceLength];                 % Length of sequences
end
