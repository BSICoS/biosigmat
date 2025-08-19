function [nD, threshold] = pulsedetection(dppg, fs, varargin)
% PULSEDETECTION Pulse detection in LPD-filtered PPG signals using adaptive thresholding.
%
%   ND = PULSEDETECTION(DPPG, FS) detects pulse maximum upslopes ND in PPG derivative
%   (DPPG) using an adaptive threshold algorithm. DPPG is the LPD-filtered PPG
%   signal (column vector) and FS is the sampling rate in Hz.
%
%   The algorithm uses adaptive thresholding with refractory periods and
%   beat pattern analysis to handle irregular rhythms. It processes long
%   signals in segments for computational efficiency and includes correction
%   mechanisms for missed or false detections based on pulse-to-pulse
%   interval regularity.
%
%   ND = PULSEDETECTION(..., 'Name', Value) specifies additional parameters
%   using name-value pairs:
%     'alfa'          - Multiplier for previous amplitude of detected maximum
%                       when updating the threshold (default: 0.2)
%     'refractPeriod' - Refractory period for threshold in seconds
%                       (default: 0.15)
%     'tauRR'         - Fraction of estimated RR interval where threshold reaches
%                       its minimum value (default: 1.0). Larger values create
%                       steeper threshold slopes
%
%   [ND, THRESHOLD] = PULSEDETECTION(...) also returns the computed
%   time-varying THRESHOLD.
%
%   Example:
%     % Load PPG signal and apply LPD filtering
%     load('ppg_sample.mat', 'ppg', 'fs');
%
%     % Design and apply LPD filter
%     fcLPD = 8; fpLPD = 0.9; orderLPD = 4;
%     [b, delay] = lpdfilter(fs, fcLPD, 'PassFreq', fpLPD, 'Order', orderLPD);
%     signalFiltered = filter(b, 1, ppg);
%     signalFiltered = [signalFiltered(delay+1:end); zeros(delay, 1)];
%
%     % Detect pulses with default parameters
%     [nD, threshold] = pulsedetection(signalFiltered, fs);
%
%     % Detect pulses with custom parameters
%     [nD2, threshold2] = pulsedetection(signalFiltered, fs, ...
%         'alfa', 0.3, 'refractPeriod', 0.2);
%
%     % Visualize results
%     t = (0:length(signalFiltered)-1) / fs;
%     figure;
%     plot(t, signalFiltered, 'b');
%     hold on;
%     plot(t, threshold, 'r--', 'LineWidth', 1.5);
%     plot(nD, signalFiltered(round(nD*fs)+1), 'go', 'MarkerSize', 8);
%     xlabel('Time (s)');
%     ylabel('Amplitude');
%     title('PPG Pulse Detection with Adaptive Threshold');
%     legend('Filtered PPG', 'Threshold', 'Detected Pulses');
%
%     % Calculate heart rate
%     heartRate = 60 ./ diff(nD);
%     fprintf('Detected %d pulses\n', length(nD));
%     fprintf('Mean heart rate: %.1f bpm\n', mean(heartRate));
%
%   See also LPDFILTER, PULSEDELINEATION, FINDPEAKS
%
%   Status: Alpha


% Check number of input and output arguments
narginchk(2, 10);
nargoutchk(0, 2);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'pulsedetection';
addRequired(parser, 'dppg', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'alfa', 0.2, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'refractPeriod', 150e-03, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'tauRR', 1, @(x) isnumeric(x) && isscalar(x) && x > 0);

parse(parser, dppg, fs, varargin{:});

dppg = parser.Results.dppg;
fs = parser.Results.fs;
alfa = parser.Results.alfa;
refractPeriod = parser.Results.refractPeriod;
tauRR = parser.Results.tauRR;

dppg = dppg(:);

refractPeriod = round(refractPeriod*fs);

% Segmentize the signals to avoid memory issues
signalLength = length(dppg);
segmentLength = 10000;

if segmentLength < signalLength
    segments = slicesignal(dppg, segmentLength, 0, 'Uselast', true);
else
    segments = dppg;
end

nSegments = size(segments, 2);

nD = [];
threshold = [];

% Go through each segment
for ii = 1:nSegments
    % Make the segments tAdd seconds longer on each side

    tAdd = 5*fs;

    if nSegments > 1
        if ii == 1
            % End the segment 10 seconds later
            segment = [segments(:, 1); segments(1:tAdd, 2)];
        elseif ii == nSegments
            % Start the segment 10 seconds earlier
            segment = [segments(end-(tAdd)+1:end, end-1); segments(:, end)];
        else
            % Start the segment 10 seconds earlier and end 10 seconds later
            segment = [segments(end-(tAdd)+1:end, ii-1); segments(:, ii); segments(1:tAdd, ii+1)];
        end
    else
        % Take the whole segment
        segment = segments;
    end

    time = (0:1:length(segment)-1)./fs;

    % Detect peaks in the LPD signal by adaptive thresholding

    [nD_segment, thresholdSegment] = adaptiveThresholding(segment(:), fs, alfa, refractPeriod, tauRR);

    % Remove added signal on both sides
    if nSegments > 1
        if ii == 1
            % Remove the last five seconds
            nD_segment = nD_segment(nD_segment <= segmentLength);
            thresholdSegment = thresholdSegment(time*fs < segmentLength);
        elseif ii == nSegments
            % Remove the first five seconds
            nD_segment = nD_segment(nD_segment > tAdd) - (tAdd);
            thresholdSegment = thresholdSegment(time*fs >= tAdd);
        else
            % Remove the first and last five seconds
            nD_segment = nD_segment(nD_segment >= tAdd) - tAdd;
            nD_segment = nD_segment(nD_segment < segmentLength);

            thresholdSegment = thresholdSegment(time*fs >= tAdd);
            thresholdSegment = thresholdSegment(time*fs < segmentLength);
        end
    end

    % Store the signals in a cell
    nD = [nD; nD_segment(:) + segmentLength*(ii-1)];
    threshold = [threshold; thresholdSegment(:)];

end

% Arrange Outputs
t = (0:1:length(dppg)-1)./fs;
nD = (unique(nD)-1) ./ fs;
threshold(length(t)+1:end) = [];

end


function [nD, thres] = adaptiveThresholding(sig_filt, fs, alfa, refractPeriod, tauRR)

nD = [];
peaks_added = [];
thres_ini_w_ini = find(~isnan(sig_filt), 1, 'first');
thres_ini_w_end = thres_ini_w_ini + round(10*fs); thres_ini_w_end(thres_ini_w_end>=length(sig_filt)) = [];
aux = sig_filt(thres_ini_w_ini:thres_ini_w_end);
thres_ini = 3*mean(aux(aux>=0), 'omitnan');
thres = nan(size(sig_filt));
t = 1:length(sig_filt);
RR = round(60/80*fs);

if (1+RR)<length(sig_filt)
    thres(1:1+RR) = thres_ini - (thres_ini*(1-alfa)/RR)*(t(1:RR+1)-1);
    thres(1+RR:end) = alfa*thres_ini;
else
    thres(1:end) = thres_ini - (thres_ini*(1-alfa)/RR)*(t(1:end)-1);
end

kk = 1;
while true
    cross_u = kk-1 + find(sig_filt(kk:end)>thres(kk:end), 1, 'first'); %Next point to cross the actual threshold (down->up)
    if isempty(cross_u)
        % No more pulses -> end
        break;
    end

    cross_d = cross_u-1 + find(sig_filt(cross_u:end)<thres(cross_u:end), 1, 'first'); %Next point to cross the actual threshold (up->down)
    if isempty(cross_d)
        % No more pulses -> end
        break;
    end

    % Pulse detected:
    [~, imax] = max(sig_filt(cross_u:cross_d));
    p = cross_u-1+imax;

    if length(nD) <= 4
        [vmax] = max(sig_filt(cross_u:cross_d));
    else
        [vmax] = median([sig_filt(nD(end-3:end)); max(sig_filt(cross_u:cross_d))]);
    end

    nD = [nD, p];
    Npeaks = length(nD);

    % Update threshold
    N_RR_estimation = 3;
    N_ampli_est = 3;
    if Npeaks >= N_RR_estimation+1
        RR = round(median(diff(nD(end-N_RR_estimation:end))));
    elseif Npeaks >= 2
        RR = round(mean(diff(nD)));
    end
    kk = min(p+refractPeriod, length(sig_filt));
    thres(p:kk) = vmax;

    vfall = vmax*alfa;
    if Npeaks >= (N_ampli_est+1)
        ampli_est = median(sig_filt(nD(end-N_ampli_est:end-1)));
        if vmax >= (2*ampli_est)
            vfall = alfa*ampli_est;
            vmax = ampli_est;
        end
    end

    fall_end = round(tauRR*RR);
    if (kk+fall_end) < length(sig_filt)
        thres(kk:kk+fall_end) = vmax - (vmax-vfall)/fall_end*(t(kk:kk+fall_end)-kk);
        thres(kk+fall_end:end) = vfall;
    else
        thres(kk:end) = vmax - (vmax-vfall)/fall_end*(t(kk:end)-kk);
    end

end

nD = unique([nD peaks_added]);

end
