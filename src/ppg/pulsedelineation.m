function [nA, nB, nM] = pulsedelineation(ppg, fs, nD, varargin)
% PULSEDELINEATION Performs pulse delineation in PPG signals using adaptive thresholding.
%
%   [NA, NB, NM] = PULSEDELINEATION(PPG, FS, ND) performs pulse delineation
%   in photoplethysmographic (PPG) signals, detecting pulse features (nA, nB, nM)
%   based on pulse detection points (nD). FS is the sampling rate in Hz (positive scalar).
%   NA returns pulse onset locations in seconds, NB returns pulse offset locations
%   in seconds, and NM returns pulse midpoint locations in seconds.
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
%   Status: Alpha


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

npulses = length(nD);
ppgLength = length(ppg);

% Time vector
t = (0:ppgLength-1) / fs;

% Convert nD to sample indices
nDSamples = 1 +  round(nD * fs);

%% nA - Pulse onset: find local max after nD within windowA

% Create search matrix
matrixA = repmat(0:round(windowA*fs), npulses , 1 ) + nDSamples;
matrixA(matrixA < 1) = 1;
matrixA(matrixA > ppgLength) = ppgLength;

% Find local maxima
[~,nALocs] = findlocalmaxima(ppg(matrixA));
nALocs = nALocs + nDSamples - 1;
nALocs(nALocs<1 | nALocs>ppgLength) = NaN;

% Refine maxima
nA = nALocs;
[~, nA(~isnan(nA))] = refinepeaks(ppg, nALocs(~isnan(nALocs)), t);


%% nB - Pulse offset: find min before nD within windowB

% Create search matrix
matrixB = repmat(-round(windowB*fs):0, npulses, 1 ) + nDSamples;
matrixB(matrixB < 1) = 1;
matrixB(matrixB > ppgLength) = ppgLength;

% Find local minima
[~,nBLocs] = findlocalmaxima(-ppg(matrixB));
nBLocs = nBLocs + (nDSamples - round(windowB*fs)) - 1;
nBLocs(nBLocs<1 | nBLocs>ppgLength) = NaN;

% Refine minima
nB = nBLocs;
[~, nB(~isnan(nB))] = refinepeaks(-ppg, nBLocs(~isnan(nBLocs)), t);


%% nM - Find midpoint between nA and nB
nM = NaN(npulses,1);
% for kpulse = 1:npulses
%     if (isnan(nBLocs(kpulse)) || isnan(nALocs(kpulse)))
%         % If either position is NaN, skip this pulse
%         continue;
%     end

%     pulseAmplitude = (ppg(nBLocs(kpulse)) + ppg(nALocs(kpulse)))/2;
%     matrixM = nBLocs(kpulse):nALocs(kpulse);
%     matrixM(matrixM < 1) = 1;
%     matrixM(matrixM > ppgLength) = ppgLength;

%     [~,nMLocs] = max(-abs(ppg(matrixM) - pulseAmplitude'), [], 2);
%     nMLocs = nMLocs + nBLocs(kpulse) - 1;
%     nMLocs(nMLocs<1 | nMLocs>ppgLength) = NaN;

%     if ~any(isnan(nMLocs)) && ~isempty(nMLocs)
%         nM(kpulse) = t(nMLocs);
%     end
% end

end

function [maxValue, maxLoc] = findlocalmaxima(X)
% X: matrix MxN (each row is a signal segment)

minProm = 0; % > 0 to ignore plateaus/noise
minSep  = 1; % minimum separation between peaks (in samples)

% 1) Peak candidates per row (dim=2)
L = islocalmax(X, 2, 'MinProminence', minProm, ...
    'MinSeparation',  minSep, ...
    'FlatSelection', 'center');

% 2) Force to -Inf where NOT a peak and take maximum per row
Xmask = X;
Xmask(~L) = -inf;

[maxValue, maxLoc] = max(Xmask, [], 2, 'omitnan');  % values and positions (column)

% 3) Rows without peaks -> NaN
hasPeak = any(L, 2);
maxLoc(~hasPeak) = NaN;           % column index of peak (NaN if none)
maxValue(~hasPeak) = NaN;           % peak value (NaN if none)

end