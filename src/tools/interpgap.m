function interpolatedSignal = interpgap(signal, maxgap, varargin)
% INTERPGAP Interpolate small NaN gaps in a signal
%
% This function interpolates NaN gaps in a signal that are smaller than or
% equal to a specified maximum gap length. Gaps larger than maxgap are left
% unchanged.
%
% Inputs:
%   signal - Input signal (numeric vector)
%   maxgap - Maximum gap length in samples to interpolate (scalar)
%   method - (optional) Interpolation method: 'linear', 'nearest', 'cubic',
%            'spline', or 'pchip' (default: 'linear')
%
% Outputs:
%   interpolatedSignal - Signal with small gaps interpolated
%
% Example:
%   % Create a signal with small gaps
%   signal = [1, 2, NaN, 4, 5, NaN, NaN, 8, 9, 10]';
%   interpolated = interpgap(signal, 2);
%   interpolatedCubic = interpgap(signal, 2, 'cubic');
%   plot(1:length(signal), signal, 'ro', 1:length(interpolated), interpolated, 'b-');
%   legend('Original', 'Interpolated');

% Check number of input and output arguments
narginchk(2, 3);
nargoutchk(0, 1);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'interpgap';
validMethods = {'linear', 'nearest', 'cubic', 'spline', 'pchip'};
addRequired(parser, 'signal', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'maxgap', @(x) isnumeric(x) && isscalar(x) && x >= 0);
addOptional(parser, 'method', 'linear', @(x) any(validatestring(x, validMethods)));
parse(parser, signal, maxgap, varargin{:});
signal = parser.Results.signal;
maxgap = parser.Results.maxgap;
method = char(parser.Results.method);

% Ensure signal is a column vector
signal = signal(:);

% Initialize output
interpolatedSignal = signal;

% Find NaN indices
nanIndices = isnan(interpolatedSignal);

% Early return if no NaN values
if ~any(nanIndices)
    return;
end

% Find NaN sequences
nanSeqStarts = find(diff([0; nanIndices]) > 0);
nanSeqEnds = find(diff([nanIndices; 0]) < 0);

% Interpolate gaps that are ≤ maxgap
for i = 1:length(nanSeqStarts)
    gapLength = nanSeqEnds(i) - nanSeqStarts(i) + 1;
    if gapLength <= maxgap
        % Get indices for interpolation (including boundary points)
        startIdx = max(1, nanSeqStarts(i) - 1);
        endIdx = min(length(interpolatedSignal), nanSeqEnds(i) + 1);

        % Find valid data points around the gap
        validIndices = ~isnan(interpolatedSignal(startIdx:endIdx));
        if sum(validIndices) >= 2
            % Interpolate
            validData = interpolatedSignal(startIdx:endIdx);
            sampleIndices = 1:length(validData);
            interpolatedData = interp1(sampleIndices(validIndices), ...
                validData(validIndices), sampleIndices, method);
            interpolatedSignal(startIdx:endIdx) = interpolatedData;
        end
    end
end

end
