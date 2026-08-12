function commit = getBiosiglibCommit()
%GETBIOSIGLIBCOMMIT Read the exact Biosiglib commit pinned by this repository.

helperDirectory = fileparts(mfilename('fullpath'));
repositoryRoot = fileparts(fileparts(helperDirectory));
lockPath = fullfile(repositoryRoot, 'biosiglib.lock');

if ~isfile(lockPath)
    error('biosigmat:BiosiglibLockInvalid', ...
        'Biosiglib lock does not exist: %s', lockPath);
end

rawLock = fileread(lockPath);
if isempty(regexp(rawLock, '^[0-9a-f]{40}(\r\n|\n)?$', 'once'))
    error('biosigmat:BiosiglibLockInvalid', ...
        'Biosiglib lock must contain one lowercase 40-character SHA: %s', lockPath);
end

commit = rawLock(1:40);
end
