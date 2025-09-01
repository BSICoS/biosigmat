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
%     stem(dtk, 'k'); hold on
%     stem([19, 39], dtk([19, 39]), 'r')
%     title('Original RR Intervals');
%     ylabel('RR Interval (s)');
%
%     subplot(2,1,2);
%     stem(dtn, 'k');
%     title('Filled RR Intervals');
%     ylabel('RR Interval (s)');
%     xlabel('Beat Index');
%
%   See also TDMETRICS, MEDFILTTHRESHOLD, REMOVEFP
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

% Disable warning for NaN values in interpolation
warning('off', 'MATLAB:interp1:NaNstrip');

% Threshold multipliers for gap detection and validation
kupper = 1.5;
kupperFine = 1/kupper*1.15;
klower = 1/kupper*0.75;

% Ensure tk is a column vector and remove false positives
tk = tk(:);
tk = sort(tk);
tk = removefp(tk);

% Compute inter-beat intervals
dtk = diff(tk);

% Initialize output variables with original values
tn = tk;
dtn = dtk;

% Detect gaps using adaptive baseline threshold
% Gaps are identified as inter-beat intervals significantly longer than the median
baseline = medfiltThreshold(dtk, 30, 1, 1.5);
gaps = find(dtk>baseline*kupper & dtk>0.5);

% Early exit if no gaps are detected
if isempty(gaps)
    return;
end

% Remove gaps at signal edges as they cannot be reliably filled
[gaps, tn, baseline] = removeEdgeGaps(gaps, tn, dtk, baseline, kupper);

% Compute thresholds for each gap based on local baseline
thresholdAtGap = baseline(gaps)*kupper;

% Setup debug figure if debugging is enabled
if debug
    f = set(gcf, 'Position', get(0, 'Screensize'));
end

% Iterative gap filling algorithm
% Start with filling one beat per gap, then progressively increase
nfill = 1;
while ~isempty(gaps)
    % In each iteration, try to fill gaps with 'nfill' number of beats
    for kk = 1:length(gaps)
        % Display original signal with gaps highlighted (debug mode)
        if kk==1 && debug
            subplot(211);
            hold off
            stem(dtn); hold on;
            stem(gaps,dtn(gaps),'r');  % Highlight gaps in red
            hold on
            plot(baseline*kupper,'k--')  % Show detection threshold
            axis tight
            ylabel('Original RR [s]')
        end

        % Attempt to fill current gap with 'nfill' interpolated beats
        auxtn = nfillgap(tn,gaps,gaps(kk),nfill);
        auxdtn = diff(auxtn);

        % Validate the correction: check if interpolated intervals are reasonable
        correct = auxdtn(gaps(kk):gaps(kk)+nfill)<kupperFine*thresholdAtGap(kk);

        % Check if intervals are too small (over-correction indicator)
        limitExceeded = auxdtn(gaps(kk):gaps(kk)+nfill)<klower*thresholdAtGap(kk) | ...
            auxdtn(gaps(kk):gaps(kk)+nfill)<0.5;

        % Debug visualization of the correction attempt
        if debug
            if limitExceeded
                debugplots(auxdtn,gaps(kk),kupperFine*thresholdAtGap(kk),klower*thresholdAtGap(kk),nfill,false);
            else
                debugplots(auxdtn,gaps(kk),kupperFine*thresholdAtGap(kk),klower*thresholdAtGap(kk),nfill,correct);
            end
        end

        % Decide whether to accept the correction
        if limitExceeded
            % Over-correction detected: use previous nfill value instead
            auxtn = nfillgap(tn,gaps,gaps(kk),nfill-1);
            auxdtn = diff(auxtn);
            if debug
                debugplots(auxdtn,gaps(kk),kupperFine*thresholdAtGap(kk),klower*thresholdAtGap(kk),nfill-1,true);
            end
            tn = auxtn;
            gaps = gaps+nfill-1; % Update gap indices after insertion
        elseif correct
            % Correction is valid: accept the filled series
            tn = auxtn;
            gaps = gaps+nfill; % Update gap indices after insertion
        end
        % If neither condition is met, gap remains unfilled for this iteration
    end

    % Prepare for next iteration: recalculate gaps and thresholds
    dtn = diff(tn);
    baseline = medfiltThreshold(dtn, 30, 1, 1.5);
    gaps = find(dtn>baseline*kupper & dtn>0.5);
    thresholdAtGap = baseline(gaps)*kupper;

    nfill = nfill+1; % Increase number of beats to fill per gap
end

% Close debug figure if it was opened
if debug
    close(f);
end

end


%% REMOVEEDGEGAPS
function [gaps, tn, baseline] = removeEdgeGaps(gaps,tn,dtk,baseline,kupper)
% REMOVEEDGEGAPS Remove gaps at signal edges from HRV event series.
%
%   [GAPS, TN, BASELINE] = REMOVEEDGEGAPS(GAPS, TN, DTK, BASELINE, KUPPER)
%   removes gaps that occur at the beginning or end of the HRV signal.
%   GAPS is a vector of gap indices, TN is the event time series, DTK is
%   the difference series (RR intervals), BASELINE is the adaptive threshold
%   baseline, and KUPPER is the upper threshold multiplier.
%
%   Edge gaps cannot be reliably filled due to lack of sufficient context
%   on one side. The function iteratively removes events from the beginning
%   and end of the series until no edge gaps remain. Returns the updated
%   gaps vector, event series, and baseline after edge removal.

% Remove beats from the beginning until no edge gaps remain
while gaps(1)<2
    tn(1) = [];         % Remove first beat
    dtk(1) = [];        % Remove first interval
    baseline(1) = [];   % Remove first baseline value
    gaps = find(dtk>baseline*kupper);  % Recalculate gaps
    if isempty(gaps)
        return;
    end
end

% Remove beats from the end until no edge gaps remain
while gaps(end)>numel(dtk)-1
    tn(end) = [];       % Remove last beat
    dtk(end) = [];      % Remove last interval
    baseline(end) = []; % Remove last baseline value
    gaps = find(dtk>baseline*kupper);  % Recalculate gaps
    if isempty(gaps)
        return;
    end
end

end


%% NFILLGAP
function tn = nfillgap(tk,gaps,currentGap,nfill)
% NFILLGAP Fill a single gap with N interpolated beats in HRV event series.
%
%   TN = NFILLGAP(TK, GAPS, CURRENTGAP, NFILL) interpolates NFILL beats
%   into a specific gap in the HRV event series. TK is the event time series,
%   GAPS is a vector of all gap indices, CURRENTGAP is the index of the gap
%   to fill, and NFILL is the number of beats to interpolate. Returns TN,
%   the corrected event series with the gap filled.
%
%   The function uses piecewise cubic Hermite interpolation (PCHIP) based on
%   surrounding RR intervals (up to 20 beats on each side of the gap). The
%   interpolated intervals are scaled to match the total duration of the gap,
%   ensuring temporal consistency. Other gaps in the series are excluded
%   from the interpolation context to avoid contamination.

dtk = diff(tk);

% Exclude other gaps from interpolation context
gaps(gaps==currentGap) = [];
dtk(gaps) = nan;

% Get the gap duration to be filled
gap = dtk(currentGap);

% Extract context intervals around the gap (up to 4 beats on each side)
nneighbors = 4;
minValidNeighbors = 2; % Minimum required for interpolation

% Start with initial window size and expand if needed
previousIntervals = dtk(max(1,currentGap-nneighbors):currentGap-1);
nextIntervals = dtk(currentGap+1:min(end,currentGap+nneighbors));

% Remove NaN values from context intervals
validPrevious = previousIntervals(~isnan(previousIntervals));
validNext = nextIntervals(~isnan(nextIntervals));

% Expand window if we don't have enough valid intervals on either side
maxNeighbors = min(currentGap-1, length(dtk)-currentGap); % Maximum possible expansion
while (numel(validPrevious) < minValidNeighbors || numel(validNext) < minValidNeighbors) && nneighbors < maxNeighbors
    nneighbors = nneighbors + 1;

    % Extract larger windows
    previousIntervals = dtk(max(1,currentGap-nneighbors):currentGap-1);
    nextIntervals = dtk(currentGap+1:min(end,currentGap+nneighbors));

    % Filter NaN values
    validPrevious = previousIntervals(~isnan(previousIntervals));
    validNext = nextIntervals(~isnan(nextIntervals));
end

% Use the valid intervals for interpolation
previousIntervals = validPrevious;
nextIntervals = validNext;

% Count the number of valid intervals on each side
npre = numel(previousIntervals);
nnext = numel(nextIntervals);

% Interpolate intervals
knownPositions = [1:npre nfill+npre+2:nfill+npre+nnext+1];
knownIntervals = [previousIntervals; nextIntervals];
targetPositions = npre+1:npre+nfill+1;
intervals = interp1(knownPositions,knownIntervals,targetPositions,'pchip');

% Scale interpolated intervals to match the total gap duration
intervals = intervals(1:end-1)*gap/(sum(intervals,'omitnan'));

% Construct the corrected event series
% Insert interpolated beats by computing cumulative times within the gap
tn = [tk(1:currentGap); tk(currentGap)+cumsum(intervals)'; tk(currentGap+1:end)];

end


%% DEBUGPLOTS
function debugplots(dtn,gap,upperThreshold,lowerThreshold,nfill,correct)
% DEBUGPLOTS Visualization for gap filling debugging in HRV analysis.
%
%   DEBUGPLOTS(DTN, GAP, UPPERTHRESHOLD, LOWERTHRESHOLD, NFILL, CORRECT)
%   displays the correction results with threshold lines for visual inspection
%   of the gap filling process. DTN is the corrected RR interval series, GAP
%   is the index of the current gap being filled, UPPERTHRESHOLD and
%   LOWERTHRESHOLD are the validation thresholds, NFILL is the number of
%   beats being interpolated, and CORRECT is a logical indicating whether
%   the correction meets validation criteria.
%
%   The function creates a stem plot of the RR intervals with color-coded
%   visualization: green for correct fills, red for incorrect fills. Threshold
%   lines are displayed for reference, and the view is focused around the
%   current gap. The function pauses for user interaction to allow step-by-step
%   inspection of the gap filling process.

% Create a new subplot for the corrected RR intervals
subplot(212);
hold off;
stem(dtn);
hold on;

filledPositions = gap:gap+nfill;

% Color-code the filled intervals: green for correct, red for incorrect
if correct
    stem(filledPositions,dtn(filledPositions),'g','LineWidth',1);
else
    stem(filledPositions,dtn(filledPositions),'r','LineWidth',1);
end

% Focus view around the current gap
xlim([max(0,gap-50) min(gap+50,numel(dtn))])
ylim([0 1.1*max(dtn(filledPositions))])
ylabel('Corrected RR [s]')
xlabel('Samples');

% Display threshold lines for reference
line(xlim,[upperThreshold upperThreshold],'Color','k');
line(xlim,[lowerThreshold lowerThreshold],'Color','k');

% Wait for user input to continue
pause;

end