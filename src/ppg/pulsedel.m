function [tA, tB, tM, tO] = pulsedel(ppg, fs, tD, varargin)
% PULSEDEL Delineate PPG pulse fiducials relative to detection times.
%
%   [TA, TB, TM] = PULSEDEL(PPG, FS, TD) returns apex, basal and
%   mid-amplitude times in seconds, with the first sample at time zero.
%   TM uses the amplitude halfway between the sampled basal and apex.
%   Each column output follows TD in input order, including NaNs and
%   repeated detections. PPG gaps limit searches to the same valid span.
%
%   [TA, TB, TM, TO] = PULSEDEL(PPG, FS, TD, DPPG) also returns onset
%   times using an aligned derivative supplied by the caller. Requesting
%   the fourth output without DPPG raises an error. Missing derivative
%   samples limit the onset search. They do not affect TA, TB or TM.
%
%   [...] = PULSEDEL(..., 'WindowA', WA, 'WindowB', WB) sets the search
%   durations after TD for the apex (default 0.25 s) and before TD for
%   the basal point (default 0.15 s).
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
%     tD = pulsedet(dppg, fs);
%
%     % Perform pulse delineation
%     [tA, tB, tM, tO] = pulsedel(ppg, fs, tD, dppg);
%
%     % Plot results
%     t = (0:length(ppg)-1)/fs;
%     figure;
%     plot(t, ppg, 'k');
%     hold on;
%     plot(tA, interp1(t, ppg, tA), 'rv');
%     plot(tB, interp1(t, ppg, tB), 'g^');
%     plot(tM, interp1(t, ppg, tM), 'bs');
%     plot(tO, interp1(t, ppg, tO), 'md');
%     legend('PPG Signal', 'Apex', 'Basal', 'Mid-amplitude', 'Onset');
%     xlabel('Time (s)');
%     ylabel('Amplitude');
%     title('PPG Pulse Delineation');
%
%   See also PULSEDET, LPDFILTER


% Check number of input and output arguments
narginchk(3, 8);
nargoutchk(0, 4);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'pulsedel';
isSignal = @(x) isnumeric(x) && isreal(x) && isvector(x) && ~isempty(x) && ~any(isinf(x));
positiveScalar = @(x) isnumeric(x) && isreal(x) && isscalar(x) && isfinite(x) && x > 0;
addRequired(parser, 'ppg', isSignal);
addRequired(parser, 'fs', positiveScalar);
addRequired(parser, 'tD', @(x) isnumeric(x) && isreal(x) && (isvector(x) || isempty(x)));
addOptional(parser, 'dppg', [], isSignal);
addParameter(parser, 'WindowA', 250e-3, positiveScalar);
addParameter(parser, 'WindowB', 150e-3, positiveScalar);

parse(parser, ppg, fs, tD, varargin{:});

ppg = parser.Results.ppg;
fs = parser.Results.fs;
tD = parser.Results.tD;
windowA = parser.Results.WindowA;
windowB = parser.Results.WindowB;

% Work with column vectors and preserve the correspondence with tD.
ppg = double(ppg(:));
tD = double(tD(:));
dppg = double(parser.Results.dppg(:));
ppgLength = length(ppg);
if nargout == 4 && isempty(dppg)
    error('pulsedel:MissingDerivative', 'Supply dppg to request onset times.');
end
if ~isempty(dppg) && numel(dppg) ~= ppgLength
    error('pulsedel:DerivativeLength', 'ppg and dppg must have the same length.');
end
if any(tD < 0 | tD > (ppgLength-1)/fs)
    error('pulsedel:DetectionOutOfBounds', 'Detection times must lie within the signal.');
end
if isempty(tD)
    tA = zeros(0,1); tB = tA; tM = tA; tO = tA;
    return;
end

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

if nargout == 4
    tO = findOnsets(ppg, dppg, nASamples, fs);
end

end


%% FINDEXTREMA
function [extremaSamples, extremaTimes] = findExtrema(ppg, nDSamples, window, fs, t, extremaType)
% FINDEXTREMA Find the strongest interior extremum in each pulse window.
%
%   [EXTREMALOCS, EXTREMATIMES] = FINDEXTREMA(PPG, NDSAMPLES, WINDOW, FS, T, EXTREMATYPE)
%   finds local extrema in the PPG signal within specified search windows.
%   EXTREMATYPE can be 'max' for maxima or 'min' for minima.

npulses = length(nDSamples);
ppgLength = length(ppg);

% Initialize outputs
extremaTimes = NaN(npulses, 1);

% Create search matrix
windowSamples = min(round(window*fs), ppgLength-1);
if strcmp(extremaType, 'max')
    % Search forward from tD (for tA)
    searchMatrix = repmat(0:windowSamples, npulses, 1) + nDSamples;
    searchSignal = ppg;
    offset = 0;
else % 'min'
    % Search backward from tD (for tB)
    offset = -windowSamples;
    searchMatrix = repmat(offset:0, npulses, 1) + nDSamples;
    searchSignal = -ppg;
end

% Keep the contiguous part of each window that touches its detection.
valid = searchMatrix >= 1 & searchMatrix <= ppgLength;
searchMatrix(~valid) = 1;
samples = reshape(searchSignal(searchMatrix), size(searchMatrix));
valid = valid & ~isnan(samples);
if strcmp(extremaType, 'max')
    valid = cumprod(valid, 2);
else
    valid = flip(cumprod(flip(valid, 2), 2), 2);
end
samples(~valid) = NaN;

% Find local extrema along each pulse window, including a single pulse.
[~, locs] = localmax(samples, 2);

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
% FINDMIDPOINTS Find the mid-amplitude time between basal and apex.
%
%   MIDPOINTTIMES = FINDMIDPOINTS(PPG, NALOCS, NBLOCS, T) finds the midpoint
%   of each pulse between basal (tB) and apex (tA) locations by finding
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

%% FINDONSETS
function onsetTimes = findOnsets(ppg, dppg, nASamples, fs)
% FINDONSETS Locate pulse onsets using the supplied PPG derivative.
%
%   ONSETTIMES = FINDONSETS(PPG, DPPG, NASAMPLES, FS) searches the 300 ms
%   preceding each sampled apex for the maximum upslope and the onset at
%   5 percent of that slope. Times are in seconds. Gaps bound the search.

onsetTimes = NaN(size(nASamples));
for k = find(~isnan(nASamples)).'
    apex = nASamples(k);
    first = max(1, apex - round(0.3*fs));
    window = first:apex;
    lastGap = find(isnan(ppg(window)) | isnan(dppg(window)), 1, 'last');
    if ~isempty(lastGap)
        first = first + lastGap;
    end
    if first >= apex
        continue;
    end

    [slope, upslope] = max(dppg(first:apex));
    if slope <= 0
        continue;
    end
    rising = dppg(first:first+upslope-1);
    threshold = 0.05*slope;
    if any(rising <= threshold)
        [~, onset] = min(abs(rising-threshold));
    else
        onset = find(islocalmin(rising, 'FlatSelection', 'center'), 1, 'last');
        if isempty(onset)
            [~, onset] = min(rising);
        end
    end
    onsetTimes(k) = (first + onset - 2)/fs;
end
end
