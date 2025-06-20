function varargout = sloperange(decg, tk, fs)
% SLOPERANGE Compute ECG-derived respiration (EDR) using slope range method
%
%   sloperange(DECG, TK, FS) Computes ECG-derived respiration signal using
%              the slope range method. This method analyzes the derivative
%              of the ECG signal around R-wave peaks to extract respiratory
%              information.
%
%   EDR = sloperange(DECG, TK, FS)
%       EDR is a column vector containing the respiratory signal derived
%       from the ECG slope range analysis.
%
%   [EDR, UPSLOPES, DOWNSLOPES, UPMAXPOS, DOWNMINPOS] = sloperange(...)
%       Returns additional outputs:
%       - UPSLOPES: Matrix containing upslope values around R-waves
%       - DOWNSLOPES: Matrix containing downslope values around R-waves
%       - UPMAXPOS: Positions of maximum upslope values
%       - DOWNMINPOS: Positions of minimum downslope values
%
% Inputs:
%   DECG - Single-lead ECG signal derivative (numeric vector)
%   TK   - Beat occurrence time series for R-waves in seconds (numeric vector)
%   FS   - Sampling frequency in Hz (numeric scalar)


% Input argument validation
narginchk(3, 3);
nargoutchk(0, 5);

% Input validation
if isempty(decg) || isscalar(decg)
    varargout{1} = [];
    return
elseif ischar(decg)
    error('Input must be a numeric array');
elseif islogical(decg)
    decg = double(decg);
end
if fs <= 0 || ~isscalar(fs)
    error('Sampling frequency FS must be a positive scalar');
end

decg = decg(:);
nk = round(tk * fs) + 1;
numBeats = length(nk);

if any(nk < 1) || any(nk > length(decg))
    error('R-wave indices must be within the bounds of the ECG signal');
end

% Define window durations around R-wave for slope analysis
shortWindow = round(fs * 0.015);
longWindow = round(fs * 0.05);

% Define relative sample intervals for upslope and downslope analysis
upslopeWindow = -longWindow+1:shortWindow;
downslopeWindow = -shortWindow:longWindow-1;
upslopeLength = length(upslopeWindow);

% Calculate absolute indices for upslope and downslope intervals
upslopeIndices = repmat(nk(:).', [upslopeLength, 1]) + ...
    repmat(upslopeWindow(:), [1, numBeats]);
downslopeIndices = repmat(nk(:).', [upslopeLength, 1]) + ...
    repmat(downslopeWindow(:), [1, numBeats]);

% Ensure windows are within bounds of the ECG signal and track removed beats
firstBeatRemoved = false;
lastBeatRemoved = false;

if nk(1) + upslopeWindow(1) < 1
    upslopeIndices(:, 1) = [];
    downslopeIndices(:, 1) = [];
    nk(1) = [];
    firstBeatRemoved = true;
end
if nk(end) + downslopeWindow(end) > length(decg)
    upslopeIndices(:, end) = [];
    downslopeIndices(:, end) = [];
    nk(end) = [];
    lastBeatRemoved = true;
end

% Find maximum upslope and minimum downslope values
[upslopeMax, upslopeMaxPosition] = max(decg(upslopeIndices));
[downslopeMin, downslopeMinPosition] = min(decg(downslopeIndices));

upslopeMaxPosition = upslopeMaxPosition(:) + upslopeWindow(1) + nk(:) - 1;
downslopeMinPosition = downslopeMinPosition(:) + downslopeWindow(1) + nk(:) - 1;

% Initialize slope arrays with NaN values
upslopes = nan(size(decg));
downslopes = nan(size(decg));

% Populate slope arrays with actual values
upslopes(upslopeIndices) = decg(upslopeIndices);
downslopes(downslopeIndices) = decg(downslopeIndices);

% Compute EDR signal as difference between maximum upslope and minimum downslope
edr = upslopeMax(:) - downslopeMin(:);

% Complete EDR signal to match the length of tk by adding NaN for removed beats
if firstBeatRemoved
    edr = [nan; edr];
end
if lastBeatRemoved
    edr = [edr; nan];
end

% Format output based on requested number of output arguments
varargout = {edr, upslopes, downslopes, upslopeMaxPosition, downslopeMinPosition};

end