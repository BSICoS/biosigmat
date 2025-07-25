function metrics = tdmetrics(dtk)
% TDMETRICS Compute classical time domain indices for heart rate variability analysis.
%
%   METRICS = TDMETRICS(DTK) Computes standard time domain metrics used in heart rate
%   variability (HRV) analysis from interval series (dtk).
%
% Inputs:
%   dtk    - Interval series (in seconds) as a numeric vector
%
% Outputs:
%   metrics - Structure containing the following time domain metrics:
%       mhr    - Mean heart rate (beats/min)
%       sdnn   - Standard deviation of normal-to-normal (NN) intervals (ms)
%       sdsd   - Standard deviation of differences between adjacent NN intervals (ms)
%       rmssd  - Root mean square of successive differences of NN intervals (ms)
%       pNN50  - Proportion of interval differences > 50ms with respect to all NN intervals (%)
%
% EXAMPLE:
%   % Compute time domain metrics from interval series
%   tk = [0.8, 0.9, 1.0, 0.85, 0.95]; % Event times in seconds
%   dtk = diff(tk); % Compute intervals
%   metrics = tdmetrics(dtk);
%
% STATUS: Beta


% Check number of input and output arguments
narginchk(1, 1);
nargoutchk(0, 1);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'tdmetrics';
addRequired(parser, 'tk', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addOptional(parser, 'removeOutliers', true, @(x) islogical(x) && isscalar(x));

parse(parser, dtk);

dtk = parser.Results.tk(:);

% Compute successive differences
ddtk = diff(dtk);

% Compute time-domain metrics
mhr = mean(60 ./ dtk, 'omitnan');
sdnn = 1000 * std(dtk, 'omitnan');
rmssd = 1000 * norm(ddtk(~isnan(ddtk))) / sqrt(length(ddtk(~isnan(ddtk))));
sdsd = 1000 * std(ddtk, 'omitnan');
pNN50 = 100 * (sum(abs(ddtk) > 0.05)) / sum(~isnan(ddtk));

% Construct output structure
metrics.mhr = mhr;
metrics.sdnn = sdnn;
metrics.sdsd = sdsd;
metrics.rmssd = rmssd;
metrics.pNN50 = pNN50;

end