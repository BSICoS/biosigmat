function trimmedSignal = trimnans(signal)
% TRIMNANS Trim NaN values from the beginning and end of a signal.
%
% TRIMEDSIGNAL = TRIMNANS(SIGNAL) This function removes NaN values from the beginning and end of a signal,
% returning the trimmed signal.
%
% Inputs:
%   signal - Input signal (numeric vector)
%
% Outputs:
%   trimmedSignal - Signal with NaN values trimmed from beginning and end
%                   Empty if all values are NaN
%
% EXAMPLE:
%   % Trim NaN values from a signal
%   signal = [NaN; NaN; 1; 2; NaN; 3; NaN; NaN];
%   trimmed = trimnans(signal);
%   % Result: trimmed = [1; 2; NaN; 3]
%
% STATUS: Beta

% Check number of input and output arguments
narginchk(1, 1);
nargoutchk(0, 1);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'trimnans';
addRequired(parser, 'signal', @(x) isnumeric(x) && isvector(x));
parse(parser, signal);
signal = parser.Results.signal;

signal = signal(:);

% Find first and last valid (non-NaN) indices
firstValidIndex = find(~isnan(signal), 1, 'first');
lastValidIndex = find(~isnan(signal), 1, 'last');

% Trim the signal
if isempty(firstValidIndex)
    % All values are NaN - return empty signal
    trimmedSignal = [];
else
    % Trim NaN values from beginning and end
    trimmedSignal = signal(firstValidIndex:lastValidIndex);
end

end
