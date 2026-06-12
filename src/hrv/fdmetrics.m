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
addRequired(parser, 'pxx', @(x) isnumeric(x) && isvector(x) && ~isempty(x) && ...
    all(~isinf(x)) && all(x(~isnan(x)) >= 0));
addRequired(parser, 'secondInput', @(x) (isnumeric(x) || islogical(x)) && isvector(x) && ~isempty(x) && ...
    all(~isinf(double(x))) && all(double(x(~isnan(double(x)))) >= 0));
addOptional(parser, 'thirdInput', [], @(x) isempty(x) || ...
    (islogical(x) && isscalar(x)) || (isnumeric(x) && isvector(x) && ~isempty(x) && all(isfinite(x))));

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

if any(diff(f) <= 0)
    error('fdmetrics:NonIncreasingFrequencyVector', ...
        'f must be strictly increasing.');
end

% The LF band is shared by both operating modes.
lfStartIndex = find(f >= 0.04, 1);
lfEndIndex = find(f >= 0.15, 1);

if isempty(lfStartIndex) || isempty(lfEndIndex) || lfStartIndex > lfEndIndex
    return;
end

if isTwoSpectrumMode
    if any(isnan(relatedPxx)) || any(isnan(unrelatedPxx))
        return;
    end

    % OSP mode reports only respiration-related and unrelated LF metrics.
    metrics.re = trapz(f, relatedPxx);
    if metrics.re > 0.05
        metrics.re = nan;
    end

    metrics.urlf = trapz(f(lfStartIndex:lfEndIndex), unrelatedPxx(lfStartIndex:lfEndIndex));
    if metrics.urlf > 0.003
        metrics.urlf = nan;
    end

    metrics.r = metrics.urlf / (metrics.re + metrics.urlf);
    return;
end

if any(isnan(pxx))
    return;
end

hfStartIndex = find(f >= 0.15, 1);

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

% Integrate the conventional LF and HF bands.
metrics.hf = trapz(f(hfStartIndex:hfEndIndex), pxx(hfStartIndex:hfEndIndex));
if metrics.hf > 15000
    metrics.hf = nan;
end

metrics.lf = trapz(f(lfStartIndex:lfEndIndex), pxx(lfStartIndex:lfEndIndex));
if metrics.lf > 15000
    metrics.lf = nan;
end

metrics.lfn = metrics.lf / (metrics.lf + metrics.hf);
metrics.lfhf = metrics.lf / metrics.hf;

end
