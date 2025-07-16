function Output = tdmetrics(tm, removeOutliers)
% TDMETRICS Compute classical time domain indices for heart rate variability analysis
%
%   Computes standard time domain metrics used in heart rate variability (HRV) analysis
%   from a series of normal beat time occurrences. The function calculates various
%   statistical measures of RR intervals and their differences to quantify heart rate
%   variability patterns.
%
%   Output = tdmetrics(tm) computes time domain indices with outlier removal enabled by default.
%
%   Output = tdmetrics(tm, removeOutliers) allows specification of outlier handling.
%
% Inputs:
%   tm             - Normal beat time occurrence series (in seconds) as a numeric vector
%   removeOutliers - Optional. Logical flag to treat gaps as NaNs (default: true)
%
% Outputs:
%   Output - Structure containing the following time domain metrics:
%       MHR    - Mean heart rate (beats/min)
%       SDNN   - Standard deviation of normal-to-normal (NN) intervals (ms)
%       SDSD   - Standard deviation of differences between adjacent NN intervals (ms)
%       RMSSD  - Root mean square of successive differences of NN intervals (ms)
%       pNN50  - Proportion of interval differences > 50ms with respect to all NN intervals (%)


% Check number of input and output arguments
narginchk(1, 2);
nargoutchk(0, 1);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'tdmetrics';
addRequired(parser, 'tm', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addOptional(parser, 'removeOutliers', true, @(x) islogical(x) && isscalar(x));

parse(parser, tm, removeOutliers);

tm = parser.Results.tm(:);
removeOutliers = parser.Results.removeOutliers;

% Compute RR intervals from beat times
rr = diff(tm);

% Apply outlier removal if requested
if removeOutliers
    threshold = medfiltThreshold(rr);
    rr(rr > threshold) = nan;
end

% Compute successive differences of RR intervals
drr = diff(rr);

% Compute time domain indices
mhr = mean(60 ./ rr, 'omitnan');
sdnn = 1000 * std(rr, 'omitnan');
rmssd = 1000 * norm(drr(~isnan(drr))) / sqrt(length(drr(~isnan(drr))));
sdsd = 1000 * std(drr, 'omitnan');
pNN50 = 100 * (sum(abs(drr) > 0.050)) / sum(~isnan(drr));

% Construct output structure
Output.mhr = mhr;
Output.sdnn = sdnn;
Output.sdsd = sdsd;
Output.rmssd = rmssd;
Output.pNN50 = pNN50;

end