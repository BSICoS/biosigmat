function varargout = pantompkins(ecg, fs, varargin)
% PANTOMPKINS Algorithm for R-wave detection in ECG signals.
%
%   RWAVETIMES = PANTOMPKINS(ECG, FS) Detects R-waves in ECG signals sampled at FS Hz
%   using the Pan-Tompkins algorithm. This method applies bandpass filtering,
%   derivative calculation, squaring, and integration to enhance R-wave peaks.
%   RWAVETIMES is a column vector containing the ECG R-wave occurrence times in seconds.
%
%   RWAVETIMES = PANTOMPKINS(..., Name, Value) allows specifying additional options using
%   name-value pairs.
%     'BandpassFreq'         -  Two-element vector [low, high] for bandpass filter
%                               cutoff frequencies in Hz. Default: [5, 12]
%     'WindowSize'           -  Integration window size in seconds. Default: 0.15
%     'MinPeakDistance'      -  Minimum distance between peaks in seconds. Default: 0.5
%     'SnapTopeakWindowSize' -  Window size in samples for peak refinement. Default: 20
%
%   [RWAVETIMES, ECGFILTERED, DECGSQUARED, DECGENVELOPE] = PANTOMPKINS(...) returns additional outputs:
%     ECGFILTERED  - Bandpass filtered ECG signal
%     DECGSQUARED  - Squared derivative of the filtered ECG signal
%     DECGENVELOPE - Integrated envelope signal used for peak detection
%
%   Example:
%     rWaveTimes = pantompkins(ecg, fs, 'BandpassFreq', [5, 12], ...
%         'WindowSize', 0.15, 'MinPeakDistance', 0.5, ...
%         'SnapTopeakWindowSize', 20);
%     plot(t, ecg); hold on;
%     plot(rWaveTimes, ecg(round(rWaveTimes*fs)), 'ro');
%     title('Detected R-waves in ECG Signal');
%
%   See also BASELINEREMOVE, LPDFILTER, FINDPEAKS


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
addParameter(parser, 'SnapTopeakWindowSize', 20, @(x) isnumeric(x) && isscalar(x) && x > 0);

parse(parser, ecg, fs, varargin{:});

ecg = parser.Results.ecg;
fs = parser.Results.fs;
bandpassFreq = parser.Results.BandpassFreq;
windowSizeSeconds = parser.Results.WindowSize;
minPeakDistanceSeconds = parser.Results.MinPeakDistance;
snapTopeakWindowSize = parser.Results.SnapTopeakWindowSize;

ecg = ecg(:);

% Bandpass filter the ECG signal. maxgap = 0, so it will preserve NaNs.
[b, a] = butter(4, bandpassFreq / (fs / 2), 'bandpass');
ecgFiltered = nanfiltfilt(b, a, ecg, 0);

% Calculate the derivative
b = lpdfilter(fs, bandpassFreq(2), 'Order', 4);
decg = nanfilter(b, 1, ecgFiltered, 0);

% Square the derivative to enhance R-wave peaks
decgSquared = decg .^ 2;

% Integrate the squared derivative to obtain the R-wave envelope
windowSize = round(fs * windowSizeSeconds);
decgEnvelope = conv(decgSquared, ones(windowSize, 1) / windowSize, 'same');

% Find peaks in the R-wave envelope
[~, locs] = findpeaks(decgEnvelope, 'MinPeakDistance', round(fs * minPeakDistanceSeconds));
locs = sort(locs);
locs = unique(locs);

% Refine peak locations using snaptopeak if enabled
if ~isempty(locs)
    locs = snaptopeak(ecg, locs, 'WindowSize', snapTopeakWindowSize);
    locs = locs(~isnan(locs));
end

% Convert peak locations to ECG R-wave occurrence times in seconds
rWaveTimes = (locs - 1) / fs;

% Format output based on requested number of output arguments
varargout = {rWaveTimes, ecgFiltered, decgSquared, decgEnvelope};

end
