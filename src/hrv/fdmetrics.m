function metrics = fdmetrics(pxx, varargin)
% FDMETRICS Compute standard frequency-domain indices for heart rate variability analysis.
%
%   METRICS = FDMETRICS(PXX, F) computes standard frequency-domain metrics used
%   in heart rate variability (HRV) analysis from the power spectral density PXX
%   of the HRV signal evaluated on the frequency vector F in hertz. METRICS contains the
%   following fields:
%     hf   - High-frequency power
%     lf   - Low-frequency power
%     lfn  - Normalized low-frequency power
%     lfhf - Low-frequency to high-frequency power ratio
%
%   METRICS = FDMETRICS(PXX, F, LIMITHF) controls the upper boundary of the
%   high-frequency band. When LIMITHF is true, the conventional 0.15 Hz to
%   0.4 Hz band is used. When LIMITHF is false, the high-frequency band extends
%   from 0.15 Hz to the highest frequency available in F. The default value is true.
%
%   METRICS = FDMETRICS(PXXRELATED, PXXUNRELATED, F) assumes that orthogonal
%   subspace projection (OSP) has been performed, where PXXRELATED contains the
%   HRV component linearly related to respiration and PXXUNRELATED contains the
%   HRV component not linearly related to respiration, and computes the following
%   fields from the separated spectra:
%     urlf - Unrelated low-frequency power
%     re   - Total respiration-related power
%     r    - Unrelated-to-total power ratio
%
%   FDMETRICS emits the warning identifiers
%   biosigmat:fdmetrics:excessive_vlf_power and
%   biosigmat:fdmetrics:zero_required_power for the corresponding Biosiglib
%   diagnostic conditions. Each warning aggregates all affected spectra or
%   required powers in one message.
%
%   Example:
%     % Compute frequency-domain HRV metrics from a synthetic spectrum
%     f = linspace(0, 0.5, 512)';
%     pxx = 0.01 * exp(-((f - 0.1) / 0.03).^2) + 0.02 * exp(-((f - 0.25) / 0.04).^2);
%     metrics = fdmetrics(pxx, f, false);
%
%     % Plot the spectrum and show the computed bands
%     figure;
%     plot(f, pxx);
%     xlabel('Frequency (Hz)');
%     ylabel('Power spectral density');
%     title(sprintf('LF/HF = %.2f', metrics.lfhf));
%
%   See also NANPWELCH, PWELCH, OSP


% Check number of input and output arguments
narginchk(2, 3);
nargoutchk(0, 1);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'fdmetrics';
addRequired(parser, 'pxx', @(x) isnumeric(x) && isreal(x) && isvector(x) && ~isempty(x) && ...
    all(~isinf(x)) && all(x(~isnan(x)) >= 0));
addRequired(parser, 'secondInput', @(x) isnumeric(x) && isreal(x) && isvector(x) && ~isempty(x) && ...
    all(~isinf(double(x))) && all(double(x(~isnan(double(x)))) >= 0));
addOptional(parser, 'thirdInput', [], @(x) isempty(x) || ...
    (islogical(x) && isscalar(x)) || (isnumeric(x) && isreal(x) && ...
    isvector(x) && ~isempty(x) && all(isfinite(x)) && all(x >= 0)));

parse(parser, pxx, varargin{:});

firstPxx = parser.Results.pxx(:);
secondInput = parser.Results.secondInput;
thirdInput = parser.Results.thirdInput;

% Dispatch between single-spectrum mode and OSP-separated spectra mode.
isTwoSpectrumMode = nargin == 3 && isnumeric(thirdInput) && ~islogical(thirdInput);

if isTwoSpectrumMode
    relatedPxx = firstPxx;
    unrelatedPxx = secondInput(:);
    f = thirdInput(:);
    metrics.urlf = nan;
    metrics.re = nan;
    metrics.r = nan;

    if numel(unrelatedPxx) ~= numel(relatedPxx)
        error('fdmetrics:SpectrumLengthMismatch', ...
            'pxxRelated and pxxUnrelated must have the same number of samples.');
    end

    if numel(f) ~= numel(relatedPxx)
        error('fdmetrics:FrequencyLengthMismatch', ...
            'f and the input spectra must have the same number of samples.');
    end
else
    pxx = firstPxx;
    f = secondInput(:);
    limitHf = true;
    metrics.hf = nan;
    metrics.lf = nan;
    metrics.lfn = nan;
    metrics.lfhf = nan;

    if nargin == 3
        if ~(islogical(thirdInput) && isscalar(thirdInput))
            error('fdmetrics:InvalidThirdInput', ...
                'The third input must be a logical scalar or a frequency vector.');
        end
        limitHf = thirdInput;
    end

    if numel(f) ~= numel(pxx)
        error('fdmetrics:FrequencyLengthMismatch', ...
            'f and pxx must have the same number of samples.');
    end
end

if any(~isfinite(f)) || any(f < 0)
    error('fdmetrics:InvalidFrequencyVector', ...
        'f must contain finite, nonnegative frequencies.');
end

if any(diff(f) <= 0)
    error('fdmetrics:NonIncreasingFrequencyVector', ...
        'f must be strictly increasing.');
end

if isTwoSpectrumMode
    if any(isnan(relatedPxx)) || any(isnan(unrelatedPxx))
        return;
    end

    vlfAffectedIds = {};
    if hasExcessiveVlfPower(relatedPxx, f)
        vlfAffectedIds{end + 1} = 'related_pxx'; %#ok<AGROW>
    end
    if hasExcessiveVlfPower(unrelatedPxx, f)
        vlfAffectedIds{end + 1} = 'unrelated_pxx'; %#ok<AGROW>
    end
    if ~isempty(vlfAffectedIds)
        emitFdmetricsWarning('excessive_vlf_power', vlfAffectedIds);
    end

    lfStartIndex = find(f >= 0.04, 1);
    lfEndIndex = find(f >= 0.15, 1);
    if isempty(lfStartIndex) || isempty(lfEndIndex)
        return;
    end

    % OSP mode reports only respiration-related and unrelated LF metrics.
    rawRe = trapz(f, relatedPxx);
    rawUrlf = trapz(f(lfStartIndex:lfEndIndex), ...
        unrelatedPxx(lfStartIndex:lfEndIndex));
    if rawUrlf == 0
        emitFdmetricsWarning('zero_required_power', {'urlf'});
        return;
    end

    metrics.re = rawRe;
    if metrics.re > 0.05
        metrics.re = nan;
    end

    metrics.urlf = rawUrlf;
    if metrics.urlf > 0.003
        metrics.urlf = nan;
    end

    metrics.r = metrics.urlf / (metrics.re + metrics.urlf);
    return;
end

if any(isnan(pxx))
    return;
end

if hasExcessiveVlfPower(pxx, f)
    emitFdmetricsWarning('excessive_vlf_power', {'pxx'});
end

lfStartIndex = find(f >= 0.04, 1);
lfEndIndex = find(f >= 0.15, 1);
if isempty(lfStartIndex) || isempty(lfEndIndex)
    return;
end

hfStartIndex = lfEndIndex;

% The HF upper bound is either capped at 0.4 Hz or left unconstrained.
if limitHf
    if f(end) < 0.4
        hfEndIndex = numel(f);
    else
        hfEndIndex = find(f >= 0.4, 1);
    end
else
    hfEndIndex = numel(f);
end

if isempty(hfStartIndex) || isempty(hfEndIndex) || hfStartIndex > hfEndIndex
    return;
end

% Integrate the conventional LF and HF bands atomically.
rawHf = trapz(f(hfStartIndex:hfEndIndex), pxx(hfStartIndex:hfEndIndex));
rawLf = trapz(f(lfStartIndex:lfEndIndex), pxx(lfStartIndex:lfEndIndex));
zeroAffectedIds = {};
if rawHf == 0
    zeroAffectedIds{end + 1} = 'hf'; %#ok<AGROW>
end
if rawLf == 0
    zeroAffectedIds{end + 1} = 'lf'; %#ok<AGROW>
end
if ~isempty(zeroAffectedIds)
    emitFdmetricsWarning('zero_required_power', zeroAffectedIds);
    return;
end

metrics.hf = rawHf;
metrics.lf = rawLf;
metrics.lfn = metrics.lf / (metrics.lf + metrics.hf);
metrics.lfhf = metrics.lf / metrics.hf;

end

function isExcessive = hasExcessiveVlfPower(spectrum, f)
isExcessive = false;
if ~any(f < 0.04)
    return;
end

vlfEndIndex = find(f >= 0.04, 1);
if isempty(vlfEndIndex)
    return;
end

vlfPower = trapz(f(1:vlfEndIndex), spectrum(1:vlfEndIndex));
restPower = trapz(f(vlfEndIndex:end), spectrum(vlfEndIndex:end));
if restPower == 0
    isExcessive = vlfPower > 0;
else
    isExcessive = vlfPower / restPower > 0.05;
end
end

function emitFdmetricsWarning(warningId, affectedIds)
warning(['biosigmat:fdmetrics:' warningId], ...
    '%s affected_ids: %s', warningId, strjoin(affectedIds, ', '));
end
