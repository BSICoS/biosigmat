function y = nanfiltfilt(b, a, x, maxgap)
% NANFILTFILT Implements filtfilt function with support for NaN values
%
% This function applies zero-phase digital filtering to a signal that contains
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
%   4. Process each valid segment independently using filtfilt after interpolating
%      any short NaN gaps within the segment
%   5. Restore the original long NaN gaps in the final result
%
% This approach eliminates border artifacts that can occur when filtering
% signals with interpolated values across large gaps.

% Argument validation
narginchk(3, 4);
nargoutchk(0, 1);

% Input validation
parser = inputParser;
parser.FunctionName = 'nanfiltfilt';
addRequired(parser, 'b', @(v) isnumeric(v) && isvector(v));
addRequired(parser, 'a', @(v) isnumeric(v) && isvector(v));
addRequired(parser, 'x', @(v) ismatrix(v));
addOptional(parser, 'maxgap', [], @(v) isempty(v) || (isnumeric(v) && isscalar(v) && v >= 0));

if nargin < 4
    parse(parser, b, a, x);
else
    parse(parser, b, a, x, maxgap);
end

b = parser.Results.b;
a = parser.Results.a;
x = parser.Results.x;
if isempty(parser.Results.maxgap)
    warning('nanfiltfilt:maxgapNotSpecified', 'maxgap not specified. All NaN segments will be preserved regardless of size.');
    maxgap = 0;
else
    maxgap = parser.Results.maxgap;
end

% Find NaNs
idxNan = isnan(x);

if all(idxNan(:))
    y = x;
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
    seqs(seqs(:,1) == 0, :) = []; % Remove non-NaN sequences

    % Separate long NaN segments (> maxgap) from short ones (<= maxgap)
    longNanSeqs = seqs(seqs(:,4) > maxgap, :);

    if isempty(longNanSeqs)
        % No long NaN segments, process entire column with interpolation
        colFilled = fillmissing(colData, 'linear');
        colFiltered = filtfilt(b, a, colFilled);
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
                segmentFiltered = filtfilt(b, a, segmentFilled);
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

end

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