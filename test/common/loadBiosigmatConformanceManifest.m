function manifest = loadBiosigmatConformanceManifest()
%LOADBIOSIGMATCONFORMANCEMANIFEST Load and cache the Biosigmat manifest.

persistent cachedManifest cachedPath cachedBytes cachedDatenum

helperDirectory = fileparts(mfilename('fullpath'));
repositoryRoot = fileparts(fileparts(helperDirectory));
manifestPath = fullfile(repositoryRoot, 'conformance.json');
manifestInfo = dir(manifestPath);
if isempty(manifestInfo)
    error('biosigmat:ConformanceManifestInvalid', ...
        'Biosigmat conformance manifest does not exist: %s', manifestPath);
end

cacheIsCurrent = ~isempty(cachedManifest) && strcmp(cachedPath, manifestPath) && ...
    cachedBytes == manifestInfo.bytes && cachedDatenum == manifestInfo.datenum;
if ~cacheIsCurrent
    try
        cachedManifest = jsondecode(fileread(manifestPath));
    catch exception
        error('biosigmat:ConformanceManifestInvalid', ...
            'Unable to load Biosigmat conformance manifest %s: %s', ...
            manifestPath, exception.message);
    end
    cachedPath = manifestPath;
    cachedBytes = manifestInfo.bytes;
    cachedDatenum = manifestInfo.datenum;
end

manifest = cachedManifest;
end
