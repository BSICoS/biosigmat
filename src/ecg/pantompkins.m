function varargout = pantompkins(ecg, fs, varargin)
% PANTOMPKINS algorithm for R-wave detection in ECG signals
%
%   pantompkins(ECG, FS) Detects R-waves in ECG signal using the Pan-Tompkins
%              algorithm. This method applies bandpass filtering, derivative
%              calculation, squaring, and integration to enhance R-wave peaks.
%
%   TK = pantompkins(ECG, FS)
%       TK is a column vector containing the R-wave occurrence times in seconds.
%
%   [TK, ECGFILTERED, DECG, DECGENVELOPE] = pantompkins(...)
%       Returns additional outputs:
%       - ECGFILTERED: Bandpass filtered ECG signal
%       - DECG: Squared derivative of the filtered ECG signal
%       - DECGENVELOPE: Integrated envelope signal used for peak detection
%
%   pantompkins(..., 'Name', Value) specifies optional parameters using
%       name-value pair arguments:
%       - 'BandpassFreq': Two-element vector [low, high] for bandpass filter
%                        cutoff frequencies in Hz. Default: [5, 12]
%       - 'WindowSize': Integration window size in seconds. Default: 0.15
%       - 'MinPeakDistance': Minimum distance between peaks in seconds. Default: 0.5
%       - 'UseSnapToPeak': Logical flag to enable peak refinement using snaptopeak.
%                         Default: true
%       - 'SnapTopeakWindowSize': Window size in samples for peak refinement.
%                                Default: 20
%
% Inputs:
%   ECG - Single-lead ECG signal (numeric vector)
%   FS  - Sampling frequency in Hz (numeric scalar)

% Argument validation
narginchk(2, inf);
nargoutchk(0, 4);

% Parse input arguments
parser = inputParser;
parser.FunctionName = 'pantompkins';
addRequired(parser, 'ecg', @(x) isnumeric(x) && ~ischar(x) && isvector(x) && ~isscalar(x) && ~isempty(x));
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'BandpassFreq', [5, 12], @(x) isnumeric(x) && numel(x) == 2 && all(x > 0) && x(1) < x(2));
addParameter(parser, 'WindowSize', 0.15, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'MinPeakDistance', 0.5, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'UseSnapToPeak', true, @(x) islogical(x) && isscalar(x));
addParameter(parser, 'SnapTopeakWindowSize', 20, @(x) isnumeric(x) && isscalar(x) && x > 0);

parse(parser, ecg, fs, varargin{:});

ecg = parser.Results.ecg;
fs = parser.Results.fs;
bandpassFreq = parser.Results.BandpassFreq;
windowSizeSeconds = parser.Results.WindowSize;
minPeakDistanceSeconds = parser.Results.MinPeakDistance;
useSnapToPeak = parser.Results.UseSnapToPeak;
snapTopeakWindowSize = parser.Results.SnapTopeakWindowSize;

ecg = ecg(:);

% Bandpass filter the ECG signal. nanfiltfilt is used with maxgap = 0, so it will preserve NaNs.
[b, a] = butter(4, bandpassFreq / (fs / 2), 'bandpass');
ecgFiltered = nanfiltfilt(b, a, ecg, 0);

% Calculate the derivative of the filtered ECG signal
decg = diff(ecgFiltered);
decg = [decg(1); decg];

% Square the derivative to enhance R-wave peaks
decg = decg .^ 2;

% Integrate the squared derivative to obtain the R-wave envelope
windowSize = round(fs * windowSizeSeconds);
decgEnvelope = conv(decg, ones(windowSize, 1) / windowSize, 'same');

% Find peaks in the R-wave envelope
[~, locs] = findpeaks(decgEnvelope, 'MinPeakDistance', round(fs * minPeakDistanceSeconds));
locs = sort(locs);
locs = unique(locs);

% Refine peak locations using snaptopeak if enabled
if useSnapToPeak && ~isempty(locs)
    locs = snaptopeak(ecg, locs, 'WindowSize', snapTopeakWindowSize);
end

% Convert peak locations to time in seconds
tk = (locs - 1) / fs;

% Format output based on requested number of output arguments
varargout = {tk, ecgFiltered, decg, decgEnvelope};

end