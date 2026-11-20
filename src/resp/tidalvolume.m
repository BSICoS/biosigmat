function [tdvol, upper, lower] = tidalvolume(resp, fs, varargin)
% TIDALVOLUME Extracts upper and lower peak envelopes from a signal.
%
%   TDVOL = TIDALVOLUME(RESP, FS) extracts a signal proportional to an estimation
%   of the tidal volume from a respiration signal RESP (numeric vector).
%   FS is the sampling frequency in Hz. Each complete peak-to-following-valley
%   amplitude is assigned to the midpoint in time between those extrema.
%
%   The algorithm does not detect every peak and valley to compute the envelopes.
%   It only uses peaks and valleys between zero crossings. This way we assure
%   that small fluctuations that may occur in real respiration signals are not
%   detected as separate events. This means that the function expects detrended
%   input signals. Although a simple detrend is performed internally, a
%   preprocessing step to remove any slow drifts or trends is recommended.
%
%   ALGORITHM PHILOSOPHY:
%   - Peak-valley synchronization is guaranteed by the zero-crossing approach
%   - Peaks are defined as global maxima between consecutive zero crossings
%   - Valleys are defined as global minima between consecutive zero crossings
%   - This definition ignores intermediate local maxima/minima that don't cross zero
%   - This approach has physiological sense: it removes noise, artifacts, and
%     imperfections in breathing patterns while preserving the main respiratory cycles
%   - The method ensures robust envelope extraction for real respiratory signals
%
%   TDVOL = TIDALVOLUME(RESP, FS, MINDIST) specifies the minimum distance between
%   consecutive zero-crossing candidates in seconds. MINDIST is a non-negative scalar with default
%   value 0.
%
%   [...] = TIDALVOLUME(..., 'MaxGap', SECONDS) splits interpolation where
%   consecutive anchors of the same curve are at least SECONDS apart.
%   The default is Inf. Missing samples interrupt detection. Each curve can
%   interpolate across missing samples within its supported anchor groups.
%
%   [TDVOL, UPPER, LOWER] = TIDALVOLUME(...) also returns the UPPER and
%   LOWER envelopes connecting the peaks and valleys.

%   Example:
%     % Extract envelopes from a modulated sine wave
%     t = (0:0.001:2)';
%     signal = sin(2*pi*5*t) .* (1 + 0.5*sin(2*pi*0.5*t));
%     [amplitude, upper, lower] = tidalvolume(signal, 1000);
%
%     % Plot results
%     figure;
%     plot(t, signal, 'b', t, upper, 'r', t, lower, 'g', t, amplitude, 'm');
%     legend('Signal', 'Upper Envelope', 'Lower Envelope', 'Amplitude');
%     title('Peak Envelopes Extraction');
%     xlabel('Time (s)');
%     ylabel('Amplitude');
%
%   See also ENVELOPE, INTERP1


% Check number of input and output arguments
narginchk(2, 5);
nargoutchk(0, 3);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'tidalvolume';
addRequired(parser, 'resp', @(x) isnumeric(x) && isreal(x) && isvector(x) && ~isempty(x) && ~any(isinf(x)));
addRequired(parser, 'fs', @(x) isnumeric(x) && isreal(x) && isscalar(x) && isfinite(x) && x > 0);
addOptional(parser, 'mindist', 0, @(x) isnumeric(x) && isreal(x) && isscalar(x) && isfinite(x) && x >= 0);
addParameter(parser, 'MaxGap', Inf, @(x) isnumeric(x) && isreal(x) && isscalar(x) && x > 0);

parse(parser, resp, fs, varargin{:});

resp = parser.Results.resp;
mindist = parser.Results.mindist;

% Remove the linear trend using observed samples at their original times.
resp = double(resp(:));
valid = isfinite(resp);
observed = find(valid);
if numel(observed) >= 2
    centeredTime = observed - mean(observed);
    centeredResp = resp(valid) - mean(resp(valid));
    slope = (centeredTime' * centeredResp) / (centeredTime' * centeredTime);
    resp(valid) = centeredResp - slope * centeredTime;
end

% Detect complete half-cycles and pair extrema within each observed segment.
edges = diff([false; valid; false]);
starts = find(edges == 1);
stops = find(edges == -1) - 1;
peakAnchors = cell(numel(starts), 1);
valleyAnchors = cell(numel(starts), 1);
volumeAnchors = cell(numel(starts), 1);
for k = 1:numel(starts)
    segment = resp(starts(k):stops(k));
    [downcross, upcross] = detectZeroCrossings(segment, mindist, fs);
    if isempty(downcross) || isempty(upcross)
        continue
    end
    [peaks, peakIndices, valleys, valleyIndices] = findPeaksAndValleys(segment, downcross, upcross);
    peakIndices = peakIndices + starts(k) - 1;
    valleyIndices = valleyIndices + starts(k) - 1;
    peakAnchors{k} = [peakIndices, peaks];
    valleyAnchors{k} = [valleyIndices, valleys];
    volumeAnchors{k} = calculateTidalVolume(peaks, peakIndices, valleys, valleyIndices);
end

% Fit each curve from its own anchors. Use row vectors on the sample grid.
upper = interpolateEnvelope(vertcat(peakAnchors{:}), numel(resp), fs, parser.Results.MaxGap);
lower = interpolateEnvelope(vertcat(valleyAnchors{:}), numel(resp), fs, parser.Results.MaxGap);
tdvol = interpolateEnvelope(vertcat(volumeAnchors{:}), numel(resp), fs, parser.Results.MaxGap);

end


%% DETECTZEROCROSSINGS
function [downcross, upcross] = detectZeroCrossings(resp, mindist, fs)
% DETECTZEROCROSSINGS Find zero crossings in a signal with minimum distance filtering.
%
%   [DOWNCROSS, UPCROSS] = DETECTZEROCROSSINGS(RESP, MINDIST, FS) finds downward
%   and upward zero crossings in the signal RESP. MINDIST specifies the minimum
%   distance in seconds between raw crossings. FS is the sampling frequency in Hz.
%
%   FILTERING STRATEGY:
%   - First detects ALL zero crossings regardless of direction
%   - Then filters out crossings that are too close together (noise-induced)
%   - Ensures strict alternating pattern by removing consecutive crossings of same type
%   - Finally classifies remaining crossings into upward/downward
%   - This approach avoids complex edge cases that arise from separate filtering

% Find all zero crossings
nonzero = find(resp ~= 0);
zerocross = diff(sign(resp(nonzero)));
changes = find(abs(zerocross) == 2);
allCrossings = nonzero(changes + 1);
crossingTypes = zerocross(changes);

% Filter close crossings to reduce noise effects
% Keep the first crossing from each group of close crossings
if mindist > 0 && length(allCrossings) > 1
    keepCrossings = true(size(allCrossings));
    for kk = 2:length(allCrossings)
        if (allCrossings(kk) - allCrossings(kk-1)) / fs < mindist
            keepCrossings(kk) = false;
        end
    end
    filteredCrossings = allCrossings(keepCrossings);
    crossingTypes = crossingTypes(keepCrossings);
else
    filteredCrossings = allCrossings;
end

% Classify into upward and downward crossings after filtering
if ~isempty(filteredCrossings)
    % Additional filtering: ensure alternating pattern by removing consecutive
    % crossings of the same type (keep only the first of each group)
    if length(filteredCrossings) > 1
        keepAlternating = true(size(filteredCrossings));
        for kk = 2:length(filteredCrossings)
            if crossingTypes(kk) == crossingTypes(kk-1)
                keepAlternating(kk) = false;
            end
        end
        filteredCrossings = filteredCrossings(keepAlternating);
        crossingTypes = crossingTypes(keepAlternating);
    end

    downcross = filteredCrossings(crossingTypes == -2);
    upcross = filteredCrossings(crossingTypes == 2);
else
    downcross = [];
    upcross = [];
end

end


%% FINDPEAKSANDVALLEYS
function [peaks, peakIndices, valleys, valleyIndices] = findPeaksAndValleys(resp, downcross, upcross)
% FINDPEAKSANDVALLEYS Find peaks and valleys between zero crossings.
%
%   [PEAKS, PEAKINDICES, VALLEYS, VALLEYINDICES] = FINDPEAKSANDVALLEYS(RESP, DOWNCROSS, UPCROSS)
%   finds peaks and valleys in the signal RESP between zero crossings defined by
%   DOWNCROSS and UPCROSS indices.
%
%   KEY DESIGN PRINCIPLES:
%   - Peaks and valleys are ALWAYS synchronized by design due to zero-crossing approach
%   - Each peak/valley represents the global extremum between consecutive zero crossings
%   - Intermediate local extrema (that don't cross zero) are intentionally ignored
%   - This ensures robust detection despite noise, artifacts, or breathing irregularities
%   - The difference in array lengths can be at most 1 due to signal start/end effects

% Initialize output arrays with same size (synchronized by design)
peaks = nan(size(downcross));
peakIndices = peaks;
valleys = peaks;
valleyIndices = peaks;

if downcross(1) < upcross(1)
    % Case 1: Signal starts with downcross (expiration phase)
    % Sequence: downcross -> valley -> upcross -> peak -> downcross -> ...

    % Find peaks between upcross and downcross
    for kk=2:length(downcross)
        indexes = upcross(kk-1):downcross(kk);
        [peaks(kk), peakIndices(kk)] = max(resp(indexes));
        peakIndices(kk) = peakIndices(kk) + upcross(kk-1) - 1;
    end

    % Find valleys between downcross and upcross
    for kk=1:length(upcross)
        indexes = downcross(kk):upcross(kk);
        [valleys(kk), valleyIndices(kk)] = min(resp(indexes));
        valleyIndices(kk) = valleyIndices(kk) + downcross(kk) - 1;
    end
else
    % Case 2: Signal starts with upcross (inhalation phase)
    % Sequence: upcross -> peak -> downcross -> valley -> upcross -> ...

    % Find peaks between upcross and downcross
    for kk=1:length(downcross)
        indexes = upcross(kk):downcross(kk);
        [peaks(kk), peakIndices(kk)] = max(resp(indexes));
        peakIndices(kk) = peakIndices(kk) + upcross(kk) - 1;
    end

    % Find valleys between downcross and upcross
    for kk=2:length(upcross)
        indexes = downcross(kk-1):upcross(kk);
        [valleys(kk), valleyIndices(kk)] = min(resp(indexes));
        valleyIndices(kk) = valleyIndices(kk) + downcross(kk-1) - 1;
    end
end

% Remove NaNs from output (clean up unused positions)
peaks = peaks(~isnan(peakIndices));
peakIndices = peakIndices(~isnan(peakIndices));
valleys = valleys(~isnan(valleyIndices));
valleyIndices = valleyIndices(~isnan(valleyIndices));

end


%% INTERPOLATEENVELOPE
function envelope = interpolateEnvelope(anchors, sampleCount, fs, maxGap)
% INTERPOLATEENVELOPE Interpolate independent groups of respiratory anchors.
%
%   ENVELOPE = INTERPOLATEENVELOPE(ANCHORS, SAMPLECOUNT, FS, MAXGAP)
%   interpolates position/amplitude pairs on the sample grid. Positions can
%   be half samples. A separation of MAXGAP seconds starts a new group.

envelope = nan(1, sampleCount);
if size(anchors, 1) < 2
    return
end
boundaries = [1; find(diff(anchors(:,1)) / fs >= maxGap) + 1; size(anchors,1) + 1];
for k = 1:numel(boundaries)-1
    group = anchors(boundaries(k):boundaries(k+1)-1,:);
    if size(group,1) >= 2
        samples = ceil(group(1,1)):floor(group(end,1));
        envelope(samples) = interp1(group(:,1), group(:,2), samples, 'pchip');
    end
end
end


%% CALCULATETIDALVOLUME
function anchors = calculateTidalVolume(peaks, peakIndices, valleys, valleyIndices)
% CALCULATETIDALVOLUME Calculate one tidal-volume anchor per complete pair.
%
%   ANCHORS = CALCULATETIDALVOLUME(PEAKS, PEAKINDICES, VALLEYS, VALLEYINDICES)
%   pairs each peak with the following valley in the same observed segment.
%   Each row contains the midpoint in samples and the peak-to-valley amplitude.

if isempty(peaks) || isempty(valleys)
    anchors = zeros(0, 2);
    return
end
if valleyIndices(1) < peakIndices(1)
    valleys = valleys(2:end);
    valleyIndices = valleyIndices(2:end);
end
pairs = 1:min(numel(peaks), numel(valleys));
midpoints = (peakIndices(pairs) + valleyIndices(pairs)) / 2;
amplitudes = peaks(pairs) - valleys(pairs);
anchors = [midpoints(:), amplitudes(:)];
end
