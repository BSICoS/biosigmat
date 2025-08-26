function [maxValue, maxLoc] = localmax(X, dim, varargin)
% LOCALMAX Finds local maxima in matrix rows or columns.
%
%   MAXVALUE = LOCALMAX(X, DIM) finds the location and value of the
%   most prominent local maximum along dimension DIM of matrix X. DIM specifies
%   the dimension along which to search for maxima (1 for columns, 2 for rows).
%   Returns MAXVALUE containing the max values. For rows/columns without
%   maxima, returns NaN.
%
%   MAXVALUE = LOCALMAX(X, DIM, 'Name', Value) specifies additional
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
%     % Find local maxima along rows (dim=2)
%     [maxValue, maxLoc] = localmax(X, 2);
%
%     % Plot results
%     figure;
%     subplot(2,1,1);
%     plot(t, signal1, 'b-', t(maxLoc(1)), maxValue(1), 'ro', 'MarkerFaceColor', 'r');
%     title('Signal 1 with Local Maximum');
%     subplot(2,1,2);
%     plot(t, signal2, 'g-', t(maxLoc(2)), maxValue(2), 'ro', 'MarkerFaceColor', 'r');
%     title('Signal 2 with Local Maximum');
%
%   See also ISLOCALMAX, MAX, FINDPEAKS
%
%   Status: Alpha


% Check number of input and output arguments
narginchk(2, 6);
nargoutchk(0, 2);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'localmax';
addRequired(parser, 'X', @(x) isnumeric(x) && ~isempty(x));
addRequired(parser, 'dim', @(x) isnumeric(x) && isscalar(x) && (x == 1 || x == 2));
addParameter(parser, 'MinProminence', 0, @(x) isnumeric(x) && isscalar(x) && x >= 0);
addParameter(parser, 'MinSeparation', 1, @(x) isnumeric(x) && isscalar(x) && x >= 1);

parse(parser, X, dim, varargin{:});

X = parser.Results.X;
dim = parser.Results.dim;
minProm = parser.Results.MinProminence;
minSep = parser.Results.MinSeparation;

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
