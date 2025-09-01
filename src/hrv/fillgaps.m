function tn = fillgaps(tk, varargin)
% FILLGAPS Fill gaps in HRV event series using iterative interpolation.
%
%   TN = FILLGAPS(TK) fills gaps in the HRV event series TK using an iterative
%   interpolation algorithm. TK is a vector of event timestamps (beat or pulse
%   occurrence times in seconds). TN is the corrected event series with gaps filled.
%   The algorithm starts by inserting a single beat per gap, moving to the next gap
%   until the entire signal is processed. Once all gaps have been attempted, those
%   that were not corrected are attempted with two insertions, and so on. This
%   approach consolidates a reference with simple gaps to improve the accuracy of
%   more complex ones.
%
%   The algorithm maintains original detections without displacement, trusting
%   that detections are correct at these points. It is recommended that the
%   processing chain discards all areas with artifacts or low SNR before detection.
%
%   TN = FILLGAPS(TK, DEBUG) enables visual inspection when DEBUG is true.
%   When DEBUG is true, the function displays gap-by-gap plots for visual
%   inspection of the correction process.
%
%   Example:
%     % Create synthetic HRV event series with gaps
%     tk = 0:0.8:60; % Regular 75 bpm baseline
%     tk(20:22) = []; % Remove some beats to create a gap
%     tk(40:44) = []; % Create another larger gap
%     dtk = diff(tk);
%
%     % Fill gaps in the event series
%     tn = fillgaps(tk,true);
%     dtn = diff(tn);
%
%     % Plot results
%     figure;
%     subplot(2,1,1);
%     stem(dtk, 'b'); hold on
%     stem([19, 39], dtk([19, 39]), 'r')
%     title('Original RR Intervals');
%     ylabel('RR Interval (s)');
%
%     subplot(2,1,2);
%     stem(dtn, 'g');
%     title('Filled RR Intervals');
%     ylabel('RR Interval (s)');
%     xlabel('Beat Index');
%
%   See also TDMETRICS, MEDFILTTHRESHOLD
%
%   Status: Alpha


% Check number of input and output arguments
narginchk(1, 2);
nargoutchk(0, 1);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'fillgaps';
addRequired(parser, 'tk', @(x) isnumeric(x) && isvector(x) && ~isempty(x) && all(isfinite(x)));
addOptional(parser, 'debug', false, @(x) islogical(x) && isscalar(x));

parse(parser, tk, varargin{:});

tk = parser.Results.tk;
debug = parser.Results.debug;

warning('off', 'MATLAB:interp1:NaNstrip');

% Threshold multipliers for upper and lower thresholds
kupper = 1.5;
kupperFine = 1/kupper*1.15;
klower = 1/kupper*0.75;

% Ensure tk is a column vector
tk = tk(:);
dtk = diff(tk);

% Remove false positives
baseline = medfiltThreshold(dtk, 30, 1, 1.5);
fp = dtk<0.7*baseline;
tk(find(fp)+1) = [];
tn = tk;
dtk = diff(tk);
dtn = dtk;

% Gaps are detected by deviation from the median in difference series
baseline = medfiltThreshold(dtk, 30, 1, 1.5);
gaps = find(dtk>baseline*kupper & dtk>0.5);
if isempty(gaps), return; end
thresholdAtGap = baseline(gaps)*kupper;

% Gaps on first and last pulses are not allowed
while gaps(1)<2
    tn(1) = [];
    dtk(1) = [];
    baseline(1) = [];
    gaps = find(dtk>baseline*kupper);
    thresholdAtGap = baseline(gaps)*kupper;
    if isempty(gaps), return; end
end
while gaps(end)>numel(dtk)-1
    tn(end) = [];
    dtk(end) = [];
    baseline(end) = [];
    gaps = find(dtk>baseline*kupper);
    thresholdAtGap = baseline(gaps)*kupper;
    if isempty(gaps), return; end
end

if debug
    f = set(gcf, 'Position', get(0, 'Screensize'));
end

nfill = 1; % Start filling with one sample
while ~isempty(gaps)
    % In each iteration, try to fill with one more sample
    for kk = 1:length(gaps)
        if kk==1 && debug
            subplot(211);
            hold off
            stem(dtn); hold on;
            stem(gaps,dtn(gaps),'r');
            hold on
            plot(baseline*kupper,'k--')
            axis tight
            ylabel('Original RR [s]')
        end

        auxtn = nfillgap(tn,gaps,gaps(kk),nfill);
        auxdtn = diff(auxtn);

        correct = auxdtn(gaps(kk):gaps(kk)+nfill)<kupperFine*thresholdAtGap(kk);
        limitExceeded = auxdtn(gaps(kk):gaps(kk)+nfill)<klower*thresholdAtGap(kk) | ...
            auxdtn(gaps(kk):gaps(kk)+nfill)<0.5;

        if debug
            if limitExceeded
                debugplots(auxdtn,gaps(kk),kupperFine*thresholdAtGap(kk),klower*thresholdAtGap(kk),nfill,false);
            else
                debugplots(auxdtn,gaps(kk),kupperFine*thresholdAtGap(kk),klower*thresholdAtGap(kk),nfill,correct);
            end
        end

        if limitExceeded
            % Check that lower theshold is not exceeded. Use previous nfill instead
            auxtn = nfillgap(tn,gaps,gaps(kk),nfill-1);
            auxdtn = diff(auxtn);
            if debug
                debugplots(auxdtn,gaps(kk),kupperFine*thresholdAtGap(kk),klower*thresholdAtGap(kk),nfill-1,true);
            end
            tn = auxtn;
            gaps = gaps+nfill-1;
        elseif correct
            % If correct number of samples, save serie
            tn = auxtn;
            gaps = gaps+nfill;
        end
    end

    % Compute gaps for next iteration
    dtn = diff(tn);
    baseline = medfiltThreshold(dtn, 30, 1, 1.5);
    gaps = find(dtn>baseline*kupper & dtn>0.5);
    thresholdAtGap = baseline(gaps)*kupper;
    nfill = nfill+1;
end

if debug
    close(f);
end

end


%% NFILLGAP
function tn = nfillgap(tk,gaps,currentGap,nfill)
dtk = diff(tk);
gaps(gaps==currentGap) = [];
dtk(gaps) = nan;
gap = dtk(currentGap);
previousIntervals = dtk(max(1,currentGap-20):currentGap-1);
posteriorIntervals = dtk(currentGap+1:min(end,currentGap+20));
npre = numel(previousIntervals);
npos = numel(posteriorIntervals);
intervals = interp1([1:npre nfill+npre+2:nfill+npre+npos+1],[previousIntervals; posteriorIntervals],...
    npre+1:npre+nfill+1,'pchip');
intervals = intervals(1:end-1)*gap/(sum(intervals,'omitnan')); % map intervals to gap
tn = [tk(1:currentGap); tk(currentGap)+cumsum(intervals)'; tk(currentGap+1:end)];
end


%% DEBUGPLOTS
function debugplots(dtn,gap,upperThreshold,lowerThreshold,nfill,correct)
subplot(212); hold off;
stem(dtn); hold on;
if correct
    stem(gap:gap+nfill,dtn(gap:gap+nfill),'g','LineWidth',1);
else
    stem(gap:gap+nfill,dtn(gap:gap+nfill),'r','LineWidth',1);
end
xlim([max(0,gap-50) min(gap+50,numel(dtn))])
ylabel('Corrected RR [s]')
xlabel('Samples');% ylim([0 1.7])
line(xlim,[upperThreshold upperThreshold],'Color','k');
line(xlim,[lowerThreshold lowerThreshold],'Color','k');
pause;
end