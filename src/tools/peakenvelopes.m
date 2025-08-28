function [upper, lower, amplitude] = peakenvelopes(signal, varargin)
% PEAKENVELOPES Extracts upper and lower peak envelopes from a signal.
%
%   [UPPER, LOWER] = PEAKENVELOPES(SIGNAL) extracts the upper and lower
%   peak envelopes from the input signal. SIGNAL is the input signal (numeric
%   vector). UPPER is the upper envelope connecting the peaks and LOWER is the
%   lower envelope connecting the valleys.
%
%   [UPPER, LOWER] = PEAKENVELOPES(SIGNAL, MINDIST) and
%   [UPPER, LOWER, AMPLITUDE] = PEAKENVELOPES(SIGNAL, MINDIST) specify
%   the minimum distance between consecutive peaks in samples. MINDIST is a
%   non-negative scalar with default value 0.
%
%   [UPPER, LOWER, AMPLITUDE] = PEAKENVELOPES(...) also returns
%   AMPLITUDE, the amplitude envelope representing the difference between
%   peaks and valleys.

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
parser.FunctionName = 'peakenvelopes';
addRequired(parser, 'signal', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addOptional(parser, 'mindist', 0, @(x) isnumeric(x) && isscalar(x) && x >= 0);

parse(parser, signal, varargin{:});

signal = parser.Results.signal;
mindist = parser.Results.mindist;

signal = signal(:);

% Find zero crossings
zerocross = diff(sign(signal));

% Find downcross and upcross indices
downcross = find(zerocross==-2)+1;
upcross = find(zerocross==2)+1;

% Remove close peaks and valleys
downcross(diff(upcross) < mindist) = [];
upcross(diff(upcross) < mindist) = [];

if downcross(1) < upcross(1)
    downcross(1) = [];
end

if downcross(end) < upcross(end)
    upcross(end) = [];
end

% Initialize output arrays
peaks = nan(size(downcross));
peakIndices = peaks;
valleys = peaks;
valleyIndices = peaks;

if downcross(1)<upcross(1)
    % Case 1: Downcross first

    % Find peaks
    for kk=2:length(downcross)
        indexes = upcross(kk-1):downcross(kk);
        [peaks(kk), peakIndices(kk)] = max(signal(indexes));
        peakIndices(kk) = peakIndices(kk) + upcross(kk-1) - 1;
    end

    % Find valleys
    for kk=1:length(upcross)
        indexes = downcross(kk):upcross(kk);
        [valleys(kk), valleyIndices(kk)] = min(signal(indexes));
        valleyIndices(kk) = valleyIndices(kk) + downcross(kk) - 1;
    end
else
    % Case 2: Upcross first

    % Find peaks
    for kk=1:length(downcross)
        indexes = upcross(kk):downcross(kk);
        [peaks(kk), peakIndices(kk)] = max(signal(indexes));
        peakIndices(kk) = peakIndices(kk) + upcross(kk) - 1;
    end

    % Find valleys
    for kk=2:length(upcross)
        indexes = downcross(kk-1):upcross(kk);
        [valleys(kk), valleyIndices(kk)] = min(signal(indexes));
        valleyIndices(kk) = valleyIndices(kk) + downcross(kk-1) - 1;
    end
end

% Remove NaNs from output
peaks = peaks(~isnan(peakIndices));
peakIndices = peakIndices(~isnan(peakIndices));
valleys = valleys(~isnan(valleyIndices));
valleyIndices = valleyIndices(~isnan(valleyIndices));

% Interpolate envelopes
upper = interp1(peakIndices, peaks, 1:length(signal),'pchip');
lower = interp1(valleyIndices, valleys, 1:length(signal),'pchip');

% Remove invalid regions
upper(1:upcross(1)) = nan;
upper(downcross(end):end) = nan;
lower(1:downcross(1)) = nan;
lower(upcross(end):end) = nan;

% Propagate NaNs from input signal to envelopes
upper(isnan(signal)) = nan;
lower(isnan(signal)) = nan;

% Calculate amplitude envelope only if requested
if nargout >= 3
    valleys = valleys(valleyIndices>peakIndices(1));
    valleyIndices = valleyIndices(valleyIndices>peakIndices(1));

    amplitudeAux = peaks(1:length(valleys)) - valleys;
    tAux = (peakIndices(1:length(valleys))+valleyIndices)/2;

    amplitude = interp1(tAux, amplitudeAux, 1:length(signal),'pchip');
    amplitude(isnan(upper-lower)) = nan;
    amplitude(isnan(signal)) = nan;
end

end