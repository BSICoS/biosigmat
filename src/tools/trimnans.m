function trimmedSignal = trimnans(signal)
% TRIMNANS Trim NaN values from the beginning and end of a signal.
%
%   TRIMMEDSIGNAL = TRIMNANS(SIGNAL) removes NaN values from the beginning
%   and end of the input signal SIGNAL, returning the trimmed signal
%   TRIMMEDSIGNAL. The function preserves any NaN values that occur in the
%   middle of the signal between valid data points. If all values in the
%   signal are NaN, an empty array is returned.
%
%   This function is useful for cleaning up signals that may have NaN
%   padding at the edges due to filtering operations, data acquisition
%   issues, or preprocessing steps. It ensures that the signal starts and
%   ends with valid numeric values while maintaining the original structure
%   of any internal NaN values.
%
%   Example:
%     % Create a signal with NaN padding at both ends
%     signal = [NaN; NaN; 1; 2; NaN; 3; 4; NaN; NaN];
%     trimmed = trimnans(signal);
%     % Result: trimmed = [1; 2; NaN; 3; 4]
%
%   See also ISNAN, FIND, RMMISSING


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
