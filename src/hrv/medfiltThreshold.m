function threshold = medfiltThreshold(dtk, varargin)
% MEDFILTTHRESHOLD Compute adaptive threshold for outlier detection in RR intervals
%
%   Computes an adaptive threshold for identifying outliers in interval series
%   using median filtering. The threshold is based on a median-filtered version
%   of the interval series, with padding at the boundaries to handle edge effects.
%
% Inputs:
%   dtk    - Interval series (in seconds) as a numeric vector
%   window - Optional. Window size for median filtering (default: 50)
%   factor - Optional. Multiplicative factor for threshold computation (default: 1.5)
%   maxthreshold - Optional. Maximum threshold value (default: 1.5)
%
% Outputs:
%   threshold - Adaptive threshold values for outlier detection


% Check number of input and output arguments
narginchk(1, 4);
nargoutchk(0, 1);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'medfiltThreshold';
addRequired(parser, 'dtk', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addOptional(parser, 'window', 50, @(x) isnumeric(x) && isscalar(x) && x > 0 && x == round(x));
addOptional(parser, 'factor', 1.5, @(x) isnumeric(x) && isscalar(x) && x > 0);
addOptional(parser, 'maxthreshold', 1.5, @(x) isnumeric(x) && isscalar(x) && x > 0);

parse(parser, dtk, varargin{:});

dtk = parser.Results.dtk(:);
window = parser.Results.window;
factor = parser.Results.factor;
maxthreshold = parser.Results.maxthreshold;

if length(dtk) < window
    window = length(dtk);
end

% Ensure window is odd for symmetric median filtering
halfWindow = floor(window / 2);

% Apply median filtering with boundary padding
mf = medfilt1([flipud(dtk(1:halfWindow)); dtk; flipud(dtk(end-halfWindow+1:end))], window-1);
mf(mf > maxthreshold) = maxthreshold;
threshold = factor * (mf(halfWindow+1:end-halfWindow));

end