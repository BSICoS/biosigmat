function biosiglibRoot = getBiosiglibRoot()
%GETBIOSIGLIBROOT Resolve and validate the pinned Biosiglib checkout.

persistent cachedRoot cachedExpectedCommit

helperDirectory = fileparts(mfilename('fullpath'));
repositoryRoot = fileparts(fileparts(helperDirectory));

configuredRoot = getenv('BIOSIGLIB_ROOT');
if isempty(configuredRoot)
    candidateRoot = fullfile(repositoryRoot, '..', 'biosiglib');
    checkoutSource = 'the sibling ../biosiglib fallback';
else
    candidateRoot = configuredRoot;
    checkoutSource = 'BIOSIGLIB_ROOT';
end

biosiglibRoot = char(javaObject('java.io.File', candidateRoot).getCanonicalPath());
if ~isfolder(biosiglibRoot)
    error('biosigmat:BiosiglibCheckoutNotFound', ...
        'Unable to resolve Biosiglib from %s: directory does not exist: %s', ...
        checkoutSource, biosiglibRoot);
end

requiredPaths = {
    fullfile('fixtures', 'catalog.json')
    'conformance'
    'specs'
};
for pathIndex = 1:numel(requiredPaths)
    requiredPath = fullfile(biosiglibRoot, requiredPaths{pathIndex});
    if ~(isfile(requiredPath) || isfolder(requiredPath))
        error('biosigmat:BiosiglibCheckoutIncomplete', ...
            'Invalid Biosiglib checkout at %s: missing required path %s.', ...
            biosiglibRoot, requiredPaths{pathIndex});
    end
end

expectedCommit = getBiosiglibCommit();

if ~isempty(cachedRoot) && strcmp(cachedRoot, biosiglibRoot) && ...
        strcmp(cachedExpectedCommit, expectedCommit)
    return;
end

gitCommand = sprintf( ...
    'git -c safe.directory="%s" -C "%s" rev-parse HEAD', ...
    biosiglibRoot, biosiglibRoot);
[gitStatus, gitOutput] = system(gitCommand);
if gitStatus ~= 0
    error('biosigmat:BiosiglibGitFailed', ...
        'Unable to read the Biosiglib commit with `%s` (exit code %d): %s', ...
        gitCommand, gitStatus, strtrim(gitOutput));
end

actualCommit = strtrim(gitOutput);
if ~strcmp(actualCommit, expectedCommit)
    error('biosigmat:BiosiglibCommitMismatch', ...
        'Biosiglib commit mismatch at %s: expected %s from biosiglib.lock, actual %s.', ...
        biosiglibRoot, expectedCommit, actualCommit);
end

cachedRoot = biosiglibRoot;
cachedExpectedCommit = expectedCommit;
end
