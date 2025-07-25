function [pkl, akl] = peakedness(pxx, f, varargin)
% PEAKEDNESSComputes the peakedness of power spectral density estimates.
%
% [Pkl, Akl] = PEAKEDNESS(PXX, F, REFERENCEFREQ, WINDOW) calculates the
% peakedness of power spectral density estimates (PXX) at frequencies (F).
% It measures how concentrated the power is in a narrow frequency band
% compared to a wider band. The peakedness is defined as the percentage of
% power in a narrow window around a reference frequency compared to the
% power in a wider window. It also computes the absolute maximum peakedness
% as the percentage of the maximum power in the narrow window compared to
% the global maximum power in the spectrum.
%
% Inputs:
%   pxx           - Power spectral density estimates. Can be:
%                   - Column vector for single spectrum
%                   - Matrix with spectra as columns
%   f             - Frequency vector (Hz) corresponding to pxx
%   referenceFreq - (Optional) Reference frequency (Hz) for peakedness calculation.
%                   If not provided, uses adaptive method (spectrum maximum as center)
%   window        - (Optional) Search window bandwith centered around referenceFreq (Hz) [default: 0.125]
%
% Outputs:
%   pkl - Power concentration peakedness values (% of power in narrow vs wide window) (1 per spectrum in pxx)
%   akl - Absolute maximum peakedness values (% of max in window vs global max) (1 per spectrum in pxx)
%
% EXAMPLE:
%   % Generate a test spectrum with a peak at 0.3 Hz
%   f = 0:0.01:1;
%   pxx = exp(-((f-0.3)/0.05).^2) + 0.1*randn(size(f));
%   [pkl, akl] = peakedness(pxx, f, 0.3);
%   fprintf('Power concentration peakedness: %.1f%%\n', pkl);
%   fprintf('Absolute maximum peakedness: %.1f%%\n', akl);
%
%   % Use adaptive method (no reference frequency)
%   [pkl, akl] = peakedness(pxx, f);
%
%   % Use custom window with fixed method
%   [pkl, akl] = peakedness(pxx, f, 0.3, 0.2);
%
%   % Use custom window with adaptive method
%   [pkl, akl] = peakedness(pxx, f, [], 0.2);
%
% STATUS: Beta

% Check number of input and output arguments
narginchk(2, inf);
nargoutchk(0, 2);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'peakedness';
addRequired(parser, 'pxx', @(x) isnumeric(x) && ~isempty(x));
addRequired(parser, 'f', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addOptional(parser, 'referenceFreq', [], @(x) isnumeric(x) && isscalar(x) && isfinite(x));
addOptional(parser, 'window', 0.125, @(x) isnumeric(x) && isscalar(x) && x > 0);
parse(parser, pxx, f, varargin{:});

pxx = parser.Results.pxx;
f = parser.Results.f;
referenceFreq = parser.Results.referenceFreq;
window = parser.Results.window;

% Determine method automatically based on referenceFreq
useAdaptiveMethod = isempty(referenceFreq);

% Ensure f is a column vector
f = f(:);

% Ensure pxx is a matrix with spectra as columns
if isvector(pxx)
    pxx = pxx(:);
end

% Handle NaN values in pxx
if any(isnan(pxx(:)))
    pkl = NaN;
    akl = NaN;
    return;
end

% Validate dimensions
if size(pxx, 1) ~= length(f)
    error('peakedness:DimensionMismatch', ...
        'First dimension of pxx must match length of frequency vector f');
end

% Get number of spectra
numSpectra = size(pxx, 2);

% Pre-allocate output arrays
pkl = zeros(numSpectra, 1);
akl = zeros(numSpectra, 1);

% Calculate peakedness for each spectrum
for i = 1:numSpectra
    % Select current spectrum
    currentPxx = pxx(:, i);

    % Skip if spectrum contains only zeros or NaN
    if all(currentPxx == 0) || all(isnan(currentPxx))
        pkl(i) = 0;
        akl(i) = 0;
        continue;
    end

    % Determine center frequency for window definition
    if useAdaptiveMethod
        % Use spectrum maximum as reference
        [~, currentPxxMax] = max(currentPxx);
        centerFreq = f(currentPxxMax);
    else
        % Use provided reference frequency
        centerFreq = referenceFreq;
    end

    windowNarrow = 0.4*window;

    % Define search windows around center frequency
    searchWindowWide = f >= centerFreq - window/2 & f <= centerFreq + window/2;
    searchWindowNarrow = f >= centerFreq - windowNarrow/2 & f <= centerFreq + windowNarrow/2;

    % For adaptive method with initialization constraints (as in original code)
    if useAdaptiveMethod
        searchWindowNarrow = f >= max(centerFreq - windowNarrow/2, 0.15) & f <= min(centerFreq + windowNarrow/2, 0.8);
    end

    % Check if windows contain valid frequency points
    if ~any(searchWindowWide) || ~any(searchWindowNarrow)
        pkl(i) = 0;
        akl(i) = 0;
        continue;
    end

    % Calculate power concentration peakedness
    % Percentage of power in narrow window vs wide window
    powerInNarrowWindow = sum(currentPxx(searchWindowNarrow));
    powerInWideWindow = sum(currentPxx(searchWindowWide));

    if powerInWideWindow > 0
        pkl(i) = 100 * powerInNarrowWindow / powerInWideWindow;
    else
        pkl(i) = 0;
    end

    % Calculate absolute maximum peakedness
    % Percentage of maximum in window vs global maximum
    maxInWindow = max(currentPxx(searchWindowWide));
    globalMax = max(currentPxx);

    if globalMax > 0
        akl(i) = 100 * maxInWindow / globalMax;
    else
        akl(i) = 0;
    end

    % Ensure peakedness values are within 0-100% range
    pkl(i) = min(max(pkl(i), 0), 100);
    akl(i) = min(max(akl(i), 0), 100);
end
end
