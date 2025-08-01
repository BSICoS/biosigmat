function varargout = sloperange(decg, tk, fs)
% SLOPERANGE Compute ECG-derived respiration (EDR) using slope range method.
%
%   EDR = SLOPERANGE(DECG, TK, FS) computes ECG-derived respiration (EDR) signal using
%   the slope range method. This method analyzes the derivative of the ECG signal
%   (DECG) around R-wave peaks (TK) to extract respiratory information.
%   EDR is a column vector with the same length as TK.
%
%   [EDR, UPSLOPES, DOWNSLOPES, UPMAXPOS, DOWNMINPOS] = SLOPERANGE(...) returns
%   additional outputs:
%     UPSLOPES   - Matrix containing upslope values around R-waves
%     DOWNSLOPES - Matrix containing downslope values around R-waves
%     UPMAXPOS   - Positions of maximum upslope values
%     DOWNMINPOS - Positions of minimum downslope values
%
%   Example:
%     % Derive respiratory signal from ECG using slope range method
%     load('ecg_data.mat'); % Load ECG signal and R-wave positions
%     decg = diff(ecg); % Calculate ECG derivative
%     edr = sloperange(decg, tk, fs);
%
%     % Plot results
%     figure;
%     plot(tk, edr);
%     title('ECG-derived Respiration');
%     xlabel('Time (s)');
%     ylabel('EDR Amplitude');
%
%   See also PANTOMPKINS, BASELINEREMOVE
%
%   Status: Beta

% Argument validation
narginchk(3, 3);
nargoutchk(0, 5);

% Parse input arguments
parser = inputParser;
parser.FunctionName = 'sloperange';
addRequired(parser, 'decg', @(x) isnumeric(x) && isvector(x) && ~isscalar(x));
addRequired(parser, 'tk', @(x) isnumeric(x) && isvector(x));
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);

parse(parser, decg, tk, fs);

decg = parser.Results.decg;
tk = parser.Results.tk;
fs = parser.Results.fs;

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
    upslopeMaxPosition = [nan; upslopeMaxPosition];
    downslopeMinPosition = [nan; downslopeMinPosition];
end
if lastBeatRemoved
    edr = [edr; nan];
    upslopeMaxPosition = [upslopeMaxPosition; nan];
    downslopeMinPosition = [downslopeMinPosition; nan];
end

% Format output based on requested number of output arguments
varargout = {edr, upslopes, downslopes, upslopeMaxPosition, downslopeMinPosition};

end