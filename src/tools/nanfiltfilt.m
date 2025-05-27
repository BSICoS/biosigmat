function y = nanfiltfilt(b, a, x, maxgap)
% NANFILTFILT Implements filtfilt function with support for NaN values
%
% This function applies zero-phase digital filtering to a signal that contains
% NaN values. It uses linear interpolation to temporarily fill NaN values,
% then filters the signal and restores NaN values for segments longer than
% the specified maximum gap.
%
% Inputs:
%   b          - Numerator coefficients of the filter
%   a          - Denominator coefficients of the filter
%   x          - Input signal with possible NaN values
%   maxgap     - Optional. Maximum gap size to interpolate. If not specified,
%                all NaN segments will be preserved regardless of their size.
%
% Outputs:
%   y          - Filtered signal with NaN values preserved where appropriate

%% Parse Inputs

% Check inputs
if nargin < 3
    error('Not enough input arguments.');
end

if nargin < 4 || isempty(maxgap)
    warning('maxgap not specified. All NaN segments will be preserved regardless of size.');
    maxgap = 0;
end

%% Algorithm

% Find NaNs
idxNan = isnan(x);

if all(idxNan(:))
    y = x;
    return
end

% Fill missing values
signalFilled = fillmissing(x, 'linear');

% Apply filter
signalFiltered = filtfilt(b, a, signalFilled);

% Initialize output with filtered signal
y = signalFiltered;

% Restore NaN segments per column for sequences longer than maxgap
for col = 1:size(x,2)
    idxNanCol = idxNan(:,col);
    if all(idxNanCol)
        continue; % entire column is NaN, already handled
    end
    seqs = findsequences(double(idxNanCol));
    seqs(seqs(:,1) == 0, :) = [];
    seqs(seqs(:,4) <= maxgap, :) = [];
    for s = 1:size(seqs,1)
        y(seqs(s,2):seqs(s,3),col) = NaN;
    end
end