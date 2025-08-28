function [nA, nB, nM] = pulsedelineation(ppg, fs, nD, varargin)
% PULSEDELINEATION Performs pulse delineation in PPG signals using adaptive thresholding.
%
%   [NA, NB, NM] = PULSEDELINEATION(PPG, FS, ND) performs pulse
%   delineation in photoplethysmographic (PPG) signals, detecting
%   pulse features (nA, nB, nM) based on pulse detection points (nD).
%   FS is the sampling rate in Hz (positive scalar). NA returns pulse
%   onset locations in seconds, NB returns pulse offset locations in
%   seconds, and NM returns pulse midpoint locations in seconds.
%
%   [NA, NB, NM] = PULSEDELINEATION(..., 'Name', Value) specifies additional
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
%     nD = pulsedetection(dppg, fs);
%
%     % Perform pulse delineation
%     [nA, nB, nM] = pulsedelineation(ppg, fs, nD);
%
%     % Plot results
%     t = (0:length(ppg)-1)/fs;
%     figure;
%     plot(t, ppg, 'k');
%     hold on;
%     plot(nA, ppg(1+round(nA*fs)), 'ro', 'MarkerFaceColor', 'r');
%     plot(nB, ppg(1+round(nB*fs)), 'go', 'MarkerFaceColor', 'g');
%     plot(nM, ppg(1+round(nM*fs)), 'bo', 'MarkerFaceColor', 'b');
%     legend('PPG Signal', 'Onset (nA)', 'Offset (nB)', 'Midpoint (nM)');
%     xlabel('Time (s)');
%     ylabel('Amplitude');
%     title('PPG Pulse Delineation');
%
%   See also PULSEDETECTION, LPDFILTER
%
%   Status: Beta


% Check number of input and output arguments
narginchk(3, 9);
nargoutchk(0, 3);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'pulsedelineation';
addRequired(parser, 'ppg', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);
addRequired(parser, 'nD', @(x) isnumeric(x) && (isvector(x) || isempty(x)));
addParameter(parser, 'WindowA', 250e-3, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'WindowB', 150e-3, @(x) isnumeric(x) && isscalar(x) && x > 0);

parse(parser, ppg, fs, nD, varargin{:});

ppg = parser.Results.ppg;
fs = parser.Results.fs;
nD = parser.Results.nD;
windowA = parser.Results.WindowA;
windowB = parser.Results.WindowB;

% Ensure ppg is a column vector
ppg = ppg(:);

% Handle empty input
nD = nD(~isnan(nD(:)));
if isempty(nD)
    nA = NaN;
    nB = NaN;
    nM = NaN;
    return;
end

ppgLength = length(ppg);

% Time vector
t = (0:ppgLength-1) / fs;

% Convert nD to sample indices
nDSamples = 1 +  round(nD * fs);

% nA - Find local max after nD within windowA
[nASamples, nA] = findExtrema(ppg, nDSamples, windowA, fs, t, 'max');

if nargout < 2
    % Only nA requested
    return;
end

% nB - Find local min before nD within windowB
[nBSamples, nB] = findExtrema(ppg, nDSamples, windowB, fs, t, 'min');

if nargout < 3
    % Only nA and nB requested
    return;
end

% nM - Find midpoint between nA and nB
nM = findMidpoints(ppg, nASamples, nBSamples, t);

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
    % Search forward from nD (for nA)
    searchMatrix = repmat(0:round(window*fs), npulses, 1) + nDSamples;
    searchSignal = ppg;
    offset = 0;
else % 'min'
    % Search backward from nD (for nB)
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
%   of each pulse between onset (nB) and offset (nA) locations by finding
%   the point closest to the average amplitude of the pulse endpoints.

npulses = length(nASamples);
ppgLength = length(ppg);
midpointTimes = NaN(npulses, 1);

% Process only valid pulses (both nA and nB are not NaN)
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

    % Create search vector (from nB to nA)
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