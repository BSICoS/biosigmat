function biosiglibRoot = getBiosiglibRoot()
%GETBIOSIGLIBROOT Resolve and validate the pinned Biosiglib checkout.

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

requiredFiles = {
    fullfile('fixtures', 'catalog.json')
    fullfile('conformance', 'hrv', 'tdmetrics', 'ecg_tk_001.json')
    fullfile('conformance', 'ecg', 'pantompkins', 'edr_signals_001.json')
    fullfile('schemas', 'implementation-manifest.schema.json')
};
for fileIndex = 1:numel(requiredFiles)
    requiredPath = fullfile(biosiglibRoot, requiredFiles{fileIndex});
    if ~isfile(requiredPath)
        error('biosigmat:BiosiglibCheckoutIncomplete', ...
            'Invalid Biosiglib checkout at %s: missing required file %s.', ...
            biosiglibRoot, requiredFiles{fileIndex});
    end
end

manifestPath = fullfile(repositoryRoot, 'conformance.json');
try
    manifest = jsondecode(fileread(manifestPath));
    expectedCommit = manifest.biosiglib.commit;
catch exception
    error('biosigmat:ConformanceManifestInvalid', ...
        'Unable to load the pinned Biosiglib commit from %s: %s', ...
        manifestPath, exception.message);
end

if ~ischar(expectedCommit) || isempty(regexp(expectedCommit, '^[0-9a-fA-F]{40}$', 'once'))
    error('biosigmat:ConformanceManifestInvalid', ...
        'The Biosiglib commit in %s must be a valid 40-character SHA.', manifestPath);
end

gitCommand = sprintf('git -C "%s" rev-parse HEAD', biosiglibRoot);
[gitStatus, gitOutput] = system(gitCommand);
if gitStatus ~= 0
    error('biosigmat:BiosiglibGitFailed', ...
        'Unable to read the Biosiglib commit with `%s` (exit code %d): %s', ...
        gitCommand, gitStatus, strtrim(gitOutput));
end

actualCommit = strtrim(gitOutput);
if ~strcmp(actualCommit, expectedCommit)
    error('biosigmat:BiosiglibCommitMismatch', ...
        'Biosiglib commit mismatch at %s: expected %s from conformance.json, actual %s.', ...
        biosiglibRoot, expectedCommit, actualCommit);
end
end
