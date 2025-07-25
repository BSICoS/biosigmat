function [sliced, tcenter] = slicesignal(x, window, overlap, fs)
% SLICESIGNAL Divide signal into overlapping segments.
%
%   [SLICED, TCENTER] = SLICESIGNAL(X, WINDOW, OVERLAP, FS) divides input
%   signal X into overlapping segments of specified length WINDOW samples.
%   OVERLAP specifies the number of overlapping samples between consecutive
%   segments, and FS is the sampling frequency in Hz. Each segment becomes
%   a column in the output matrix SLICED, making it suitable for spectral
%   analysis methods. TCENTER contains the time values in seconds
%   corresponding to the center of each slice.
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
%     % Slice the signal with 50% overlap
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
narginchk(4, 4);
nargoutchk(0, 2);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'slicesignal';
addRequired(parser, 'x', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'sliceLength', @(x) isnumeric(x) && isscalar(x) && x > 0 && x == round(x));
addRequired(parser, 'overlap', @(x) isnumeric(x) && isscalar(x) && x >= 0 && x == round(x));
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);
parse(parser, x, window, overlap, fs);

x = parser.Results.x;
window = parser.Results.sliceLength;
overlap = parser.Results.overlap;
fs = parser.Results.fs;

x = x(:);

% Validate overlap
if overlap >= window
    error('sliceSignal:invalidOverlap', ...
        'Overlap (%d) must be less than slice length (%d)', overlap, window);
end

% Calculate step size and number of slices
stepSize = window - overlap;
numSlices = floor((length(x) - overlap) / stepSize);

if numSlices < 1
    error('sliceSignal:signalTooShort', ...
        'Signal length (%d) is too short for slice length (%d)', length(x), window);
end

% Initialize time axis (center of each slice)
tcenter = (0:numSlices-1) * stepSize / fs + (window-1)/(2*fs);

% Create matrix with all slices as columns
sliced = zeros(window, numSlices);
for i = 1:numSlices
    startIdx = (i-1) * stepSize + 1;
    endIdx = startIdx + window - 1;
    sliced(:, i) = x(startIdx:endIdx);
end

% Ensure time output is column vector
tcenter = tcenter(:);

end
