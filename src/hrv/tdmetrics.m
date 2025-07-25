function metrics = tdmetrics(dtk)
% TDMETRICS Compute standard time-domain indices for heart rate variability analysis.
%
%   METRICS = TDMETRICS(DTK) computes standard time-domain metrics used in heart rate
%   variability (HRV) analysis from interval series (DTK). METRICS is a structure
%   containing the following time-domain metrics:
%     MHR   - Mean heart rate (beats/min)
%     SDNN  - Standard deviation of normal-to-normal (NN) intervals (ms)
%     SDSD  - Standard deviation of differences between adjacent NN intervals (ms)
%     RMSSD - Root mean square of successive differences of NN intervals (ms)
%     PNN50 - Proportion of interval differences > 50ms with respect to all NN intervals (%)
%
%   Example:
%     % Compute time domain metrics from R-R interval series
%     load('ecg_data.mat'); % Load ECG data
%     rpeaks = pantompkins(ecg, fs); % Detect R-peaks
%     dtk = diff(rpeaks); % Compute R-R intervals
%     metrics = tdmetrics(dtk);
%
%     % Display results
%     fprintf('Mean HR: %.1f bpm\n', metrics.mhr);
%     fprintf('SDNN: %.1f ms\n', metrics.sdnn);
%     fprintf('RMSSD: %.1f ms\n', metrics.rmssd);
%     fprintf('SDSD: %.1f ms\n', metrics.sdsd);
%     fprintf('pNN50: %.1f %%\n', metrics.pNN50);
%
%   See also PANTOMPKINS


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