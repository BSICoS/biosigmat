function [nA, nB, nM] = pulsedelineation(dppg, fs, nD, varargin)
% PULSEDELINEATION Performs pulse delineation in PPG signals using adaptive thresholding.
%
%   [NA, NB, NM] = PULSEDELINEATION(DPPG, FS, ND) performs pulse delineation
%   in photoplethysmographic (PPG) signals, detecting pulse features (nA, nB, nM)
%   based on pulse detection points (nD). DPPG is the filtered LPD-filtered PPG
%   signal (numeric vector), FS is the sampling rate in Hz (positive scalar), and
%   ND contains pre-computed pulse detection points in seconds (numeric vector).
%   NA returns pulse onset locations in seconds, NB returns pulse offset locations
%   in seconds, and NM returns pulse midpoint locations in seconds.
%
%   [NA, NB, NM] = PULSEDELINEATION(..., 'Name', Value) specifies additional
%   parameters using name-value pairs:
%     'WindowA'  - Window width for searching pulse onset in seconds
%                  (default: 250e-3)
%     'WindowB'  - Window width for searching pulse offset in seconds
%                  (default: 150e-3)
%     'InterpFS' - Sampling frequency for interpolation in Hz
%                  (default: 2*FS)
%
%   Example:
%     % Load PPG signal and apply LPD filtering
%     ppgData = readtable('ppg_signals.csv');
%     signal = ppgData.sig(1:30000);
%     fs = 1000;
%
%     % Apply LPD filter
%     [b, delay] = lpdfilter(fs, 8, 'PassFreq', 7.8, 'Order', 100);
%     signalFiltered = filter(b, 1, signal);
%     signalFiltered = [signalFiltered(delay+1:end); zeros(delay, 1)];
%
%     % Compute pulse detection points
%     nD = pulsedetection(signalFiltered, fs);
%
%     % Perform pulse delineation
%     [nA, nB, nM] = pulsedelineation(signalFiltered, fs, nD);
%
%     % Plot results
%     t = (0:length(signal)-1)/fs;
%     figure;
%     plot(t, signal, 'k');
%     hold on;
%     plot(nA, signal(1+round(nA*fs)), 'ro', 'MarkerFaceColor', 'r');
%     plot(nB, signal(1+round(nB*fs)), 'go', 'MarkerFaceColor', 'g');
%     plot(nM, signal(1+round(nM*fs)), 'bo', 'MarkerFaceColor', 'b');
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
addRequired(parser, 'signal', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);
addRequired(parser, 'nD', @(x) isnumeric(x) && (isvector(x) || isempty(x)));
addParameter(parser, 'WindowA', 250e-3, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'WindowB', 150e-3, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'InterpFS', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x > 0));

parse(parser, dppg, fs, nD, varargin{:});

dppg = parser.Results.signal;
fs = parser.Results.fs;
nD = parser.Results.nD;
wdw_nA = parser.Results.WindowA;
wdw_nB = parser.Results.WindowB;
fsi = parser.Results.InterpFS;

% Set default interpolation frequency if not provided
if isempty(fsi)
    fsi = 2 * fs;
end


% Ensure signal is a column vector
dppg = dppg(:);

% Check if nD is empty
if isempty(nD)
    nA = NaN;
    nB = NaN;
    nM = NaN;
    return;
end

% Remove NaN values from nD and convert to interpolated indices
nDClean = nD(~isnan(nD(:)));
nDIndices = 1 + round(nDClean * fsi);

% Create time vectors for interpolation
t = 0:1/fs:(length(dppg)-1)/fs;
tInterp = 0:1/fsi:((length(dppg)*(fsi/fs)-1)/fsi);
signalInterp = interp1(t, dppg, tInterp, 'spline');

% Initialize output variables
nA = NaN(length(nDClean), 1);
nB = NaN(length(nDClean), 1);
nM = NaN(length(nDClean), 1);

% nA - Find maximum after nD within window
mtx_nA = repmat(0:round(wdw_nA*fsi), length(nDIndices), 1) + nDIndices;
mtx_nA(mtx_nA < 1) = 1;
mtx_nA(mtx_nA > length(signalInterp)) = length(signalInterp);
[~, i_nA] = max(signalInterp(mtx_nA), [], 2);
i_nA = i_nA + nDIndices;
i_nA(i_nA < 1 | i_nA > length(signalInterp)) = NaN;
nA(~isnan(i_nA)) = tInterp(i_nA(~isnan(i_nA)));

% nB - Find minimum before nD within window
mtx_nB = repmat(-round(wdw_nB*fsi):0, length(nDIndices), 1) + nDIndices;
mtx_nB(mtx_nB < 1) = 1;
mtx_nB(mtx_nB > length(signalInterp)) = length(signalInterp);
[~, i_nB] = min(signalInterp(mtx_nB), [], 2);
i_nB = i_nB + (nDIndices - round(wdw_nB*fsi));
i_nB(i_nB < 1 | i_nB > length(signalInterp)) = NaN;
nB(~isnan(i_nB)) = tInterp(i_nB(~isnan(i_nB)));

% nM - Find midpoint between nA and nB
for ii = 1:length(nDIndices)
    if isnan(i_nB(ii)) || isnan(i_nA(ii))
        continue;
    end
    pulseAmplitude = (signalInterp(i_nB(ii)) + signalInterp(i_nA(ii))) / 2;
    mtx_nM = i_nB(ii):i_nA(ii);
    mtx_nM(mtx_nM < 1) = 1;
    mtx_nM(mtx_nM > length(signalInterp)) = length(signalInterp);
    [~, i_nM] = max(-abs(signalInterp(mtx_nM) - pulseAmplitude), [], 2);
    i_nM = i_nM + i_nB(ii);
    i_nM(i_nM < 1 | i_nM > length(signalInterp)) = NaN;
    if ~isnan(i_nM) && ~isempty(i_nM)
        nM(ii) = tInterp(i_nM);
    end
end

end