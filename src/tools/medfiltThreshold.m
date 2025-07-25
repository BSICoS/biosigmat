function threshold = medfiltThreshold(x, window, factor, maxthreshold)
% MEDFILTTHRESHOLD Compute median-filtered adaptive threshold.
%
%   THRESHOLD = MEDFILTTHRESHOLD(X, WINDOW, FACTOR, MAXTHRESHOLD) computes an
%   adaptive threshold for identifying outliers in a series using median filtering.
%   The threshold is based on a median-filtered version of the series, with padding
%   at the boundaries to handle edge effects. THRESHOLD is the adaptive threshold
%   values, same length as X, computed as FACTOR times the median-filtered signal,
%   capped at MAXTHRESHOLD.
%
%   Example:
%     % Create sample series with outliers
%     x = [0.8, 0.82, 0.81, 1.2, 0.79, 0.83, 0.80]';
%
%     % Compute adaptive threshold
%     threshold = medfiltThreshold(x, 5, 1.5, 1.5);
%
%     % Identify outliers
%     outliers = x > threshold;
%
%   See also MEDFILT1, MOVMEDIAN


% Check number of input and output arguments
narginchk(4, 4);
nargoutchk(0, 1);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'medfiltThreshold';
addRequired(parser, 'x', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'window', @(x) isnumeric(x) && isscalar(x) && x > 0 && x == round(x));
addRequired(parser, 'factor', @(x) isnumeric(x) && isscalar(x) && x > 0);
addRequired(parser, 'maxthreshold', @(x) isnumeric(x) && isscalar(x) && x > 0);

parse(parser, x, window, factor, maxthreshold);

x = parser.Results.x(:);
window = parser.Results.window;
factor = parser.Results.factor;
maxthreshold = parser.Results.maxthreshold;

if length(x) < window
    window = length(x);
end

% Ensure window is odd for symmetric median filtering
halfWindow = floor(window / 2);

% Apply median filtering with boundary padding
mf = medfilt1([flipud(x(1:halfWindow)); x; flipud(x(end-halfWindow+1:end))], window-1);
threshold = factor * (mf(halfWindow+1:end-halfWindow));
threshold(threshold > maxthreshold) = maxthreshold;

end