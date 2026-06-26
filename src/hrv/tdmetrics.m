function metrics = tdmetrics(dtk)
% TDMETRICS Compute standard time-domain indices for heart rate variability analysis.

narginchk(1, 1);
nargoutchk(0, 1);

parser = inputParser;
parser.FunctionName = 'tdmetrics';
addRequired(parser, 'dtk', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
parse(parser, dtk);

dtk = parser.Results.dtk(:);

if any(isinf(dtk)) || any(dtk(~isnan(dtk)) <= 0)
    error('biosigmat:TdmetricsInvalidInterval', ...
        'DTK must contain positive finite intervals or NaN markers.');
end

validDtk = dtk(~isnan(dtk));
if numel(validDtk) < 2
    error('biosigmat:TdmetricsInsufficientIntervals', ...
        'DTK must contain at least two valid intervals.');
end

ddtk = diff(validDtk);

metrics.mhr = 60 / mean(validDtk);
metrics.sdnn = 1000 * std(validDtk);
metrics.sdsd = 1000 * std(ddtk);
metrics.rmssd = 1000 * norm(ddtk) / sqrt(length(ddtk));
metrics.pNN50 = 100 * sum(abs(ddtk) > 0.05) / length(ddtk);

end
