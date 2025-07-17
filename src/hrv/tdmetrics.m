function Output = tdmetrics(dtk)
% TDMETRICS Compute classical time domain indices for heart rate variability analysis
%
%   Computes standard time domain metrics used in heart rate variability (HRV) analysis
%   from a series of event time occurrences.
%
%   Output = tdmetrics(dtk) computes time domain indices from interval series (dtk).
%
% Inputs:
%   dtk    - Interval series (in seconds) as a numeric vector
%
% Outputs:
%   Output - Structure containing the following time domain metrics:
%       mhr    - Mean heart rate (beats/min)
%       sdnn   - Standard deviation of normal-to-normal (NN) intervals (ms)
%       sdsd   - Standard deviation of differences between adjacent NN intervals (ms)
%       rmssd  - Root mean square of successive differences of NN intervals (ms)
%       pNN50  - Proportion of interval differences > 50ms with respect to all NN intervals (%)


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
Output.mhr = mhr;
Output.sdnn = sdnn;
Output.sdsd = sdsd;
Output.rmssd = rmssd;
Output.pNN50 = pNN50;

end