function [detectionsVector, segments] = hjorthArtifacts(signal, fs, seg, step, margins, varargin)
% HJORTHARTIFACTS Detects artifacts in physiological signals using Hjorth parameters.
%
%   [DETECTIONSVECTOR, SEGMENTS] = HJORTHARTIFACTS(SIGNAL, FS, SEG, STEP,
%   MARGINS) detects artifacts in the input signal using Hjorth parameters
%   analysis. SIGNAL is the input signal vector, FS is the sampling frequency
%   in Hz, SEG is the time window search in seconds, STEP is the step in seconds
%   to shift the window, MARGINS is a 3x2 matrix where each row contains
%   [low, up] margins for H0, H1, and H2 parameters respectively, relative to
%   their median filtered baselines. DETECTIONSVECTOR is a logical vector
%   indicating artifact segments, and SEGMENTS contains the onset and offset
%   of segments in seconds.
%
%   [...] = HJORTHARTIFACTS(..., 'minSegmentSeparation', MINSEGMENTSEPARATION)
%   sets the minimum segment separation in seconds (default: 1).
%
%   [...] = HJORTHARTIFACTS(..., 'medfiltOrder', MEDFILTORDER) sets the median
%   filter order for threshold computation (default: 300).
%
%   [...] = HJORTHARTIFACTS(..., 'negative', NEGATIVE) inverts the artifact
%   detection logic when NEGATIVE is true (default: false).
%
%   [...] = HJORTHARTIFACTS(..., 'plotflag', PLOTFLAG) enables plotting of
%   intermediate results when PLOTFLAG is true (default: false).
%
%   Example:
%     % Load PPG signal and detect artifacts
%     fs = 125;
%     t = 0:1/fs:60;
%     signal = sin(2*pi*1*t) + 0.1*randn(size(t));
%
%     % Define parameters
%     seg = 4;
%     step = 3;
%     marginH0 = [5, 1];
%     marginH1 = [0.8, 2];
%     marginH2 = [6, 6];
%     margins = [marginH0; marginH1; marginH2];
%
%     [artifacts, segments] = hjorthArtifacts(signal, fs, seg, step, ...
%         margins, 'minSegmentSeparation', 1, 'medfiltOrder', 15, 'plotflag', true);
%
%     % Plot results
%     figure;
%     plot(t, signal, 'b');
%     hold on;
%     plot(t(artifacts == 1), signal(artifacts == 1), 'r.');
%     title('Artifact Detection using Hjorth Parameters');
%     legend('Original Signal', 'Detected Artifacts');
%
%   See also HJORTH, MEDFILT1
%
%   Status: Alpha


% Check number of input and output arguments
narginchk(5, 9);
nargoutchk(0, 2);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'hjorthArtifacts';

addRequired(parser, 'signal', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);
addRequired(parser, 'seg', @(x) isnumeric(x) && isscalar(x) && x > 0);
addRequired(parser, 'step', @(x) isnumeric(x) && isscalar(x) && x > 0);
addRequired(parser, 'margins', @(x) isnumeric(x) && size(x,1) == 3 && size(x,2) == 2);

addParameter(parser, 'minSegmentSeparation', 1, @(x) isnumeric(x) && isscalar(x) && x >= 0);
addParameter(parser, 'medfiltOrder', 300, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'negative', false, @(x) islogical(x) && isscalar(x));
addParameter(parser, 'plotflag', false, @(x) islogical(x) && isscalar(x));

parse(parser, signal, fs, seg, step, margins, varargin{:});

% Extract parsed values
signal = parser.Results.signal;
fs = parser.Results.fs;
seg = parser.Results.seg;
step = parser.Results.step;
margins = parser.Results.margins;
minSegmentSeparation = parser.Results.minSegmentSeparation;
medfiltOrder = parser.Results.medfiltOrder;
negative = parser.Results.negative;
plotflag = parser.Results.plotflag;

% Extract margin values
marginH0Low = margins(1,1);
marginH0Up = margins(1,2);
marginH1Low = margins(2,1);
marginH1Up = margins(2,2);
marginH2Low = margins(3,1);
marginH2Up = margins(3,2);

% Initialize Hjorth parameters
nWindow = floor(seg*fs); % Segmentation window [samples]
nStep = floor(step*fs);  % Sliding step [samples]
nSegments = floor((length(signal)-nWindow)/nStep);
h0 = zeros(1,nSegments+1);
h1 = zeros(1,nSegments+1);
h2 = zeros(1,nSegments+1);
segments = zeros(nSegments+1,2);
signal(nSegments*nStep+nWindow+1:end) = [];

% Compute derivatives
sfilt = signal-mean(signal,'omitnan');
sfilt = sfilt(:)';

% Compute Hjorth parameters
for kk=0:nSegments
    indexes = (kk*nStep)+1:(kk*nStep+nWindow);
    [h0(kk+1),h1(kk+1),h2(kk+1)] = hjorth(sfilt(indexes),fs);
    segments(kk+1,:) = ([indexes(1) indexes(end)]-1)/fs;
end

% Compute thresholds
thresholdH0LowCalc  = medfilt1(h0,medfiltOrder,'truncate','omitnan') - marginH0Low;
thresholdH0UpCalc  = medfilt1(h0,medfiltOrder,'truncate','omitnan') + marginH0Up;
thresholdH1LowCalc = medfilt1(h1,medfiltOrder,'truncate','omitnan') - marginH1Low;
thresholdH1UpCalc = medfilt1(h1,medfiltOrder,'truncate','omitnan') + marginH1Up;
thresholdH2LowCalc  = medfilt1(h2,medfiltOrder,'truncate','omitnan') - marginH2Low;
thresholdH2UpCalc  = medfilt1(h2,medfiltOrder,'truncate','omitnan') + marginH2Up;
thresholdH0LowCalc(thresholdH0LowCalc<=0) = 0.0001;

% Look for artifact segments
artifactSegments = (h2 > thresholdH2UpCalc) | (h2 < thresholdH2LowCalc) | (h1 > thresholdH1UpCalc) | (h1 < thresholdH1LowCalc)...
    | (h0 > thresholdH0UpCalc) | (h0 < thresholdH0LowCalc);% | isnan(h0);
if negative
    artifactSegments = ~artifactSegments;
end

if nargout > 1
    detections = artifactSegments(:);
    %     detections(find(diff(diff(detections))>minSegmentSeparation)+1) = true;
else
    artifactSegments = find(artifactSegments);

    if isempty(artifactSegments)
        detections = [];
        detectionsVector = zeros(size(signal));
    else
        artifactSegments = [artifactSegments artifactSegments(end)+minSegmentSeparation]; % To use last one too
        newSegmentPosition = find(diff(artifactSegments)>=minSegmentSeparation);

        if ~isempty(newSegmentPosition)
            idetection = nan(length(newSegmentPosition),2);
            detections = nan(length(newSegmentPosition),2);
            k = 1;
            for i = 1:length(newSegmentPosition)
                idetection(i,1) = artifactSegments(k);
                idetection(i,2) = artifactSegments(newSegmentPosition(i));
                k = newSegmentPosition(i)+1;
            end
        else
            idetection(1,1) = artifactSegments(1);
            idetection(1,2) = artifactSegments(end);
        end

        % Samples -> Seconds
        detections(:,1) = (idetection(:,1)-1)*nStep + 1;
        detections(:,2) = (idetection(:,2)-1)*nStep + nWindow;

        detectionsVector = zeros(size(signal));
        for i=1:size(detections,1)
            indexes = detections(i,1):detections(i,2);
            detectionsVector(indexes) = 1;
        end

        % Detections can be outputed as a matrix with inits and ends in
        % seconds by changing the output from "detectionsVector" to "detections"
        detections = (detections-1)/fs;
    end
end

if plotflag
    plotResults(signal, fs, h0, h1, h2, thresholdH0UpCalc, thresholdH0LowCalc, ...
        thresholdH1UpCalc, thresholdH1LowCalc, thresholdH2UpCalc, thresholdH2LowCalc, ...
        segments, detections);
end

end


%% PLOTRESULTS
function plotResults(signal, fs, h0, h1, h2, thresholdH0UpCalc, thresholdH0LowCalc, ...
    thresholdH1UpCalc, thresholdH1LowCalc, thresholdH2UpCalc, thresholdH2LowCalc, ...
    segments, detections)
% PLOTRESULTS Helper function to plot Hjorth artifact detection results.
%
%   This function creates a comprehensive visualization of the Hjorth artifact
%   detection results, showing the original signal with detected artifacts,
%   and the three Hjorth parameters (variance, mobility, complexity) with
%   their corresponding thresholds.

t = linspace(0,(length(signal)-1)/(fs),length(h1));
tSignal = (0:1/fs:(length(signal)-1)/fs);
tSegments = segments;
detectionsAux = detections;

figure
ax(1) = subplot(4,1,1);
plot(tSignal, signal); hold on; grid on
if size(detections, 2) == 1  % Vector format
    for kk = 1:length(detections)
        if detections(kk)
            plot(tSignal(tSignal>=tSegments(kk,1) & tSignal<=tSegments(kk,2)), ...
                signal(tSignal>=tSegments(kk,1) & tSignal<=tSegments(kk,2)),'r');
        end
    end
else  % Matrix format
    for kk = 1:size(detectionsAux,1)
        plot(tSignal(tSignal>=detectionsAux(kk,1) & tSignal<=detectionsAux(kk,2)), ...
            signal(tSignal>=detectionsAux(kk,1) & tSignal<=detectionsAux(kk,2)),'r');
    end
end
ylabel('Input');

ax(2) = subplot(4,1,2);
plot(t,h0); hold on;
plot(t,thresholdH0UpCalc,'k','LineWidth',2);
plot(t,thresholdH0LowCalc,'k','LineWidth',2);
grid on; ylabel('Variance');
ylim([min(thresholdH0LowCalc), max(thresholdH0UpCalc)])
xlim([t(1) t(end)])

ax(3) = subplot(4,1,3);
plot(t,h1); hold on;
plot(t,thresholdH1UpCalc,'k','LineWidth',2);
plot(t,thresholdH1LowCalc,'k','LineWidth',2);
grid on; ylabel('Mobility');
ylim([min(thresholdH1LowCalc), max(thresholdH1UpCalc)])
xlim([t(1) t(end)])

ax(4) = subplot(4,1,4);
plot(t,h2); hold on;
plot(t,thresholdH2LowCalc,'k','LineWidth',2)
plot(t,thresholdH2UpCalc,'k','LineWidth',2)
grid on; ylabel('Complexity'); xlabel('t [sec]');
ylim([min(thresholdH2LowCalc), max(thresholdH2UpCalc)])
xlim([t(1) t(end)])

linkaxes(ax,'x');
end