function [tA, tB, tM] = pulsedelineation(ppg, fs, tD, varargin)
% PULSEDELINEATION Performs pulse delineation in PPG signals using adaptive thresholding.
%
%   [TA, TB, TM] = PULSEDELINEATION(PPG, FS, TD) performs pulse
%   delineation in photoplethysmographic (PPG) signals, detecting
%   pulse features (tA, tB, tM) based on pulse detection points (tD).
%   FS is the sampling rate in Hz (positive scalar). TA returns pulse
%   onset locations in seconds, TB returns pulse offset locations in
%   seconds, and TM returns pulse midpoint locations in seconds.
%
%   [TA, TB, TM] = PULSEDELINEATION(..., 'Name', Value) specifies additional
%   parameters using name-value pairs:
%     'WindowA'  - Window width for searching pulse onset in seconds
%                  (default: 250e-3)
%     'WindowB'  - Window width for searching pulse offset in seconds
%                  (default: 150e-3)
%
%   Example:
%     % Load PPG signal and apply LPD filtering
%     ppgData = readtable('ppg_signals.csv');
%     ppg = ppgData.sig(1:30000);
%     fs = 1000;
%
%     % Apply LPD filter
%     [b, delay] = lpdfilter(fs, 8, 'PassFreq', 7.8, 'Order', 100);
%     dppg = filter(b, 1, ppg);
%     dppg = [dppg(delay+1:end); zeros(delay, 1)];
%
%     % Compute pulse detection points
%     tD = pulsedetection(dppg, fs);
%
%     % Perform pulse delineation
%     [tA, tB, tM] = pulsedelineation(ppg, fs, tD);
%
%     % Plot results
%     t = (0:length(ppg)-1)/fs;
%     figure;
%     plot(t, ppg, 'k');
%     hold on;
%     plot(tA, ppg(1+round(tA*fs)), 'ro', 'MarkerFaceColor', 'r');
%     plot(tB, ppg(1+round(tB*fs)), 'go', 'MarkerFaceColor', 'g');
%     plot(tM, ppg(1+round(tM*fs)), 'bo', 'MarkerFaceColor', 'b');
%     legend('PPG Signal', 'Onset (tA)', 'Offset (tB)', 'Midpoint (tM)');
%     xlabel('Time (s)');
%     ylabel('Amplitude');
%     title('PPG Pulse Delineation');
%
%   See also PULSEDETECTION, LPDFILTER


% Check number of input and output arguments
narginchk(3, 9);
nargoutchk(0, 3);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'pulsedelineation';
addRequired(parser, 'ppg', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);
addRequired(parser, 'tD', @(x) isnumeric(x) && (isvector(x) || isempty(x)));
addParameter(parser, 'WindowA', 250e-3, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'WindowB', 150e-3, @(x) isnumeric(x) && isscalar(x) && x > 0);

parse(parser, ppg, fs, tD, varargin{:});

ppg = parser.Results.ppg;
fs = parser.Results.fs;
tD = parser.Results.tD;
windowA = parser.Results.WindowA;
windowB = parser.Results.WindowB;

% Ensure ppg is a column vector
ppg = ppg(:);

% Handle empty input
tD = tD(~isnan(tD(:)));
if isempty(tD)
    tA = NaN;
    tB = NaN;
    tM = NaN;
    return;
end

ppgLength = length(ppg);

% Time vector
t = (0:ppgLength-1) / fs;

% Convert tD to sample indices
nDSamples = 1 +  round(tD * fs);

% tA - Find local max after tD within windowA
[nASamples, tA] = findExtrema(ppg, nDSamples, windowA, fs, t, 'max');

if nargout < 2
    % Only tA requested
    return;
end

% tB - Find local min before tD within windowB
[nBSamples, tB] = findExtrema(ppg, nDSamples, windowB, fs, t, 'min');

if nargout < 3
    % Only tA and tB requested
    return;
end

% tM - Find midpoint between tA and tB
tM = findMidpoints(ppg, nASamples, nBSamples, t);

end


%% FINDEXTREMA
function [extremaSamples, extremaTimes] = findExtrema(ppg, nDSamples, window, fs, t, extremaType)
% FINDEXTREMA Helper function to find local extrema (maxima or minima) in PPG signal
%
%   [EXTREMALOCS, EXTREMATIMES] = FINDEXTREMA(PPG, NDSAMPLES, WINDOW, FS, T, EXTREMATYPE)
%   finds local extrema in the PPG signal within specified search windows.
%   EXTREMATYPE can be 'max' for maxima or 'min' for minima.

npulses = length(nDSamples);
ppgLength = length(ppg);

% Initialize outputs
extremaTimes = NaN(npulses, 1);

% Create search matrix
if strcmp(extremaType, 'max')
    % Search forward from tD (for tA)
    searchMatrix = repmat(0:round(window*fs), npulses, 1) + nDSamples;
    searchSignal = ppg;
    offset = 0;
else % 'min'
    % Search backward from tD (for tB)
    offset = -round(window*fs);
    searchMatrix = repmat(offset:0, npulses, 1) + nDSamples;
    searchSignal = -ppg;
end

% Clamp search indices to valid range
searchMatrix = max(1, min(searchMatrix, ppgLength));

% Find local extrema
[~, locs] = localmax(searchSignal(searchMatrix), 2);

% Adjust locations based on search type
if strcmp(extremaType, 'max')
    extremaSamples = locs + nDSamples - 1;
else % 'min'
    extremaSamples = locs + (nDSamples + offset) - 1;
end

% Clamp to valid range
extremaSamples(extremaSamples < 1 | extremaSamples > ppgLength) = NaN;

% Refine extrema positions
validIdx = ~isnan(extremaSamples);
if any(validIdx)
    if strcmp(extremaType, 'max')
        [~, extremaTimes(validIdx)] = refinepeaks(ppg, extremaSamples(validIdx), t);
    else % 'min'
        [~, extremaTimes(validIdx)] = refinepeaks(-ppg, extremaSamples(validIdx), t);
    end
end
end


%% FINDMIDPOINTS
function midpointTimes = findMidpoints(ppg, nASamples, nBSamples, t)
% FINDMIDPOINTS Helper function to find pulse midpoints between onset and offset
%
%   MIDPOINTTIMES = FINDMIDPOINTS(PPG, NALOCS, NBLOCS, T) finds the midpoint
%   of each pulse between onset (tB) and offset (tA) locations by finding
%   the point closest to the average amplitude of the pulse endpoints.

npulses = length(nASamples);
ppgLength = length(ppg);
midpointTimes = NaN(npulses, 1);

% Process only valid pulses (both tA and tB are not NaN)
validPulses = ~isnan(nASamples) & ~isnan(nBSamples);
validIndices = find(validPulses);

if isempty(validIndices)
    return;
end

% Process each valid pulse
for i = 1:length(validIndices)
    kpulse = validIndices(i);
    nBpulse = nBSamples(kpulse);
    nApulse = nASamples(kpulse);

    % Create search vector (from tB to tA)
    searchM = nBpulse:nApulse;
    searchM = max(1, min(searchM, ppgLength)); % Clamp to valid range

    % Calculate target amplitude (average of endpoints)
    pulseAmplitude = (ppg(nBpulse) + ppg(nApulse)) / 2;

    % Find point closest to target amplitude
    pulseSegment = abs(ppg(searchM) - pulseAmplitude);
    [~, minIdx] = min(pulseSegment);

    % Convert back to global index
    globalIdx = searchM(minIdx);
    if globalIdx >= 1 && globalIdx <= ppgLength
        % Use refinepeaks for more precise localization
        % Create time vector for the pulse segment
        segmentTime = t(searchM);

        % Use refinepeaks on the inverted signal (to find minimum as maximum)
        [~, refinedTime] = refinepeaks(-pulseSegment, minIdx, segmentTime);
        midpointTimes(kpulse) = refinedTime;
    end
end
end