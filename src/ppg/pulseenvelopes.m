function [lowerEnvelope, upperEnvelope] = pulseenvelopes(ppg, fs, nD, varargin)
% PULSEENVELOPES Estimates lower and upper PPG envelopes using pulse-anchored interpolation.
%
%   LOWERENVELOPE = PULSEENVELOPES(PPG, FS, ND) estimates the lower envelope of
%   a photoplethysmographic (PPG) signal by selecting one local minimum per
%   pulse within a window before each pulse detection time ND and
%   interpolating these anchor points. PPG is a numeric vector, FS is the
%   sampling rate in Hz (positive scalar), and ND contains pulse detection
%   times in seconds (typically returned by pulsedetection). LOWERENVELOPE is
%   a column vector with the same length as PPG.
%
%   [LOWERENVELOPE, UPPERENVELOPE] = PULSEENVELOPES(PPG, FS, ND) also returns
%   the upper envelope by selecting one local maximum per pulse within a
%   window after each detection and interpolating these anchor points.
%
%   [...] = PULSEENVELOPES(..., 'Name', Value) specifies additional
%   parameters using name-value pairs:
%     'WindowA'  - Window width in seconds for searching the upper envelope
%                  after each detection (default: 400e-3)
%     'WindowB'  - Window width in seconds for searching the lower envelope
%                  before each detection (default: 300e-3)
%
%   Example:
%     % Pulse detection on the LPD-filtered signal
%     [b, delay] = lpdfilter(fs, 8, 'PassFreq', 7.8, 'Order', 100);
%     dppg = filter(b, 1, ppg);
%     dppg = [dppg(delay+1:end); zeros(delay, 1)];
%     nD = pulsedetection(dppg, fs);
%
%     % Estimate envelopes
%     [lowerEnv, upperEnv] = pulseenvelopes(ppg, fs, nD);
%
%     t = (0:length(ppg)-1)/fs;
%     figure;
%     plot(t, ppg, 'k'); hold on;
%     plot(t, lowerEnv, 'b', 'LineWidth', 1.5);
%     plot(t, upperEnv, 'r', 'LineWidth', 1.5);
%     legend('PPG', 'Lower envelope', 'Upper envelope');
%     xlabel('Time (s)'); ylabel('Amplitude');
%
%   See also PULSEDETECTION, PULSEDELINEATION, INTERP1
%
%   Status: Beta


% Check number of input and output arguments
narginchk(3, 7);
nargoutchk(0, 2);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'pulseenvelopes';
addRequired(parser, 'ppg', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);
addRequired(parser, 'nD', @(x) isnumeric(x) && (isvector(x) || isempty(x)));
addParameter(parser, 'WindowA', 400e-3, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'WindowB', 300e-3, @(x) isnumeric(x) && isscalar(x) && x > 0);

parse(parser, ppg, fs, nD, varargin{:});

ppg = parser.Results.ppg;
fs = parser.Results.fs;
nD = parser.Results.nD;
windowA = parser.Results.WindowA;
windowB = parser.Results.WindowB;

% Normalize signal shape
ppg = ppg(:);
ppgLength = length(ppg);
t = (0:ppgLength-1)'/fs;

% Clean detections
nD = nD(:);
nD = nD(~isnan(nD));
nD = unique(nD, 'sorted');

lowerEnvelope = NaN(ppgLength, 1);
upperEnvelope = NaN(ppgLength, 1);

if isempty(nD)
    warning('pulseenvelopes:emptyDetections', ...
        'No pulse detections provided; returning NaN envelopes.');
    return;
end

% Convert detection times to samples (MATLAB 1-based indexing)
detectionSamples = 1 + round(nD*fs);

% --- Lower envelope (search backward for minima) ---
windowBSamples = round(windowB*fs);
startSamplesLower = detectionSamples - windowBSamples;
searchOffsetsLower = 0:windowBSamples;
searchMatrixLower = repmat(searchOffsetsLower, length(startSamplesLower), 1) + startSamplesLower;
searchMatrixLower = max(1, min(searchMatrixLower, ppgLength));

[~, locsLower] = min(ppg(searchMatrixLower), [], 2);
anchorSamplesLower = startSamplesLower + (locsLower - 1);
anchorSamplesLower(anchorSamplesLower < 1 | anchorSamplesLower > ppgLength) = NaN;
anchorSamplesLower = unique(anchorSamplesLower(~isnan(anchorSamplesLower)));

if numel(anchorSamplesLower) >= 2
    lowerEnvelope = interp1(t(anchorSamplesLower), ppg(anchorSamplesLower), t, 'pchip', NaN);
    lowerEnvelope(t < nD(1)) = NaN;
    lowerEnvelope(t > nD(end)) = NaN;
else
    warning('pulseenvelopes:insufficientLowerAnchors', ...
        'Not enough anchor points to interpolate the lower envelope; returning NaNs.');
end

% If only one output requested, do not compute the upper envelope
if nargout < 2
    return;
end

% --- Upper envelope (search forward for maxima) ---
windowASamples = round(windowA*fs);
startSamplesUpper = detectionSamples;
searchOffsetsUpper = 0:windowASamples;
searchMatrixUpper = repmat(searchOffsetsUpper, length(startSamplesUpper), 1) + startSamplesUpper;
searchMatrixUpper = max(1, min(searchMatrixUpper, ppgLength));

[~, locsUpper] = max(ppg(searchMatrixUpper), [], 2);
anchorSamplesUpper = startSamplesUpper + (locsUpper - 1);
anchorSamplesUpper(anchorSamplesUpper < 1 | anchorSamplesUpper > ppgLength) = NaN;
anchorSamplesUpper = unique(anchorSamplesUpper(~isnan(anchorSamplesUpper)));

if numel(anchorSamplesUpper) >= 2
    upperEnvelope = interp1(t(anchorSamplesUpper), ppg(anchorSamplesUpper), t, 'pchip', NaN);
    upperEnvelope(t < nD(1)) = NaN;
    upperEnvelope(t > nD(end)) = NaN;
else
    warning('pulseenvelopes:insufficientUpperAnchors', ...
        'Not enough anchor points to interpolate the upper envelope; returning NaNs.');
end

end
