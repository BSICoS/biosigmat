function [nD, threshold] = adaptiveThreshold(dppg, fs, params)
% ADAPTIVETHRESHOLD Core implementation of adaptive thresholding algorithm.
%
%   [ND, THRESHOLD] = ADAPTIVETHRESHOLD(DPPG, FS, PARAMS) implements the
%   adaptive thresholding algorithm for pulse detection in PPG derivative signals.
%   This is a private function called by PULSEDETECTION.
%
%   DPPG is the derivative PPG signal (column vector), FS is the sampling rate
%   in Hz, and PARAMS is a struct containing algorithm parameters:
%     .alphaAmp      - Multiplier for previous amplitude when updating threshold
%     .refractPeriod - Refractory period in seconds
%     .tauRR         - Fraction of RR interval where threshold reaches minimum
%
%   Returns ND (detected pulse indices) and THRESHOLD (time-varying threshold).
%
%   This function assumes inputs are already validated by the calling function.
%
%   See also PULSEDETECTION

dppg = dppg(:);
refractPeriod = round(params.refractPeriod * fs);

thresIniWIni = find(~isnan(dppg), 1, 'first');
thresIniWEnd = thresIniWIni + round(10*fs);
thresIniWEnd(thresIniWEnd>=length(dppg)) = [];
aux = dppg(thresIniWIni:thresIniWEnd);

t = 1:length(dppg);
RR = round(60/80*fs);
threshold = nan(size(dppg));
thresIni = 3*mean(aux(aux>=0), 'omitnan');
if (1+RR)<length(dppg)
    threshold(1:1+RR) = thresIni - (thresIni*(1-params.alphaAmp)/RR)*(t(1:RR+1)-1);
    threshold(1+RR:end) = params.alphaAmp*thresIni;
else
    threshold(1:end) = thresIni - (thresIni*(1-params.alphaAmp)/RR)*(t(1:end)-1);
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

    vfall = vmax*params.alphaAmp;
    if npeaks >= (nAmpliEst+1)
        ampliEst = median(dppg(nD(end-nAmpliEst:end-1)));
        if vmax >= (2*ampliEst)
            vfall = params.alphaAmp*ampliEst;
            vmax = ampliEst;
        end
    end

    fallEnd = round(params.tauRR*RR);
    if (kk+fallEnd) < length(dppg)
        threshold(kk:kk+fallEnd) = vmax - (vmax-vfall)/fallEnd*(t(kk:kk+fallEnd)-kk);
        threshold(kk+fallEnd:end) = vfall;
    else
        threshold(kk:end) = vmax - (vmax-vfall)/fallEnd*(t(kk:end)-kk);
    end

end

nD = unique([nD peaksAdded]);

end
