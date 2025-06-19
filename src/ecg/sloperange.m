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
%

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

% Ensure decg is a column vector
decg = decg(:);

% Convert R-wave times from seconds to sample indices
nk = round(tk * fs) + 1;

% Number of R-wave peaks
numBeats = length(nk);

% Define window durations around R-wave for slope analysis
shortWindow = round(fs * 0.015);  % 15 ms window
longWindow = round(fs * 0.05);    % 50 ms window

% Define relative sample intervals for upslope and downslope analysis
upslopeWindow = -longWindow+1:shortWindow;
downslopeWindow = -shortWindow:longWindow-1;
upslopeLength = length(upslopeWindow);

% Calculate absolute indices for upslope and downslope intervals
upslopeIndices = repmat(nk(:).', [upslopeLength, 1]) + ...
    repmat(upslopeWindow(:), [1, numBeats]);
downslopeIndices = repmat(nk(:).', [upslopeLength, 1]) + ...
    repmat(downslopeWindow(:), [1, numBeats]);

% Find maximum upslope and minimum downslope values
[upslopeMax, upslopeMaxPosition] = max(decg(upslopeIndices));
[downslopeMin, downslopeMinPosition] = min(decg(downslopeIndices));

% Initialize slope arrays with NaN values
upslopes = nan(size(decg));
downslopes = nan(size(decg));

% Populate slope arrays with actual values
upslopes(upslopeIndices) = decg(upslopeIndices);
downslopes(downslopeIndices) = decg(downslopeIndices);

% Compute EDR signal as difference between maximum upslope and minimum downslope
edr = upslopeMax(:) - downslopeMin(:);

% Format output based on requested number of output arguments
if nargout < 2
    varargout = {edr};
else
    varargout = {edr, upslopes, downslopes, upslopeMaxPosition, downslopeMinPosition};
end

end