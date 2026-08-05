function [outputSignal, m] = ipfm(tn, varargin)
% IPFM Estimate instantaneous heart rate using the integral pulse frequency modulation model.
%
%   SP = IPFM(TN) estimates the spline representation of instantaneous heart
%   rate from the normal beat occurrence time series TN using the integral
%   pulse frequency modulation model. TN is a vector of normal beat occurrence
%   times in seconds. SP is a spline representation that can be evaluated with
%   SPVAL.
%
%   IHR = IPFM(TN, FS) evaluates the IPFM spline at the uniformly sampled time
%   vector TM = TN(1):1/FS:TN(end), where FS is the desired sampling frequency
%   in hertz. FS must be positive. IHR is the instantaneous heart rate in
%   hertz.
%
%   SP = IPFM(TN, 'SplineOrder', SPLINEORDER) uses the specified spline order
%   for the spline interpolation stage. The default spline order is 14.
%
%   IHR = IPFM(TN, FS, 'SplineOrder', SPLINEORDER) evaluates the IPFM spline
%   using the specified spline order.
%
%   [IHR, M] = IPFM(TN, FS, ...) also returns M, the modulating signal
%   obtained by removing the low-frequency trend of IHR and normalizing the
%   residual by that trend. This output requires FS greater than 0.06 Hz and
%   at least 13 samples on the output grid.
%
%   Example:
%     % Estimate instantaneous heart rate from beat occurrence times
%     tkData = readtable('../../fixtures/ecg/medicom_mtd_r_wave_timing.csv');
%     tn = tkData.r_wave_times(1:100);
%     fs = 4;
%
%     % Evaluate the IPFM spline and compute the modulating signal
%     [ihr, m] = ipfm(tn, fs);
%     tm = (tn(1):1/fs:tn(end))';
%
%     % Plot results
%     figure;
%     subplot(2,1,1);
%     plot(tm, ihr);
%     ylabel('Heart rate (Hz)');
%     title('IPFM-Based Instantaneous Heart Rate');
%
%     subplot(2,1,2);
%     plot(tm, m);
%     xlabel('Time (s)');
%     ylabel('Modulating signal');
%     title('IPFM Modulating Signal');
%
%   See also SPAPI, SPVAL, FNDER


% Check number of input and output arguments
narginchk(1, 4);
nargoutchk(0, 2);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'ipfm';
addRequired(parser, 'tn', @(x) isnumeric(x) && isvector(x) && ~isempty(x) && all(isfinite(x)));
addOptional(parser, 'fs', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x) && x > 0));
addParameter(parser, 'SplineOrder', 14, @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x == floor(x) && x > 1);

parse(parser, tn, varargin{:});

tn = parser.Results.tn(:);
fs = parser.Results.fs;
splineOrder = parser.Results.SplineOrder;

if numel(tn) < 2
    error('ipfm:NotEnoughBeats', 'tn must contain at least two beat occurrence times.');
end

if any(diff(tn) <= 0)
    error('ipfm:NonIncreasingTimes', 'tn must be strictly increasing.');
end

if splineOrder > numel(tn) + 20
    error('biosigmat:ipfm:SplineOrder', ...
        'SplineOrder must not exceed the number of extended event sites.');
end

if ~isempty(fs) && nargout > 1 && fs <= 0.06
    error('biosigmat:ipfm:SamplingFrequency', ...
        'fs must be greater than 0.06 Hz when requesting the modulating signal.');
end

% Extend the beat occurrence series at both edges to stabilize the spline.
edgeCount = min(9, numel(tn));
dtStart = median(diff(tn(1:edgeCount)));
dtEnd = median(diff(tn(end-edgeCount+1:end)));
extensionLength = 10;
extendedTn = [tn(1) - (extensionLength:-1:1)' * dtStart; tn; tn(end) + (1:extensionLength)' * dtEnd];
beatIndex = (1:numel(extendedTn))';

% Build the spline of the integrated pulse frequency modulation model.
outputSignal = fnder(spapi(splineOrder, extendedTn, beatIndex));

if isempty(fs)
    if nargout > 1
        error('ipfm:FsRequiredForModulatingSignal', ...
            'fs must be provided when requesting the modulating signal.');
    end
    return;
end

tm = (tn(1):1/fs:tn(end))';
outputSignal = spval(outputSignal, tm);
outputSignal = outputSignal(:);

if any(~isfinite(outputSignal)) || any(outputSignal <= 0)
    error('biosigmat:ipfm:InvalidNumericalResult', ...
        'The sampled instantaneous heart rate must be finite and positive.');
end

if nargout > 1
    if numel(outputSignal) <= 12
        error('biosigmat:ipfm:InsufficientData', ...
            'At least 13 sampled values are required for the modulating signal.');
    end
    [bLow, aLow] = butter(4, 0.03 * 2 / fs, 'low');
    lowFrequencyComponent = filtfilt(bLow, aLow, outputSignal);
    if any(~isfinite(lowFrequencyComponent)) || ...
            any(lowFrequencyComponent <= 0)
        error('biosigmat:ipfm:InvalidNumericalResult', ...
            'The mean instantaneous heart rate must be finite and positive.');
    end
    m = (outputSignal - lowFrequencyComponent) ./ lowFrequencyComponent;
    if any(~isfinite(m))
        error('biosigmat:ipfm:InvalidNumericalResult', ...
            'The modulating signal must be finite.');
    end
end

end
