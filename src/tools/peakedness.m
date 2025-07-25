function [pkl, akl] = peakedness(pxx, f, varargin)
% PEAKEDNESS Computes the peakedness of power spectral density estimates.
%
%   [PKL, AKL] = PEAKEDNESS(PXX, F) calculates the peakedness of power
%   spectral density estimates PXX at frequencies F using an adaptive method
%   that automatically determines the reference frequency as the spectrum
%   maximum. PXX can be a column vector for a single spectrum or a matrix
%   with spectra as columns. F is the frequency vector in Hz corresponding
%   to PXX. Returns PKL (power concentration peakedness) and AKL (absolute
%   maximum peakedness), both as percentages.
%
%   The peakedness measures how concentrated the power is in a narrow
%   frequency band compared to a wider band. Power concentration peakedness
%   (PKL) is the percentage of power in a narrow window compared to power in
%   a wider window. Absolute maximum peakedness (AKL) is the percentage of
%   the maximum power in the window compared to the global maximum power.
%
%   [PKL, AKL] = PEAKEDNESS(PXX, F, REFERENCEFREQ) uses a fixed reference
%   frequency REFERENCEFREQ in Hz for peakedness calculation instead of the
%   adaptive method.
%
%   [PKL, AKL] = PEAKEDNESS(PXX, F, REFERENCEFREQ, WINDOW) additionally
%   specifies the search window bandwidth WINDOW in Hz centered around the
%   reference frequency. Default window size is 0.125 Hz. Use empty array
%   [] for REFERENCEFREQ to use adaptive method with custom window.
%
%   Example:
%     % Generate a test spectrum with a peak at 0.3 Hz
%     f = 0:0.01:1;
%     pxx = exp(-((f-0.3)/0.05).^2) + 0.1*randn(size(f));
%
%     % Calculate peakedness using fixed reference frequency
%     [pkl, akl] = peakedness(pxx, f, 0.3);
%
%   See also NANPWELCH, PWELCH


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
