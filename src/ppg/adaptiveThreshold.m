
function [nD, thres] = adaptiveThreshold(signal, fs, alfa, refractPeriod, tauRR)
signal = signal(:);
nD = [];
peaksAdded = [];
thresIniWIni = find(~isnan(signal), 1, 'first');
thresIniWEnd = thresIniWIni + round(10*fs); thresIniWEnd(thresIniWEnd>=length(signal)) = [];
aux = signal(thresIniWIni:thresIniWEnd);
thresIni = 3*mean(aux(aux>=0), 'omitnan');
thres = nan(size(signal));
t = 1:length(signal);
RR = round(60/80*fs);

if (1+RR)<length(signal)
    thres(1:1+RR) = thresIni - (thresIni*(1-alfa)/RR)*(t(1:RR+1)-1);
    thres(1+RR:end) = alfa*thresIni;
else
    thres(1:end) = thresIni - (thresIni*(1-alfa)/RR)*(t(1:end)-1);
end

kk = 1;
while true
    crossUp = kk-1 + find(signal(kk:end)>thres(kk:end), 1, 'first'); % Next point to cross the actual threshold (down->up)
    if isempty(crossUp)
        % No more pulses -> end
        break;
    end

    crossDown = crossUp-1 + find(signal(crossUp:end)<thres(crossUp:end), 1, 'first'); % Next point to cross the actual threshold (up->down)
    if isempty(crossDown)
        % No more pulses -> end
        break;
    end

    % Pulse detected:
    [~, imax] = max(signal(crossUp:crossDown));
    p = crossUp-1+imax;

    if length(nD) <= 4
        [vmax] = max(signal(crossUp:crossDown));
    else
        [vmax] = median([signal(nD(end-3:end)); max(signal(crossUp:crossDown))]);
    end

    nD = [nD, p]; %#ok<*AGROW>
    Npeaks = length(nD);

    % Update threshold
    NRREstimation = 3;
    NAmpliEst = 3;
    if Npeaks >= NRREstimation+1
        RR = round(median(diff(nD(end-NRREstimation:end))));
    elseif Npeaks >= 2
        RR = round(mean(diff(nD)));
    end
    kk = min(p+refractPeriod, length(signal));
    thres(p:kk) = vmax;

    vfall = vmax*alfa;
    if Npeaks >= (NAmpliEst+1)
        ampliEst = median(signal(nD(end-NAmpliEst:end-1)));
        if vmax >= (2*ampliEst)
            vfall = alfa*ampliEst;
            vmax = ampliEst;
        end
    end

    fallEnd = round(tauRR*RR);
    if (kk+fallEnd) < length(signal)
        thres(kk:kk+fallEnd) = vmax - (vmax-vfall)/fallEnd*(t(kk:kk+fallEnd)-kk);
        thres(kk+fallEnd:end) = vfall;
    else
        thres(kk:end) = vmax - (vmax-vfall)/fallEnd*(t(kk:end)-kk);
    end

end

nD = unique([nD peaksAdded]);

end
