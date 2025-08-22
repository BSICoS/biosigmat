function [nD, threshold] = adaptiveThreshold(dppg, fs, varargin)
% ADAPTIVETHRESHOLD Adaptive thresholding algorithm for pulse detection in PPG signals.
%
%   ND = ADAPTIVETHRESHOLD(SIGNAL, FS) detects pulse peaks ND in derivative
%   PPG signals (DPPG) using an adaptive threshold algorithm. DPPG is a column
%   vector and FS is the sampling rate in Hz. The algorithm uses dynamic
%   thresholding with refractory periods and amplitude estimation to detect
%   pulse peaks robustly.
%
%   ND = ADAPTIVETHRESHOLD(SIGNAL, FS, 'Name', Value) specifies additional
%   parameters using name-value pairs:
%     'alphaAmp'      - Multiplier for previous amplitude of detected maximum
%                       when updating the threshold (default: 0.2)
%     'refractPeriod' - Refractory period for threshold in seconds
%                       (default: 0.15)
%     'tauRR'         - Fraction of estimated RR interval where threshold reaches
%                       its minimum value (default: 1.0). Larger values create
%                       steeper threshold slopes
%
%   [ND, THRESHOLD] = ADAPTIVETHRESHOLD(...) also returns the computed
%   time-varying THRESHOLD.
%
%   Example:
%     % Apply adaptive thresholding
%     [nD, threshold] = adaptiveThreshold(signal, fs);
%
%     % Plot results
%     figure;
%     plot(t, signal, 'b');
%     hold on;
%     plot(t, threshold, 'r--', 'LineWidth', 1.5);
%     plot(nD, signal(round(nD*fs)+1), 'go', 'MarkerSize', 8);
%     xlabel('Time (s)');
%     ylabel('Amplitude');
%     title('Adaptive Threshold Pulse Detection');
%     legend('Signal', 'Threshold', 'Detected Peaks');
%
%   See also PULSEDETECTION, FINDPEAKS
%
%   Status: Alpha

% Check number of input and output arguments
narginchk(2, 8);
nargoutchk(0, 2);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'adaptiveThreshold';
addRequired(parser, 'signal', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'alphaAmp', 0.2, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'refractPeriod', 150e-03, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'tauRR', 1, @(x) isnumeric(x) && isscalar(x) && x > 0);

parse(parser, dppg, fs, varargin{:});

dppg = parser.Results.signal;
fs = parser.Results.fs;
alphaAmp = parser.Results.alphaAmp;
refractPeriod = parser.Results.refractPeriod;
tauRR = parser.Results.tauRR;

dppg = dppg(:);
refractPeriod = round(refractPeriod*fs);

thresIniWIni = find(~isnan(dppg), 1, 'first');
thresIniWEnd = thresIniWIni + round(10*fs); thresIniWEnd(thresIniWEnd>=length(dppg)) = [];
aux = dppg(thresIniWIni:thresIniWEnd);

t = 1:length(dppg);
RR = round(60/80*fs);
threshold = nan(size(dppg));
thresIni = 3*mean(aux(aux>=0), 'omitnan');
if (1+RR)<length(dppg)
    threshold(1:1+RR) = thresIni - (thresIni*(1-alphaAmp)/RR)*(t(1:RR+1)-1);
    threshold(1+RR:end) = alphaAmp*thresIni;
else
    threshold(1:end) = thresIni - (thresIni*(1-alphaAmp)/RR)*(t(1:end)-1);
end

kk = 1;
nD = [];
peaksAdded = [];
while true
    crossUp = kk-1 + find(dppg(kk:end)>threshold(kk:end), 1, 'first'); % Next point to cross the actual threshold (down->up)
    if isempty(crossUp)
        % No more pulses -> end
        break;
    end

    crossDown = crossUp-1 + find(dppg(crossUp:end)<threshold(crossUp:end), 1, 'first'); % Next point to cross the actual threshold (up->down)
    if isempty(crossDown)
        % No more pulses -> end
        break;
    end

    % Pulse detected:
    [~, imax] = max(dppg(crossUp:crossDown));
    p = crossUp-1+imax;

    if length(nD) <= 4
        [vmax] = max(dppg(crossUp:crossDown));
    else
        [vmax] = median([dppg(nD(end-3:end)); max(dppg(crossUp:crossDown))]);
    end

    nD = [nD, p]; %#ok<*AGROW>
    npeaks = length(nD);

    % Update threshold
    nRREstimation = 3;
    nAmpliEst = 3;
    if npeaks >= nRREstimation+1
        RR = round(median(diff(nD(end-nRREstimation:end))));
    elseif npeaks >= 2
        RR = round(mean(diff(nD)));
    end
    kk = min(p+refractPeriod, length(dppg));
    threshold(p:kk) = vmax;

    vfall = vmax*alphaAmp;
    if npeaks >= (nAmpliEst+1)
        ampliEst = median(dppg(nD(end-nAmpliEst:end-1)));
        if vmax >= (2*ampliEst)
            vfall = alphaAmp*ampliEst;
            vmax = ampliEst;
        end
    end

    fallEnd = round(tauRR*RR);
    if (kk+fallEnd) < length(dppg)
        threshold(kk:kk+fallEnd) = vmax - (vmax-vfall)/fallEnd*(t(kk:kk+fallEnd)-kk);
        threshold(kk+fallEnd:end) = vfall;
    else
        threshold(kk:end) = vmax - (vmax-vfall)/fallEnd*(t(kk:end)-kk);
    end

end

nD = unique([nD peaksAdded]);

end
