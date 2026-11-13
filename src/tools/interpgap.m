function interpolated = interpgap(x, maxgap, varargin)
% INTERPGAP Interpolate small NaN gaps in a signal.
%
%   INTERPOLATED = INTERPGAP(X, MAXGAP) interpolates NaN gaps in a
%   vector X that are smaller than or equal to a specified MAXGAP
%   Gaps larger than MAXGAP are left unchanged. INTERPOLATED is a
%   vector with the same size as X.
%
%   INTERPOLATED = INTERPGAP(..., METHOD) allows specifying the interpolation
%   method:
%     'linear'   - Linear interpolation (default)
%     'nearest'  - Nearest neighbor interpolation
%     'spline'   - Spline interpolation
%     'pchip'    - Piecewise cubic Hermite interpolating polynomial
%
%   Example:
%     % Create a signal with small gaps and interpolate
%     x = [1, 2, NaN, 4, 5, NaN, NaN, 8, 9, 10]';
%     interpolated = interpgap(x, 2);
%     interpolatedCubic = interpgap(x, 2, 'spline');
%
%     % Plot results
%     figure;
%     plot(1:length(x), x, 'ro', 1:length(interpolated), interpolated, 'b-');
%     legend('Original', 'Interpolated');
%     title('Signal Gap Interpolation');
%
%   See also INTERP1, ISNAN, FILLMISSING


% Check number of input and output arguments
narginchk(2, 3);
nargoutchk(0, 1);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'interpgap';
validMethods = {'linear', 'nearest', 'spline', 'pchip'};
addRequired(parser, 'x', @(x) isnumeric(x) && isreal(x) && ...
    (isvector(x) || isequal(size(x), [0, 0])) && ~any(isinf(x(:))));
addRequired(parser, 'maxgap', @(x) isnumeric(x) && isreal(x) && ...
    isscalar(x) && isfinite(x) && x >= 0 && x == fix(x));
addOptional(parser, 'method', 'linear', @(x) ...
    (ischar(x) || (isstring(x) && isscalar(x))) && any(strcmp(x, validMethods)));
parse(parser, x, maxgap, varargin{:});
x = parser.Results.x;
maxgap = parser.Results.maxgap;
method = char(parser.Results.method);

% Ensure signal is a column vector
inputSize = size(x);
x = x(:);

% Initialize output
interpolated = x;

% Find NaN indices
nanIndices = isnan(interpolated);

% Early return if no NaN values
if ~any(nanIndices)
    interpolated = reshape(interpolated, inputSize);
    return;
end

% Find NaN sequences
nanSeqStarts = find(diff([0; nanIndices]) > 0);
nanSeqEnds = find(diff([nanIndices; 0]) < 0);
longGaps = nanSeqEnds - nanSeqStarts + 1 > maxgap;

% Interpolate gaps that are ≤ maxgap
for i = 1:length(nanSeqStarts)
    gapLength = nanSeqEnds(i) - nanSeqStarts(i) + 1;
    if gapLength <= maxgap && nanSeqStarts(i) > 1 && nanSeqEnds(i) < length(x)
        % Get indices for interpolation (including boundary points)
        startIdx = 1;
        endIdx = length(x);
        previousGap = find(longGaps & nanSeqEnds < nanSeqStarts(i), 1, 'last');
        nextGap = find(longGaps & nanSeqStarts > nanSeqEnds(i), 1, 'first');
        if ~isempty(previousGap)
            startIdx = nanSeqEnds(previousGap) + 1;
        end
        if ~isempty(nextGap)
            endIdx = nanSeqStarts(nextGap) - 1;
        end

        % Find valid data points around the gap
        validIndices = ~isnan(x(startIdx:endIdx));
        if sum(validIndices) >= 2
            % Interpolate
            validData = x(startIdx:endIdx);
            sampleIndices = 1:length(validData);
            interpolatedData = interp1(sampleIndices(validIndices), ...
                validData(validIndices), sampleIndices, method);
            gapIndices = nanSeqStarts(i):nanSeqEnds(i);
            interpolated(gapIndices) = interpolatedData(gapIndices - startIdx + 1);
        end
    end
end

interpolated = reshape(interpolated, inputSize);
end
