% VERSIONEXAMPLE Query the installed Biosigmat implementation version.
%
% This example uses the package-qualified public API so MATLAB's built-in
% version function remains available independently.

implementationVersion = biosigmat.version();
fprintf('Biosigmat %s\n', implementationVersion);
