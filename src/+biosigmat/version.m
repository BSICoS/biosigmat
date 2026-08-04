function versionNumber = version()
% VERSION Return the installed Biosigmat implementation version.
%
%   VERSIONNUMBER = BIOSIGMAT.VERSION() returns the authoritative Biosigmat
%   implementation version as a character vector. Biosigmat versions are
%   independent from Biosiglib specification releases.
%
%   The package-qualified name avoids shadowing MATLAB's built-in VERSION
%   function.
%
%   Example:
%     currentVersion = biosigmat.version();
%
%   See also VERSION, VER

narginchk(0, 0);
nargoutchk(0, 1);

parser = inputParser;
parser.FunctionName = 'biosigmat.version';
parse(parser);

versionNumber = '0.2.0';

end
