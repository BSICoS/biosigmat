function [sliced, tcenter] = slicesignal(x, window, overlap, fs)
% SLICESIGNAL Divide signal into overlapping segments
%
% This function divides a signal into overlapping segments of specified length.
% Each segment becomes a column in the output matrix, making it easy to apply
% spectral analysis methods like periodogram or pwelch to multiple segments.
%
% Inputs:
%   x - Input signal (numeric column vector)
%   window - Length of each slice in samples (scalar)
%   overlap - Number of overlapping samples between slices (scalar)
%   fs - Sample rate in Hz (scalar)
%
% Outputs:
%   sliced - Matrix where each column is a signal segment
%   tcenter - Time axis in seconds corresponding to center of each slice (column vector)
%
% Example:
%   % Slice a signal and compute time-frequency map with pwelch
%   fs = 1000;
%   tSignal = (0:1/fs:2)';
%   x = chirp(tSignal, 10, 2, 50);
%   [sliced, tcenter] = slicesignal(x, 256, 128, fs);
%   [pxx, f] = pwelch(sliced, [], [], [], fs);
%   imagesc(tcenter, f, 10*log10(pxx));
%   axis xy;
%   xlabel('Time (s)');
%   ylabel('Frequency (Hz)');
%   title('Time-Frequency Map');

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
