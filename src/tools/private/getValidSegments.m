function validSegments = getValidSegments(data, longNanSeqs)
% GETVALIDSEGMENTS Identify valid data segments between long NaN sequences
%
% This function identifies continuous data segments that are separated by
% long NaN sequences. These segments can be processed independently to
% avoid filtering artifacts at the boundaries.
%
% Inputs:
%   data        - Input signal vector
%   longNanSeqs - Matrix of long NaN sequences from findsequences
%                 [value, startIdx, endIdx, length]
%
% Outputs:
%   validSegments - Nx2 matrix where each row contains [startIdx, endIdx]
%                   of valid data segments

% Check number of input and output arguments
narginchk(2, 2);
nargoutchk(0, 1);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'getValidSegments';
addRequired(parser, 'data', @(v) isvector(v));
addRequired(parser, 'longNanSeqs', @(v) ismatrix(v));
parse(parser, data, longNanSeqs);

data = parser.Results.data;
longNanSeqs = parser.Results.longNanSeqs;

if isempty(longNanSeqs)
    validSegments = [1, length(data)];
    return;
end

% Sort NaN sequences by start position
longNanSeqs = sortrows(longNanSeqs, 2);

% Initialize valid segments
validSegments = [];
currentStart = 1;

for i = 1:size(longNanSeqs, 1)
    nanStart = longNanSeqs(i, 2);
    nanEnd = longNanSeqs(i, 3);

    % Add segment before this NaN sequence
    if currentStart < nanStart
        validSegments = [validSegments; currentStart, nanStart - 1]; %#ok<AGROW>
    end

    % Next segment starts after this NaN sequence
    currentStart = nanEnd + 1;
end

% Add final segment if it exists
if currentStart <= length(data)
    validSegments = [validSegments; currentStart, length(data)];
end

% Remove invalid segments (where start > end)
validSegments = validSegments(validSegments(:,1) <= validSegments(:,2), :);
end
