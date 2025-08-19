function [sliced, tcenter] = slicesignal(x, window, overlap, varargin)
% SLICESIGNAL Divide signal into overlapping segments.
%
%   SLICED = SLICESIGNAL(X, WINDOW, OVERLAP) divides input signal X into
%   overlapping segments of specified length WINDOW samples. OVERLAP
%   specifies the number of overlapping samples between consecutive
%   segments. Each segment becomes a column in the output matrix SLICED,
%   making it suitable for spectral analysis methods.
%
%   SLICED = SLICESIGNAL(..., FS) includes the sampling
%   frequency FS in Hz, which is required when requesting time center
%   output (TCENTER).
%
%   SLICED = SLICESIGNAL(..., 'Uselast', true) if true, the last segment
%   will be included in the slicing, with nan padding to ensure it has the
%   same length as the other segments. This option is set to false by default.
%
%   [SLICED, TCENTER] = SLICESIGNAL(...) returns TCENTER, the time values
%   in seconds corresponding to the center of each slice. When requesting
%   TCENTER output, FS parameter is required.
%
%   This function is particularly useful for time-frequency analysis where
%   you need to apply spectral analysis methods like pwelch or periodogram
%   to multiple overlapping segments of a signal.
%
%   Example:
%     % Create a chirp signal and slice it for time-frequency analysis
%     fs = 1000;
%     t = (0:1/fs:2)';
%     x = chirp(t, 10, 2, 50) + 0.1*randn(size(t));
%
%     % Slice the signal with 50% overlap (without time information)
%     sliced = slicesignal(x, 256, 128);
%
%     % Slice with time center information (fs required)
%     [sliced, tcenter] = slicesignal(x, 256, 128, fs);
%
%     % Compute power spectral density for each slice
%     [pxx, f] = pwelch(sliced, [], [], [], fs);
%
%     % Create time-frequency map
%     figure;
%     imagesc(tcenter, f, 10*log10(pxx));
%     axis xy;
%     xlabel('Time (s)');
%     ylabel('Frequency (Hz)');
%     title('Time-Frequency Spectrogram');
%     colorbar;
%
%   See also PWELCH, SPECTROGRAM, PERIODOGRAM


% Check number of input and output arguments
narginchk(3, 6);
nargoutchk(0, 2);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'slicesignal';
addRequired(parser, 'x', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'sliceLength', @(x) isnumeric(x) && isscalar(x) && x > 0 && x == round(x));
addRequired(parser, 'overlap', @(x) isnumeric(x) && isscalar(x) && x >= 0 && x == round(x));
addOptional(parser, 'fs', [], @(x) isnumeric(x) && isscalar(x) && x > 0);
addOptional(parser, 'uselast', false, @(x) islogical(x) && isscalar(x));
parse(parser, x, window, overlap, varargin{:});

x = parser.Results.x;
window = parser.Results.sliceLength;
overlap = parser.Results.overlap;
fs = parser.Results.fs;
uselast = parser.Results.uselast;

% Validate that fs is provided when tcenter is requested
if nargout == 2 && isempty(fs)
    error('slicesignal:missingFs', ...
        'Sampling frequency (fs) is required when requesting time center output (tcenter)');
end

x = x(:);

% Validate overlap
if overlap >= window
    error('sliceSignal:invalidOverlap', ...
        'Overlap (%d) must be less than slice length (%d)', overlap, window);
end

% Calculate step size and number of slices
stepSize = window - overlap;
if uselast
    % Include last segment even if it is shorter than window
    numSlices = ceil((length(x) - overlap) / stepSize);
else
    % Exclude last segment if it does not fill the window
    numSlices = floor((length(x) - overlap) / stepSize);
end

if numSlices < 1
    error('sliceSignal:signalTooShort', ...
        'Signal length (%d) is too short for slice length (%d). You may use the ''uselast'' option to force zero-padding.', length(x), window);
end

% Initialize time axis (center of each slice) only if fs is provided
if ~isempty(fs)
    tcenter = (0:numSlices-1) * stepSize / fs + (window-1)/(2*fs);
else
    tcenter = [];
end

% Create matrix with all slices as columns
sliced = zeros(window, numSlices);
for i = 1:numSlices
    startIdx = (i-1) * stepSize + 1;
    endIdx = startIdx + window - 1;
    if endIdx > length(x)
        endIdx = length(x);
        sliced(:, i) = [x(startIdx:endIdx); nan(window - (endIdx - startIdx + 1), 1)];
    else
        sliced(:, i) = x(startIdx:endIdx);
    end
end

% Ensure time output is column vector
if ~isempty(tcenter)
    tcenter = tcenter(:);
end

end
