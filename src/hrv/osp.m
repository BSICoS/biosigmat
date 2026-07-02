function [mResp, mUnrelated, delay] = osp(m, resp, respPxx, f, fs, varargin)
% OSP Decompose the HRV modulating signal into respiratory and unrelated components.
%
%   [MRESP, MUNRELATED, DELAY] = OSP(M, RESP, RESPPXX, F, FS) decomposes the
%   HRV modulating signal M into a component linearly related to the respiration
%   signal RESP and a residual component containing the remaining dynamics.
%   RESP must be sampled at the same sampling frequency FS and aligned in time
%   with M. RESPPXX is the respiratory power spectral density evaluated on the
%   frequency vector F. MRESP and MUNRELATED correspond to the delayed segment
%   M(DELAY:END), where DELAY is the model order estimated from the dominant
%   respiratory frequency. If M or RESP is empty, MRESP and MUNRELATED are
%   returned as empty vectors. If either input signal contains NaN values,
%   MRESP and MUNRELATED are also returned as empty vectors.
%
%   [MRESP, MUNRELATED, DELAY] = OSP(..., 'MinRespFrequency', MINRESPFREQUENCY)
%   enforces a lower bound in hertz for the dominant respiratory frequency used
%   to compute the model order. The default value is 0.1 Hz.
%
%   Example:
%     % Load fixture-based respiration and beat occurrence times
%     tkData = readtable('../../fixtures/ecg/medicom_mtd_r_wave_timing.csv');
%     respData = readtable('../../fixtures/ecg/medicom_mtd_ecg_respiration.csv');
%     fs = 4;
%
%     % Compute the HRV modulating signal and align respiration to its grid
%     tn = tkData.r_wave_times(1:100);
%     [~, m] = ipfm(tn, fs);
%     tm = (tn(1):1/fs:tn(end))';
%     resp = interp1(respData.time, detrend(respData.respiration), tm, 'pchip');
%
%     % Estimate the respiratory spectrum and decompose the modulating signal
%     windowLength = min(256, length(resp));
%     [respPxx, f] = pwelch(resp, hamming(windowLength), floor(windowLength / 2), [], fs);
%     [mResp, mUnrelated, delay] = osp(m, resp, respPxx, f, fs);
%
%   See also IPFM, PWELCH, FINDPEAKS, HANKEL


% Check number of input and output arguments
narginchk(5, 7);
nargoutchk(0, 3);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'osp';
addRequired(parser, 'm', @(x) isnumeric(x) && (isempty(x) || isvector(x)));
addRequired(parser, 'resp', @(x) isnumeric(x) && (isempty(x) || isvector(x)));
addRequired(parser, 'respPxx', @(x) isnumeric(x) && isvector(x) && ~isempty(x) && all(isfinite(x)) && all(x >= 0));
addRequired(parser, 'f', @(x) isnumeric(x) && isvector(x) && ~isempty(x) && all(isfinite(x)));
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0);
addParameter(parser, 'MinRespFrequency', 0.1, @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0);

parse(parser, m, resp, respPxx, f, fs, varargin{:});

mInput = parser.Results.m;
respInput = parser.Results.resp;
m = mInput(:);
resp = respInput(:);
respPxx = parser.Results.respPxx(:);
f = parser.Results.f(:);
fs = parser.Results.fs;
minRespFrequency = parser.Results.MinRespFrequency;

if isempty(mInput) || isempty(respInput)
    mResp = [];
    mUnrelated = [];
    delay = [];
    return;
end

if any(isnan(mInput)) || any(isnan(respInput))
    mResp = [];
    mUnrelated = [];
    delay = [];
    return;
end

if numel(resp) ~= numel(m)
    error('osp:LengthMismatch', ...
        'resp and m must have the same number of samples.');
end

if numel(respPxx) ~= numel(f)
    error('osp:SpectrumLengthMismatch', ...
        'respPxx and f must have the same number of samples.');
end

if any(diff(f) <= 0)
    error('osp:NonIncreasingFrequencyVector', ...
        'f must be strictly increasing.');
end

% Estimate the 90% occupied respiratory bandwidth to identify candidate peaks.
[~, fLow, fHigh] = obw(respPxx, f, [], 90);
bandMask = f >= fLow & f <= fHigh;

if ~any(bandMask)
    bandMask = true(size(f));
end

bandSpectrum = respPxx(bandMask);
bandFrequencies = f(bandMask);

if numel(bandSpectrum) < 3
    [~, peakIndex] = max(bandSpectrum);
    dominantFrequency = bandFrequencies(peakIndex);
else
    [peakValues, peakFrequencies] = findpeaks(bandSpectrum, bandFrequencies);

    if isempty(peakValues)
        [~, peakIndex] = max(bandSpectrum);
        dominantFrequency = bandFrequencies(peakIndex);
    elseif numel(peakValues) <= 3
        [~, peakIndex] = max(peakValues);
        dominantFrequency = peakFrequencies(peakIndex);
    else
        dominantFrequency = min(peakFrequencies);
    end
end

dominantFrequency = max(dominantFrequency, minRespFrequency);
delay = max(round(2 * fs / dominantFrequency), 1);

if numel(resp) < delay || numel(m) < delay
    mResp = nan;
    mUnrelated = nan;
    return;
end

% Build the respiratory subspace and project the delayed modulating signal.
v = hankel(resp(1:delay), resp(delay:end));
v = v';
projectionMatrix = v * pinv(v' * v) * v';
delayedM = m(delay:end);
mResp = projectionMatrix * delayedM;
mUnrelated = delayedM - mResp;

end