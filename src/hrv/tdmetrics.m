function metrics = tdmetrics(dtk)
% TDMETRICS Compute time-domain HRV metrics from interval series.
%
%   METRICS = TDMETRICS(DTK) computes standard time-domain heart-rate
%   variability metrics from the interval series DTK, expressed in seconds.
%
%   DTK must be a non-empty numeric vector. Positive finite values are treated
%   as valid intervals. NaN values are allowed as missing-interval markers and
%   are omitted before computing the metrics. Inf, zero and negative values are
%   rejected.
%
%   METRICS is a structure with fields:
%     mhr   - Mean heart rate in beats per minute.
%     sdnn  - Standard deviation of intervals in milliseconds.
%     sdsd  - Standard deviation of successive interval differences in ms.
%     rmssd - Root mean square of successive interval differences in ms.
%     pnn50 - Percentage of successive interval differences greater than 50 ms.
%   A metric is NaN when too few valid intervals exist to define it. If DTK
%   contains only NaN markers, every metric is NaN.
%
%   Example:
%     dtk = [0.80 0.82 NaN 0.79 0.81];
%     metrics = tdmetrics(dtk);
%
%   See also PANTOMPKINS

narginchk(1, 1);
nargoutchk(0, 1);

parser = inputParser;
parser.FunctionName = 'tdmetrics';
addRequired(parser, 'dtk', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
parse(parser, dtk);

dtk = parser.Results.dtk(:);

if any(isinf(dtk)) || any(dtk(~isnan(dtk)) <= 0)
    error('tdmetrics:InvalidInterval', ...
        'DTK must contain positive finite intervals or NaN markers.');
end

validDtk = dtk(~isnan(dtk));
if isempty(validDtk)
    metrics = struct( ...
        'mhr', NaN, ...
        'sdnn', NaN, ...
        'sdsd', NaN, ...
        'rmssd', NaN, ...
        'pnn50', NaN);
    return;
end

ddtk = diff(validDtk);

metrics.mhr = 60 / mean(validDtk);
if numel(validDtk) >= 2
    metrics.sdnn = 1000 * std(validDtk);
else
    metrics.sdnn = NaN;
end
if numel(ddtk) >= 2
    metrics.sdsd = 1000 * std(ddtk);
else
    metrics.sdsd = NaN;
end
if ~isempty(ddtk)
    metrics.rmssd = 1000 * norm(ddtk) / sqrt(length(ddtk));
    metrics.pnn50 = 100 * sum(abs(ddtk) > 0.05) / length(ddtk);
else
    metrics.rmssd = NaN;
    metrics.pnn50 = NaN;
end

end
