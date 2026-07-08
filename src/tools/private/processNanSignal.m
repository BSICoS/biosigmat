function y = processNanSignal(b, a, x, maxgap, filterFunc, minimumSegmentLength)
% PROCESSNANSIGNAL Common function for processing signals with NaN values
%
% This function implements the common logic for both nanFilter and nanFiltFilt
% by processing signals in segments separated by preserved NaN gaps.
%
% Inputs:
%   b          - Numerator coefficients of the filter
%   a          - Denominator coefficients of the filter
%   x          - Input matrix with signals in columns that can include NaN values
%   maxgap     - Maximum gap size to interpolate
%   filterFunc - Function handle (@filter or @filtfilt)
%   minimumSegmentLength - Minimum samples required to filter a segment
%
% Outputs:
%   y          - Matrix of processed signals in columns with NaN values preserved

% Check number of input and output arguments
narginchk(6, 6);
nargoutchk(0, 1);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'processNanSignal';
addRequired(parser, 'b', @(v) isnumeric(v) && isvector(v));
addRequired(parser, 'a', @(v) isnumeric(v) && isvector(v));
addRequired(parser, 'x', @(v) ismatrix(v));
addRequired(parser, 'maxgap', @(v) isnumeric(v) && isscalar(v) && v >= 0);
addRequired(parser, 'filterFunc', @(v) isa(v, 'function_handle'));
addRequired(parser, 'minimumSegmentLength', @(v) isnumeric(v) && isscalar(v) && v >= 1);
parse(parser, b, a, x, maxgap, filterFunc, minimumSegmentLength);

b = parser.Results.b;
a = parser.Results.a;
x = parser.Results.x;
maxgap = parser.Results.maxgap;
filterFunc = parser.Results.filterFunc;
minimumSegmentLength = parser.Results.minimumSegmentLength;

% Handle row vectors by transposing
wasRowVector = false;
if isrow(x)
    wasRowVector = true;
    x = x';
end

idxNan = isnan(x);

if all(idxNan(:))
    y = x;
    if wasRowVector
        y = y';
    end
    return
end

% Initialize output with same size as input
y = NaN(size(x));

% Process each column separately to avoid cross-column contamination
for col = 1:size(x,2)
    colData = x(:,col);
    idxNanCol = idxNan(:,col);

    if all(idxNanCol)
        continue; % entire column is NaN, already handled
    end

    % Find NaN sequences in this column
    seqs = findsequences(double(idxNanCol));
    if ~isempty(seqs)
        % Keep only NaN sequences (value = 1)
        seqs = seqs(seqs(:,1) == 1, :);
    end

    % findsequences detects repeated runs, so add isolated NaN samples as
    % one-sample sequences before classifying gaps.
    if any(idxNanCol)
        coveredNan = false(size(idxNanCol));
        for s = 1:size(seqs, 1)
            coveredNan(seqs(s, 2):seqs(s, 3)) = true;
        end

        isolatedNanIndices = find(idxNanCol & ~coveredNan);
        if ~isempty(isolatedNanIndices)
            isolatedNanSeqs = [ ...
                ones(numel(isolatedNanIndices), 1), ...
                isolatedNanIndices, ...
                isolatedNanIndices, ...
                ones(numel(isolatedNanIndices), 1)];
            seqs = [seqs; isolatedNanSeqs]; %#ok<AGROW>
        end

        seqs = sortrows(seqs, 2);
    end

    % Boundary NaN gaps and long internal NaN gaps are preserved as NaN.
    % Short internal gaps are interpolated within their candidate segment.
    if isempty(seqs)
        preservedNanSeqs = [];
    else
        isBoundaryGap = seqs(:,2) == 1 | seqs(:,3) == length(colData);
        isLongInternalGap = ~isBoundaryGap & seqs(:,4) > maxgap;
        preservedNanSeqs = seqs(isBoundaryGap | isLongInternalGap, :);
    end

    % Process valid segments between preserved NaN gaps separately
    validSegments = getValidSegments(colData, preservedNanSeqs);

    for segIdx = 1:size(validSegments,1)
        startIdx = validSegments(segIdx,1);
        endIdx = validSegments(segIdx,2);

        if startIdx > endIdx
            continue; % Skip invalid segments
        end

        segmentData = colData(startIdx:endIdx);

        % Fill short NaN gaps within this segment. Boundary and long gaps
        % have already split the segment, so no extrapolation is allowed.
        segmentFilled = fillmissing(segmentData, 'linear', 'EndValues', 'none');

        % Apply the selected filter only to segments that meet its minimum
        % length; too-short candidate segments remain NaN in the output.
        if any(isnan(segmentFilled)) || length(segmentFilled) < minimumSegmentLength
            continue;
        end

        y(startIdx:endIdx,col) = filterFunc(b, a, segmentFilled);
    end
end

% Transpose back if input was row vector
if wasRowVector
    y = y';
end

end
