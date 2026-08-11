function [tn, dtn] = fillgaps(tk, varargin)
% FILLGAPS Reconstruct missing events inside locally detected gaps.
%
%   TN = FILLGAPS(TK) reconstructs missing event timestamps in TK. TK must
%   be a non-empty vector of finite event times in seconds, ordered strictly
%   increasingly. FILLGAPS does not sort TK and does not remove false-positive
%   detections; apply REMOVEFP explicitly first when that preprocessing is
%   required. Every original timestamp is preserved exactly.
%
%   [TN, DTN] = FILLGAPS(TK) also returns the successive intervals of TN.
%   An interval that spans a detected gap which cannot be reconstructed is
%   represented by NaN in DTN. A gap remains unresolved when it exceeds the
%   maximum duration or lacks two valid neighboring intervals on either side.
%
%   FILLGAPS(TK, DEBUG) enables interactive visual inspection when DEBUG is
%   true. The upper plot shows the current interval series, detected gaps and
%   detection threshold. For every reconstruction attempt, the lower plot
%   shows the candidate intervals and the upper and lower validation limits;
%   accepted candidates are green and rejected candidates are red. Execution
%   pauses after each attempt until the user continues. If over-insertion is
%   detected, the rejected attempt is shown first and the retained preceding
%   attempt is then shown in green. The debug figure closes when processing
%   finishes. DEBUG defaults to false and does not change numerical results.
%
%   FILLGAPS(TK, DEBUG, MAXGAPDURATION) attempts only detected gaps whose
%   duration is at most MAXGAPDURATION seconds. Longer gaps remain in TN and
%   are represented by NaN in DTN. The default is 10 seconds.
%
%   FILLGAPS(..., NAME, VALUE) accepts these parameters:
%     'GapDetectionFactor'    Detection factor, default 1.5.
%     'CorrectionUpperFactor' Upper acceptance factor, default 1.15.
%     'CorrectionLowerFactor' Over-insertion factor, default 0.75.
%     'MinimumInterval'       Absolute interval floor in seconds, default 0.5.
%
%   The factors must satisfy 0 < CorrectionLowerFactor <
%   CorrectionUpperFactor <= GapDetectionFactor. Detected gaps are attempted
%   segment-wide with one inserted event, then two, and so on. Interpolation
%   uses PCHIP with the two nearest valid intervals on each side and preserves
%   the exact duration between the original timestamps.
%
%   Example:
%     observed = [0 1 2 4 5 6];
%     cleaned = removefp(observed);
%     [tn, dtn] = fillgaps(cleaned, true);
%
%   See also REMOVEFP, MEDFILTTHRESHOLD, INTERP1

% Check number of input and output arguments
narginchk(1, 11);
nargoutchk(0, 2);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'fillgaps';
addRequired(parser, 'tk', @(x) isnumeric(x) && isreal(x) && isvector(x) && ...
    ~isempty(x) && all(isfinite(x)));
addOptional(parser, 'debug', false, @(x) islogical(x) && isscalar(x));
addOptional(parser, 'maxgapduration', 10, @isPositiveFiniteScalar);
addParameter(parser, 'GapDetectionFactor', 1.5, @isPositiveFiniteScalar);
addParameter(parser, 'CorrectionUpperFactor', 1.15, @isPositiveFiniteScalar);
addParameter(parser, 'CorrectionLowerFactor', 0.75, @isPositiveFiniteScalar);
addParameter(parser, 'MinimumInterval', 0.5, @isNonnegativeFiniteScalar);
parse(parser, tk, varargin{:});

tn = double(parser.Results.tk(:));
debug = parser.Results.debug;
maxGapDuration = parser.Results.maxgapduration;
gapDetectionFactor = parser.Results.GapDetectionFactor;
correctionUpperFactor = parser.Results.CorrectionUpperFactor;
correctionLowerFactor = parser.Results.CorrectionLowerFactor;
minimumInterval = parser.Results.MinimumInterval;

if any(diff(tn) <= 0)
    error('biosigmat:fillgaps:EventOrder', ...
        'tk must contain strictly increasing event timestamps.');
end
if ~(correctionLowerFactor < correctionUpperFactor && ...
        correctionUpperFactor <= gapDetectionFactor)
    error('biosigmat:fillgaps:ParameterRelationship', ...
        ['Factors must satisfy 0 < CorrectionLowerFactor < ' ...
        'CorrectionUpperFactor <= GapDetectionFactor.']);
end

% Initialize output variables with original values
dtn = diff(tn);
if numel(tn) < 3
    return;
end

% Detect gaps using the adaptive baseline threshold
baseline = medfiltThreshold(dtn, 30, 1, 1.5);
detectedGaps = find(dtn > gapDetectionFactor .* baseline & ...
    dtn > minimumInterval);
unresolved = containers.Map('KeyType', 'char', 'ValueType', 'logical');
gaps = findCorrectableGaps(tn, dtn, detectedGaps, maxGapDuration, unresolved);

% Setup debug figure if debugging is enabled
debugFigure = [];
if debug && ~isempty(gaps)
    debugFigure = figure('Name', 'fillgaps interactive debug');
    set(debugFigure, 'Position', get(0, 'Screensize'));
end

% Iterative gap filling algorithm
% Start with one inserted event per gap, then progressively increase.
nfill = 1;
while ~isempty(gaps)
    thresholdAtGap = baseline(gaps);

    for kk = 1:numel(gaps)
        if kk == 1 && debug
            plotDebugOverview(debugFigure, dtn, gaps, ...
                gapDetectionFactor .* baseline, nfill);
        end

        currentGap = gaps(kk);
        currentKey = pairKey(tn(currentGap), tn(currentGap + 1));
        currentPairKeys = intervalPairKeys(tn);
        blockedGaps = find(cellfun( ...
            @(key) isKey(unresolved, key), currentPairKeys));
        excludedGaps = union(gaps(kk:end), blockedGaps);

        % Attempt to fill the current gap with NFILL interpolated events.
        auxtn = nfillgap(tn, excludedGaps, currentGap, nfill);
        auxdtn = diff(auxtn);
        reconstructed = auxdtn(currentGap:currentGap + nfill);
        upperThreshold = correctionUpperFactor * thresholdAtGap(kk);
        lowerThreshold = max( ...
            correctionLowerFactor * thresholdAtGap(kk), minimumInterval);

        % A correction is sufficient only when every interval is below the
        % upper limit. Over-insertion requires every interval below the lower.
        correct = all(reconstructed < upperThreshold);
        limitExceeded = all(reconstructed < lowerThreshold);

        if debug
            debugplots(debugFigure, auxdtn, currentGap, upperThreshold, ...
                lowerThreshold, nfill, correct && ~limitExceeded);
        end

        if limitExceeded
            if nfill == 1
                % No preceding attempt exists to retain.
                unresolved(currentKey) = true;
            else
                % Retain the reconstruction from the preceding insertion count.
                auxtn = nfillgap(tn, excludedGaps, currentGap, nfill - 1);
                auxdtn = diff(auxtn);
                if debug
                    debugplots(debugFigure, auxdtn, currentGap, ...
                        upperThreshold, lowerThreshold, nfill - 1, true);
                end
                tn = auxtn;
                gaps(kk + 1:end) = gaps(kk + 1:end) + nfill - 1;
            end
        elseif correct
            tn = auxtn;
            gaps(kk + 1:end) = gaps(kk + 1:end) + nfill;
        end
    end

    % Recalculate the baseline and unresolved gaps after the complete pass.
    dtn = diff(tn);
    baseline = medfiltThreshold(dtn, 30, 1, 1.5);
    detectedGaps = find(dtn > gapDetectionFactor .* baseline & ...
        dtn > minimumInterval);
    gaps = findCorrectableGaps( ...
        tn, dtn, detectedGaps, maxGapDuration, unresolved);
    nfill = nfill + 1;
end

% Preserve unresolved original timestamps and mark their spanning intervals.
dtn = diff(tn);
finalPairKeys = intervalPairKeys(tn);
for index = 1:numel(finalPairKeys)
    if isKey(unresolved, finalPairKeys{index})
        dtn(index) = NaN;
    end
end

if debug && ~isempty(debugFigure) && isgraphics(debugFigure)
    close(debugFigure);
end
end


function valid = isPositiveFiniteScalar(value)
valid = isnumeric(value) && isreal(value) && isscalar(value) && ...
    isfinite(value) && value > 0;
end


function valid = isNonnegativeFiniteScalar(value)
valid = isnumeric(value) && isreal(value) && isscalar(value) && ...
    isfinite(value) && value >= 0;
end


function gaps = findCorrectableGaps( ...
        events, intervals, detectedGaps, maxGapDuration, unresolved)
pairKeys = intervalPairKeys(events);
blockedGaps = find(cellfun(@(key) isKey(unresolved, key), pairKeys));
excludedGaps = union(detectedGaps, blockedGaps);
gaps = [];

for index = 1:numel(detectedGaps)
    gapIndex = detectedGaps(index);
    gapKey = pairKeys{gapIndex};
    if isKey(unresolved, gapKey)
        continue;
    end
    support = interpolationSupport(intervals, gapIndex, excludedGaps);
    if intervals(gapIndex) > maxGapDuration || isempty(support)
        unresolved(gapKey) = true;
    else
        gaps(end + 1) = gapIndex; %#ok<AGROW>
    end
end
end


function pairKeys = intervalPairKeys(events)
pairKeys = arrayfun(@(index) pairKey(events(index), events(index + 1)), ...
    1:numel(events) - 1, 'UniformOutput', false);
end


function key = pairKey(left, right)
key = sprintf('%.17g|%.17g', left, right);
end


%% NFILLGAP
function tn = nfillgap(tk, gaps, currentGap, nfill)
% NFILLGAP Fill one gap using the normative local PCHIP support.

dtk = diff(tk);
gapDuration = dtk(currentGap);
support = interpolationSupport(dtk, currentGap, gaps);

coordinates = [-1, 0, nfill + 2, nfill + 3];
targets = 1:nfill + 1;
reconstructed = interp1(coordinates, support, targets, 'pchip');

% Preserve the exact duration between the two original timestamps.
reconstructed = reconstructed * gapDuration / sum(reconstructed);
reconstructed(end) = gapDuration - sum(reconstructed(1:end - 1));
inserted = tk(currentGap) + cumsum(reconstructed(1:end - 1));
tn = [tk(1:currentGap); inserted(:); tk(currentGap + 1:end)];
end


function support = interpolationSupport(intervals, currentGap, gaps)
excludedGaps = setdiff(gaps, currentGap);

previous = [];
for index = currentGap - 1:-1:1
    if ~ismember(index, excludedGaps)
        previous(end + 1) = intervals(index); %#ok<AGROW>
        if numel(previous) == 2
            break;
        end
    end
end

following = [];
for index = currentGap + 1:numel(intervals)
    if ~ismember(index, excludedGaps)
        following(end + 1) = intervals(index); %#ok<AGROW>
        if numel(following) == 2
            break;
        end
    end
end

if numel(previous) < 2 || numel(following) < 2
    support = [];
else
    support = [fliplr(previous), following];
end
end


function plotDebugOverview(debugFigure, dtn, gaps, threshold, nfill)
set(groot, 'CurrentFigure', debugFigure);
subplot(2, 1, 1);
hold off;
stem(dtn, 'Color', [0.15, 0.15, 0.15]);
hold on;
stem(gaps, dtn(gaps), 'r', 'LineWidth', 1);
plot(threshold, 'k--');
axis tight;
ylabel('Current RR [s]');
title(sprintf('Detected gaps: testing %d inserted event(s)', nfill));
legend('RR intervals', 'Detected gaps', 'Detection threshold', ...
    'Location', 'best');
drawnow;
end


%% DEBUGPLOTS
function debugplots(debugFigure, dtn, gap, upperThreshold, ...
        lowerThreshold, nfill, correct)
% DEBUGPLOTS Show one reconstruction attempt and wait for user input.

set(groot, 'CurrentFigure', debugFigure);
subplot(2, 1, 2);
hold off;
stem(dtn, 'Color', [0.15, 0.15, 0.15]);
hold on;

filledPositions = gap:gap + nfill;
if correct
    attemptColor = 'g';
    attemptStatus = 'accepted';
else
    attemptColor = 'r';
    attemptStatus = 'rejected';
end
stem(filledPositions, dtn(filledPositions), attemptColor, 'LineWidth', 1);

xlim([max(0.5, gap - 50), min(numel(dtn) + 0.5, gap + 50)]);
visibleMaximum = max([dtn(filledPositions); upperThreshold; lowerThreshold]);
if ~isfinite(visibleMaximum) || visibleMaximum <= 0
    visibleMaximum = 1;
end
ylim([0, 1.1 * visibleMaximum]);
ylabel('Candidate RR [s]');
xlabel('Interval index');
line(xlim, [upperThreshold, upperThreshold], ...
    'Color', 'k', 'LineStyle', '--');
line(xlim, [lowerThreshold, lowerThreshold], ...
    'Color', 'k', 'LineStyle', ':');
displayStatus = [upper(attemptStatus(1)), attemptStatus(2:end)];
title(sprintf('%s attempt: %d inserted event(s)', displayStatus, nfill));
legend('Candidate intervals', attemptStatus, 'Upper limit', 'Lower limit', ...
    'Location', 'best');
drawnow;

% Continue only when the user explicitly advances the interactive check.
pause;
end
