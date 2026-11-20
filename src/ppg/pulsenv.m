function [lowerEnvelope, upperEnvelope] = pulsenv(ppg, fs, varargin)
% PULSENV Estimate lower and upper PPG envelopes using pulse fiducials.
%
%   LOWERENVELOPE = PULSENV(PPG, FS, tD) delineates the basal and apex
%   points around detections tD in seconds. It interpolates the sampled
%   basal amplitudes on the PPG grid. FS is the sampling frequency in Hz.
%
%   [LOWERENVELOPE, UPPERENVELOPE] = PULSENV(PPG, FS, tD) also
%   interpolates the apex amplitudes. All fiducial times are in seconds
%   from the first PPG sample.
%
%   [...] = PULSENV(PPG, FS, 'tA', tA, 'tB', tB) uses precomputed apex
%   and basal times. NaNs denote missing anchors. Each output is a column
%   with one value per PPG sample, and NaN outside supported segments.
%
%   [...] = PULSENV(..., 'Name', Value) specifies additional parameters:
%     'WindowA' - Apex search duration after tD (default: 0.25 s).
%     'WindowB' - Basal search duration before tD (default: 0.15 s).
%     'MaxGap'  - Split before interpolation when successive valid times
%                 of the same fiducial differ by at least this duration
%                 in seconds (default: Inf). PPG gaps can be bridged.
%
%   Example:
%     tD = pulsedet(dppg, fs);
%     [lower, upper] = pulsenv(ppg, fs, tD, 'MaxGap', 2);
%
%   See also PULSEDET, PULSEDEL, INTERP1

nargoutchk(0, 2);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'pulsenv';
timeVector = @(x) isnumeric(x) && isreal(x) && (isvector(x) || isempty(x));
positiveScalar = @(x) isnumeric(x) && isreal(x) && isscalar(x) && x > 0;
addRequired(parser, 'ppg', @(x) timeVector(x) && ~isempty(x) && ~any(isinf(x)));
addRequired(parser, 'fs', @(x) positiveScalar(x) && isfinite(x));
addOptional(parser, 'tD', [], timeVector);
addParameter(parser, 'tA', [], timeVector);
addParameter(parser, 'tB', [], timeVector);
addParameter(parser, 'WindowA', 0.25, @(x) positiveScalar(x) && isfinite(x));
addParameter(parser, 'WindowB', 0.15, @(x) positiveScalar(x) && isfinite(x));
addParameter(parser, 'MaxGap', Inf, positiveScalar);
parse(parser, ppg, fs, varargin{:});

% Normalize signal shape and determine the last sample time.
ppg = double(ppg(:));
fs = double(fs);
lastTime = (numel(ppg)-1)/fs;

provided = ~ismember({'tD','tA','tB'}, parser.UsingDefaults);
if isequal(provided, [true false false])
    tD = validateTimes(parser.Results.tD, lastTime);
    if all(isnan(tD))
        lowerEnvelope = NaN(size(ppg));
        upperEnvelope = NaN(size(ppg));
        warning('pulsenv:emptyDetections', 'No pulse detections provided.');
        return;
    end
    [tA, tB] = pulsedel(ppg, fs, tD, 'WindowA', parser.Results.WindowA, ...
        'WindowB', parser.Results.WindowB);
elseif isequal(provided, [false true true])
    tA = validateTimes(parser.Results.tA, lastTime);
    tB = validateTimes(parser.Results.tB, lastTime);
else
    error('pulsenv:InvalidFiducials', 'Supply tD or both tA and tB.');
end

% Lower and upper envelopes have independent interpolation support.
clockTolerance = 4*eps(lastTime);
lowerEnvelope = interpolateEnvelope(ppg, tB, fs, parser.Results.MaxGap, clockTolerance);
if all(isnan(lowerEnvelope))
    warning('pulsenv:insufficientLowerAnchors', 'Not enough connected lower anchors to interpolate.');
end
if nargout < 2
    return;
end
upperEnvelope = interpolateEnvelope(ppg, tA, fs, parser.Results.MaxGap, clockTolerance);
if all(isnan(upperEnvelope))
    warning('pulsenv:insufficientUpperAnchors', 'Not enough connected upper anchors to interpolate.');
end
end


%% VALIDATETIMES
function times = validateTimes(values, lastTime)
% VALIDATETIMES Validate fiducial times against the recording interval.
%
%   TIMES = VALIDATETIMES(VALUES, LASTTIME) returns a column of times in
%   [0, LASTTIME], retaining NaNs for missing fiducials.

times = double(values(:));
if any(times < 0 | times > lastTime)
    error('pulsenv:TimeOutOfBounds', 'Fiducial times must lie within the signal.');
end
end


%% INTERPOLATEENVELOPE
function envelope = interpolateEnvelope(ppg, times, fs, maxGap, clockTolerance)
% INTERPOLATEENVELOPE Interpolate one curve between sampled PPG anchors.
%
%   ENVELOPE = INTERPOLATEENVELOPE(PPG, TIMES, FS, MAXGAP, CLOCKTOLERANCE) fits a separate
%   PCHIP to each group of at least two anchors separated by less than MAXGAP.

envelope = NaN(size(ppg));
times = sort(times(~isnan(times)));
[anchors, first] = unique(1 + round(times*fs), 'first');
valid = isfinite(ppg(anchors));
anchors = anchors(valid);
times = times(first(valid));
boundaries = [1; find(diff(times) + clockTolerance >= maxGap)+1; numel(anchors)+1];
for k = 1:numel(boundaries)-1
    group = anchors(boundaries(k):boundaries(k+1)-1);
    if numel(group) >= 2
        samples = group(1):group(end);
        envelope(samples) = interp1(group, ppg(group), samples, 'pchip');
    end
end
end
