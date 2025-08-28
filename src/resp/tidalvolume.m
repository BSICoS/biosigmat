function [tdvol, upper, lower] = tidalvolume(resp, varargin)
% TIDALVOLUME Extracts upper and lower peak envelopes from a signal.
%
%   TDVOL = TIDALVOLUME(SIGNAL) extracts a signal proportional to an estimation
%   of the tidal volume from a respiration signal RESP (numeric vector).
%   The estimation is performed using the upper and lower envelopes connecting the
%   peaks and valleys.
%
%   The algorithm does not detect every peak and valley to compute the envelopes.
%   It only uses peaks and valleys between zero crossings. This way we assure
%   that small fluctuations that may occur in real respiration signals are not
%   detected as separate events. This means that the function expects detrended
%   input signals. Although a simple detrend is performed internally, a
%   preprocessing step to remove any slow drifts or trends is recommended.
%
%   TDVOL = TIDALVOLUME(SIGNAL, MINDIST) specifies the minimum distance between
%   consecutive peaks in samples. MINDIST is a non-negative scalar with default
%   value 0.
%
%   [TDVOL, UPPER, LOWER] = TIDALVOLUME(...) also returns the UPPER and
%   LOWER envelopes connecting the peaks and valleys.

%   Example:
%     % Extract envelopes from a modulated sine wave
%     t = 0:0.001:2;
%     signal = sin(2*pi*5*t) .* (1 + 0.5*sin(2*pi*0.5*t))';
%     [upper, lower, amplitude] = peakenvelopes(signal);
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
%
%   Status: Alpha


% Check number of input and output arguments
narginchk(1, 2);
nargoutchk(0, 3);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'tidalvolume';
addRequired(parser, 'resp', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addOptional(parser, 'mindist', 0, @(x) isnumeric(x) && isscalar(x) && x >= 0);

parse(parser, resp, varargin{:});

resp = parser.Results.resp;
mindist = parser.Results.mindist;

% Ensure column vector and detrend
resp = resp(:);
resp = detrend(resp, 'omitnan');

% Find zero crossings and filter by minimum distance
[downcross, upcross] = detectZeroCrossings(resp, mindist);

% Find peaks and valleys between zero crossings
[peaks, peakIndices, valleys, valleyIndices] = findPeaksAndValleys(resp, downcross, upcross);

% Interpolate envelopes and handle invalid regions
upper = interpolateEnvelope(peakIndices, peaks, resp, upcross(1), downcross(end));
lower = interpolateEnvelope(valleyIndices, valleys, resp, downcross(1), upcross(end));

% Calculate tidal volume
tdvol = calculateTidalVolume(peaks, peakIndices, valleys, valleyIndices, resp, upper, lower);

end


%% DETECTZEROCROSSINGS
function [downcross, upcross] = detectZeroCrossings(resp, mindist)
% DETECTZEROCROSSINGS Find zero crossings in a signal with minimum distance filtering.
%
%   [DOWNCROSS, UPCROSS] = DETECTZEROCROSSINGS(RESP, MINDIST) finds downward
%   and upward zero crossings in the signal RESP. MINDIST specifies the minimum
%   distance between consecutive crossings to reduce noise effects.

% Find all zero crossings first
zerocross = diff(sign(resp));
allCrossings = find(abs(zerocross) == 2) + 1;

% Filter close crossings to reduce noise effects
if mindist > 0 && length(allCrossings) > 1
    % Keep the first crossing from each group of close crossings
    keepCrossings = true(size(allCrossings));
    for kk = 2:length(allCrossings)
        if allCrossings(kk) - allCrossings(kk-1) < mindist
            keepCrossings(kk) = false;
        end
    end
    filteredCrossings = allCrossings(keepCrossings);
else
    filteredCrossings = allCrossings;
end

% Classify into upward and downward crossings
if ~isempty(filteredCrossings)
    crossingTypes = zerocross(filteredCrossings - 1);
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

% Initialize output arrays
peaks = nan(size(downcross));
peakIndices = peaks;
valleys = peaks;
valleyIndices = peaks;

if downcross(1) < upcross(1)
    % Case 1: Downcross first

    % Find peaks
    for kk=2:length(downcross)
        indexes = upcross(kk-1):downcross(kk);
        [peaks(kk), peakIndices(kk)] = max(resp(indexes));
        peakIndices(kk) = peakIndices(kk) + upcross(kk-1) - 1;
    end

    % Find valleys
    for kk=1:length(upcross)
        indexes = downcross(kk):upcross(kk);
        [valleys(kk), valleyIndices(kk)] = min(resp(indexes));
        valleyIndices(kk) = valleyIndices(kk) + downcross(kk) - 1;
    end
else
    % Case 2: Upcross first

    % Find peaks
    for kk=1:length(downcross)
        indexes = upcross(kk):downcross(kk);
        [peaks(kk), peakIndices(kk)] = max(resp(indexes));
        peakIndices(kk) = peakIndices(kk) + upcross(kk) - 1;
    end

    % Find valleys
    for kk=2:length(upcross)
        indexes = downcross(kk-1):upcross(kk);
        [valleys(kk), valleyIndices(kk)] = min(resp(indexes));
        valleyIndices(kk) = valleyIndices(kk) + downcross(kk-1) - 1;
    end
end

% Remove NaNs from output
peaks = peaks(~isnan(peakIndices));
peakIndices = peakIndices(~isnan(peakIndices));
valleys = valleys(~isnan(valleyIndices));
valleyIndices = valleyIndices(~isnan(valleyIndices));

end


%% INTERPOLATEENVELOPE
function envelope = interpolateEnvelope(indices, values, resp, startInvalid, endInvalid)
% INTERPOLATEENVELOPE Interpolate a single envelope and handle invalid regions.
%
%   ENVELOPE = INTERPOLATEENVELOPE(INDICES, VALUES, RESP, STARTINVALID, ENDINVALID)
%   interpolates a single envelope from the given indices and values, removes invalid
%   regions at the beginning and end, and propagates NaNs from the input signal.

% Interpolate envelope
envelope = interp1(indices, values, 1:length(resp), 'pchip');

% Remove invalid regions
envelope(1:startInvalid) = nan;
envelope(endInvalid:end) = nan;

% Propagate NaNs from input signal
envelope(isnan(resp)) = nan;

end


%% CALCULATETIDALVOLUME
function tdvol = calculateTidalVolume(peaks, peakIndices, valleys, valleyIndices, resp, upper, lower)
% CALCULATETIDALVOLUME Calculate tidal volume from peaks and valleys.
%
%   TDVOL = CALCULATETIDALVOLUME(PEAKS, PEAKINDICES, VALLEYS, VALLEYINDICES, RESP, UPPER, LOWER)
%   calculates the tidal volume signal by interpolating amplitude differences between
%   peaks and valleys, and handles NaN propagation.

% Ensure we have matching pairs by taking minimum length
minLength = min(length(peaks), length(valleys));
if minLength < 2
    tdvol = nan(size(resp));
    return;
end

% Determine the correct pairing based on temporal sequence
if peakIndices(1) < valleyIndices(1)
    % Signal starts with peak: pair each peak with corresponding valley
    % peak[i] -> valley[i]
    amplitudeAux = peaks(1:minLength) - valleys(1:minLength);
    tAux = (peakIndices(1:minLength) + valleyIndices(1:minLength))/2;
else
    % Signal starts with valley: pair each valley with next peak
    % valley[i] -> peak[i+1], so we need to offset the arrays
    if minLength > 2
        amplitudeAux = peaks(1:minLength-1) - valleys(2:minLength);
        tAux = (peakIndices(1:minLength-1) + valleyIndices(2:minLength))/2;
    else
        % Not enough data for proper pairing
        tdvol = nan(size(resp));
        return;
    end
end

% Check if we have valid data for interpolation
if isempty(tAux) || isempty(amplitudeAux)
    tdvol = nan(size(resp));
    return;
end

tdvol = interp1(tAux, amplitudeAux, 1:length(resp),'pchip');
tdvol(isnan(upper-lower)) = nan;
tdvol(isnan(resp)) = nan;

end