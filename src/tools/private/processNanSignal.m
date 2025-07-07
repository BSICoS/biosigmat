function y = processNanSignal(b, a, x, maxgap, filterFunc)
% PROCESSNANSIGNAL Common function for processing signals with NaN values
%
% This function implements the common logic for both nanFilter and nanFiltFilt
% by processing signals in segments separated by long NaN gaps.
%
% Inputs:
%   b          - Numerator coefficients of the filter
%   a          - Denominator coefficients of the filter
%   x          - Input matrix with signals in columns that can include NaN values
%   maxgap     - Maximum gap size to interpolate
%   filterFunc - Function handle (@filter or @filtfilt)
%
% Outputs:
%   y          - Matrix of processed signals in columns with NaN values preserved

% Check number of input and output arguments
narginchk(5, 5);
nargoutchk(0, 1);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'processNanSignal';
addRequired(parser, 'b', @(v) isnumeric(v) && isvector(v));
addRequired(parser, 'a', @(v) isnumeric(v) && isvector(v));
addRequired(parser, 'x', @(v) ismatrix(v));
addRequired(parser, 'maxgap', @(v) isnumeric(v) && isscalar(v) && v >= 0);
addRequired(parser, 'filterFunc', @(v) isa(v, 'function_handle'));
parse(parser, b, a, x, maxgap, filterFunc);

b = parser.Results.b;
a = parser.Results.a;
x = parser.Results.x;
maxgap = parser.Results.maxgap;
filterFunc = parser.Results.filterFunc;

% Find NaNs
idxNan = isnan(x);

% Handle row vectors by transposing
wasRowVector = false;
if isvector(x) && size(x, 1) == 1
    wasRowVector = true;
    x = x';
    idxNan = idxNan';
end

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

    % Separate long NaN segments (> maxgap) from short ones (<= maxgap)
    if ~isempty(seqs)
        longNanSeqs = seqs(seqs(:,4) > maxgap, :);
    else
        longNanSeqs = [];
    end

    if isempty(longNanSeqs)
        % No long NaN segments, process entire column with interpolation
        colFilled = fillmissing(colData, 'linear');
        colFiltered = filterFunc(b, a, colFilled);
        y(:,col) = colFiltered;

        % Keep short NaN segments interpolated (do not restore them)
        % Only restore NaN segments that are longer than maxgap
        % Since longNanSeqs is empty, there are no long segments to restore
    else
        % Process valid segments between long NaN gaps separately
        validSegments = getValidSegments(colData, longNanSeqs);

        for segIdx = 1:size(validSegments,1)
            startIdx = validSegments(segIdx,1);
            endIdx = validSegments(segIdx,2);

            if startIdx > endIdx
                continue; % Skip invalid segments
            end

            segmentData = colData(startIdx:endIdx);

            % Fill short NaN gaps within this segment
            segmentFilled = fillmissing(segmentData, 'linear');

            % Apply filter to this segment
            if length(segmentFilled) >= max(length(a), length(b))
                segmentFiltered = filterFunc(b, a, segmentFilled);
                y(startIdx:endIdx,col) = segmentFiltered;

                % Do not restore short NaN segments within this segment
                % They should remain interpolated since they are <= maxgap
                % Only long NaN segments are restored later
            else
                % Segment too short for filtering, keep original with interpolation
                y(startIdx:endIdx,col) = segmentFilled;
            end
        end

        % Restore long NaN segments
        for s = 1:size(longNanSeqs,1)
            y(longNanSeqs(s,2):longNanSeqs(s,3),col) = NaN;
        end
    end
end

% Transpose back if input was row vector
if wasRowVector
    y = y';
end

end
