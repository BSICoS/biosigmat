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
%     'FsInterp' - Sampling frequency for interpolation in Hz
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
%   See also PULSEDETECTION, LPDFILTER, REFINEPEAKS
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
addParameter(parser, 'FsInterp', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x > 0));

parse(parser, dppg, fs, nD, varargin{:});

dppg = parser.Results.signal;
fs = parser.Results.fs;
nD = parser.Results.nD;
windowA = parser.Results.WindowA;
windowB = parser.Results.WindowB;
fsInterp = parser.Results.FsInterp;

% Set default interpolation frequency if not provided
if isempty(fsInterp)
    fsInterp = 2 * fs;
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

% Remove NaN values from nD
nDClean = nD(~isnan(nD(:)));
if isempty(nDClean)
    nA = NaN;
    nB = NaN;
    nM = NaN;
    return;
end

% Create high-resolution interpolated signal for delineation
t = (0:length(dppg)-1) / fs;
tInterp = (0:((length(dppg)*fsInterp/fs)-1)) / fsInterp;
signalInterp = interp1(t, dppg, tInterp, 'spline');

% nA - Find maximum after nD within window using refinepeaks
nA = refinepeaks(dppg, fs, nDClean, 'FsInterp', fsInterp, 'WindowWidth', windowA);

% nB - Find minimum before nD within window using refinepeaks with inverted signal
nB = refinepeaks(-dppg, fs, nDClean, 'FsInterp', fsInterp, 'WindowWidth', windowB);

% nM - Find midpoint between nA and nB
nM = NaN(length(nDClean), 1);
for ii = 1:length(nDClean)
    % Get corresponding interpolated indices for nA and nB
    if isnan(nA(ii)) || isnan(nB(ii))
        continue;
    end

    idxA = round(nA(ii) * fsInterp) + 1;
    idxB = round(nB(ii) * fsInterp) + 1;

    % Ensure valid indices
    idxA = max(1, min(length(signalInterp), idxA));
    idxB = max(1, min(length(signalInterp), idxB));

    if idxB >= idxA
        continue; % Invalid order
    end

    % Calculate target amplitude (midpoint between nA and nB amplitudes)
    targetAmplitude = (signalInterp(idxB) + signalInterp(idxA)) / 2;

    % Search between nB and nA for point closest to target amplitude
    searchIndices = idxB:idxA;
    if ~isempty(searchIndices)
        [~, closestIdx] = min(abs(signalInterp(searchIndices) - targetAmplitude));
        refinedIdx = idxB + closestIdx - 1;

        if refinedIdx >= 1 && refinedIdx <= length(signalInterp)
            nM(ii) = tInterp(refinedIdx);
        end
    end
end

end