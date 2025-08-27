function [maxValue, maxLoc] = localmax(X, varargin)
% LOCALMAX Finds local maxima in matrix rows or columns.
%
%   MAXVALUE = LOCALMAX(X) finds the location and value of the most
%   prominent local maximum along the first non-singleton dimension of matrix X.
%   Returns MAXVALUE containing the max values. For rows/columns without
%   maxima, returns NaN.
%
%   MAXVALUE = LOCALMAX(X, DIM) finds the location and value of the
%   most prominent local maximum along dimension DIM of matrix X. DIM specifies
%   the dimension along which to search for maxima (1 for columns, 2 for rows).
%   Returns MAXVALUE containing the max values. For rows/columns without
%   maxima, returns NaN.
%
%   MAXVALUE = LOCALMAX(X, DIM, 'Name', Value) specifies additional
%   parameters using name-value pairs:
%
%   MAXVALUE = LOCALMAX(X, 'Name', Value) specifies additional
%   parameters using name-value pairs:
%     'MinProminence' - Minimum prominence required for max detection
%                       (default: 0)
%     'MinSeparation' - Minimum separation between max in samples
%                       (default: 1)
%
%   [MAXVALUE, MAXLOC] = LOCALMAX(...) also returns MAXLOC containing
%   the max locations.
%
%   Example:
%     % Create test signals with peaks
%     t = 0:0.01:2;
%     signal1 = sin(2*pi*t) + 0.5*sin(6*pi*t);
%     signal2 = cos(3*pi*t) + 0.3*randn(size(t));
%     X = [signal1; signal2];
%
%     % Find local maxima using automatic dimension detection
%     [maxValue, maxLoc] = localmax(X);
%
%     % Find local maxima along rows (dim=2) explicitly
%     [maxValue2, maxLoc2] = localmax(X, 2);
%
%     % Plot results
%     figure;
%     subplot(2,1,1);
%     plot(t, signal1, 'b-', t(maxLoc2(1)), maxValue2(1), 'ro', 'MarkerFaceColor', 'r');
%     title('Signal 1 with Local Maximum');
%     subplot(2,1,2);
%     plot(t, signal2, 'g-', t(maxLoc2(2)), maxValue2(2), 'ro', 'MarkerFaceColor', 'r');
%     title('Signal 2 with Local Maximum');
%
%   See also ISLOCALMAX, MAX, FINDPEAKS
%
%   Status: Alpha


% Check number of input and output arguments
narginchk(1, 5);
nargoutchk(0, 2);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'localmax';
addRequired(parser, 'X', @(x) isnumeric(x) && ~isempty(x));
addOptional(parser, 'dim', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && (x == 1 || x == 2)));
addParameter(parser, 'MinProminence', 0, @(x) isnumeric(x) && isscalar(x) && x >= 0);
addParameter(parser, 'MinSeparation', 1, @(x) isnumeric(x) && isscalar(x) && x >= 1);

parse(parser, X, varargin{:});

X = parser.Results.X;
dim = parser.Results.dim;
minProm = parser.Results.MinProminence;
minSep = parser.Results.MinSeparation;

% If dim is not specified, find first non-singleton dimension
if isempty(dim)
    sz = size(X);
    dim = find(sz > 1, 1);
    if isempty(dim)
        dim = 1; % If all dimensions are singleton, default to 1
    end
end

% Peak candidates per specified dimension
L = islocalmax(X, dim, 'MinProminence', minProm, ...
    'MinSeparation', minSep, ...
    'FlatSelection', 'center');

% Force to -Inf where NOT a peak and take maximum per specified dimension
Xmask = X;
Xmask(~L) = -inf;

[maxValue, maxLoc] = max(Xmask, [], dim, 'omitnan');

% Rows/columns without peaks -> NaN
hasPeak = any(L, dim);
maxLoc(~hasPeak) = NaN;
maxValue(~hasPeak) = NaN;

end
