function [b, a, x, maxgap] = parseNanFiltering(functionName, b, a, x, maxgap)
% PARSENANFILTERING Common input parsing and validation for NaN filtering functions
%
% This function handles the common input parsing and validation logic used by
% both nanfilter and nanfiltfilt functions to avoid code duplication.
%
% Inputs:
%   functionName - String with the name of the calling function for error messages
%   b            - Numerator coefficients of the filter
%   a            - Denominator coefficients of the filter
%   x            - Input matrix with signals in columns that can include NaN values
%   maxgap       - Maximum gap size to interpolate (may be empty if not provided)
%
% Outputs:
%   b            - Validated numerator coefficients
%   a            - Validated denominator coefficients
%   x            - Validated input matrix
%   maxgap       - Validated maximum gap size (defaulted to 0 if not provided)

% Check number of input and output arguments
narginchk(4, 5);
nargoutchk(0, 4);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = functionName;
addRequired(parser, 'b', @(v) isnumeric(v) && isvector(v));
addRequired(parser, 'a', @(v) isnumeric(v) && isvector(v));
addRequired(parser, 'x', @(v) ismatrix(v));
addOptional(parser, 'maxgap', 0, @(v) isempty(v) || (isnumeric(v) && isscalar(v) && v >= 0));

if nargin < 5
    parse(parser, b, a, x);
else
    parse(parser, b, a, x, maxgap);
end

% Extract validated results
b = parser.Results.b;
a = parser.Results.a;
x = parser.Results.x;
maxgap = parser.Results.maxgap;

end
