function y = nanfiltfilt(bb, aa, x, maxgap)
% NANFILTFILT Implements filtfilt function with support for NaN values
%
% This function applies zero-phase digital filtering to a signal that contains
% NaN values. It uses linear interpolation to temporarily fill NaN values,
% then filters the signal and restores NaN values for segments longer than
% the specified maximum gap.
%
% Inputs:
%   bb         - Numerator coefficients of the filter
%   aa         - Denominator coefficients of the filter
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

if all(idxNan)
    y = x;
    return
end

% Fill missing values
signalFilled = fillmissing(x, 'linear');

% Apply filter
signalFiltered = filtfilt(bb, aa, signalFilled);

% Initialize output with filtered signal
y = signalFiltered;

% Find sequences of NaN values
seqs = findsequences(double(idxNan));
seqs(seqs(:,1) == 0, :) = [];
seqs(seqs(:,4) <= maxgap, :) = [];

% Restore NaN values for sequences longer than maxgap
for idx = 1:size(seqs, 1)
    y(seqs(idx, 2):seqs(idx, 3)) = NaN;
end