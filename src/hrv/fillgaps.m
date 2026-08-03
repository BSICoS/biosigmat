function [tn, dtn] = fillgaps(tk, varargin)
% FILLGAPS Reconstruct missing events inside locally detected gaps.
%
%   TN = FILLGAPS(TK) reconstructs missing event timestamps in the finite,
%   strictly increasing event-time vector TK. TK must already have undergone
%   any desired false-positive removal; FILLGAPS never calls REMOVEFP
%   implicitly. Every original timestamp is preserved exactly.
%
%   [TN, DTN] = FILLGAPS(TK) also returns the successive corrected intervals.
%   A DTN element spanning a gap that cannot be reconstructed is NaN.
%
%   FILLGAPS(TK, DEBUG) preserves the historical optional visualization feature.
%   DEBUG defaults to false and never changes the numerical result.
%
%   FILLGAPS(TK, DEBUG, MAXGAPDURATION) preserves the historical positional
%   maximum-gap argument. MAXGAPDURATION maps to the canonical Biosiglib
%   max_gap_duration parameter and defaults to 10 seconds.
%
%   FILLGAPS(..., NAME, VALUE) accepts the remaining canonical parameters with
%   MATLAB names:
%     'GapDetectionFactor'    (gap_detection_factor, default 1.5)
%     'CorrectionUpperFactor' (correction_upper_factor, default 1.15)
%     'CorrectionLowerFactor' (correction_lower_factor, default 0.75)
%     'MinimumInterval'       (minimum_interval, default 0.5 seconds)
%
%   The factors must satisfy 0 < CorrectionLowerFactor <
%   CorrectionUpperFactor <= GapDetectionFactor.
%
%   Example:
%     observed = [0 1 2 4 5 6];
%     cleaned = removefp(observed);
%     [tn, dtn] = fillgaps(cleaned);
%
%   See also REMOVEFP, MEDFILTTHRESHOLD, INTERP1

narginchk(1, 11);
nargoutchk(0, 2);

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

tn = parser.Results.tk(:);
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

if numel(tn) < 3
    dtn = diff(tn);
    if debug
        plotCorrection(tn, dtn);
    end
    return;
end

unresolved = containers.Map('KeyType', 'char', 'ValueType', 'logical');
nextInsertionCount = containers.Map('KeyType', 'char', 'ValueType', 'double');
previousReconstructions = containers.Map('KeyType', 'char', 'ValueType', 'any');

while true
    intervals = diff(tn);
    baseline = medfiltThreshold(intervals, 30, 1, 1.5);
    pairKeys = intervalPairKeys(tn);
    detected = find(intervals > gapDetectionFactor .* baseline & ...
        intervals > minimumInterval);
    blocked = find(cellfun(@(key) isKey(unresolved, key), pairKeys));
    candidates = setdiff(detected, blocked, 'stable');
    if isempty(candidates)
        break;
    end

    allUnresolved = union(detected, blocked);
    accepted = containers.Map('KeyType', 'char', 'ValueType', 'any');
    newlyUnresolved = {};

    for candidateIndex = 1:numel(candidates)
        gapIndex = candidates(candidateIndex);
        key = pairKeys{gapIndex};
        gapDuration = intervals(gapIndex);
        if gapDuration > maxGapDuration
            newlyUnresolved{end + 1} = key; %#ok<AGROW>
            continue;
        end

        support = interpolationSupport(intervals, gapIndex, allUnresolved);
        if isempty(support)
            newlyUnresolved{end + 1} = key; %#ok<AGROW>
            continue;
        end

        if isKey(nextInsertionCount, key)
            insertionCount = nextInsertionCount(key);
        else
            insertionCount = 1;
        end
        reconstruction = reconstructIntervals( ...
            support, gapDuration, insertionCount);
        lowerBoundary = max( ...
            correctionLowerFactor * baseline(gapIndex), minimumInterval);
        upperBoundary = correctionUpperFactor * baseline(gapIndex);

        % Over-insertion takes precedence because it also satisfies the upper test.
        if all(reconstruction < lowerBoundary)
            if isKey(previousReconstructions, key)
                accepted(key) = previousReconstructions(key);
            else
                newlyUnresolved{end + 1} = key; %#ok<AGROW>
            end
        elseif all(reconstruction < upperBoundary)
            accepted(key) = reconstruction;
        else
            previousReconstructions(key) = reconstruction;
            nextInsertionCount(key) = insertionCount + 1;
        end
    end

    for index = 1:numel(newlyUnresolved)
        key = newlyUnresolved{index};
        unresolved(key) = true;
        removeIfPresent(nextInsertionCount, key);
        removeIfPresent(previousReconstructions, key);
    end
    acceptedKeys = keys(accepted);
    for index = 1:numel(acceptedKeys)
        key = acceptedKeys{index};
        removeIfPresent(nextInsertionCount, key);
        removeIfPresent(previousReconstructions, key);
    end
    if ~isempty(acceptedKeys)
        tn = applyReconstructions(tn, pairKeys, accepted);
    end
end

dtn = diff(tn);
finalPairKeys = intervalPairKeys(tn);
for index = 1:numel(finalPairKeys)
    if isKey(unresolved, finalPairKeys{index})
        dtn(index) = NaN;
    end
end

if debug
    plotCorrection(tn, dtn);
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


function pairKeys = intervalPairKeys(events)
pairKeys = arrayfun(@(index) pairKey(events(index), events(index + 1)), ...
    1:numel(events) - 1, 'UniformOutput', false);
end


function key = pairKey(left, right)
key = sprintf('%.17g|%.17g', left, right);
end


function support = interpolationSupport(intervals, gapIndex, unresolvedIndices)
excluded = setdiff(unresolvedIndices, gapIndex);
previous = [];
for index = gapIndex - 1:-1:1
    if ~ismember(index, excluded)
        previous(end + 1) = intervals(index); %#ok<AGROW>
        if numel(previous) == 2
            break;
        end
    end
end
following = [];
for index = gapIndex + 1:numel(intervals)
    if ~ismember(index, excluded)
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


function reconstruction = reconstructIntervals(support, gapDuration, insertionCount)
coordinates = [-1, 0, insertionCount + 2, insertionCount + 3];
targets = 1:insertionCount + 1;
raw = interp1(coordinates, support, targets, 'pchip');
reconstruction = raw * gapDuration / sum(raw);
reconstruction(end) = gapDuration - sum(reconstruction(1:end - 1));
reconstruction = reconstruction(:);
end


function corrected = applyReconstructions(events, pairKeys, accepted)
corrected = events(1);
for index = 1:numel(events) - 1
    left = events(index);
    key = pairKeys{index};
    if isKey(accepted, key)
        reconstruction = accepted(key);
        inserted = left + cumsum(reconstruction(1:end - 1));
        corrected = [corrected; inserted(:)]; %#ok<AGROW>
    end
    corrected(end + 1, 1) = events(index + 1); %#ok<AGROW>
end
end


function removeIfPresent(map, key)
if isKey(map, key)
    remove(map, key);
end
end


function plotCorrection(tn, dtn)
figure;
subplot(2, 1, 1);
stem(tn, ones(size(tn)), 'filled');
xlabel('Time [s]');
title('Corrected event timestamps');
subplot(2, 1, 2);
stem(dtn, 'filled');
xlabel('Interval index');
ylabel('Interval [s]');
title('Corrected intervals');
end
