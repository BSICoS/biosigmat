function caseDefinition = loadBiosiglibConformanceCase(caseId)
%LOADBIOSIGLIBCONFORMANCECASE Load a pinned Biosiglib case by canonical ID.

persistent cachedScope caseCache

caseId = char(caseId);
idParts = strsplit(caseId, '.');
if numel(idParts) < 3
    error('biosigmat:InvalidConformanceCaseId', ...
        'Conformance case ID must contain module, algorithm, and case parts: %s', caseId);
end

biosiglibRoot = getBiosiglibRoot();
manifest = loadBiosigmatConformanceManifest();
cacheScope = [biosiglibRoot '|' manifest.biosiglib.commit];
if isempty(caseCache) || ~strcmp(cachedScope, cacheScope)
    caseCache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    cachedScope = cacheScope;
end
if isKey(caseCache, caseId)
    caseDefinition = caseCache(caseId);
    return;
end

caseFilename = [strjoin(idParts(3:end), '.') '.json'];
casePath = fullfile(biosiglibRoot, 'conformance', idParts{1}, idParts{2}, caseFilename);
if ~isfile(casePath)
    error('biosigmat:ConformanceCaseNotFound', ...
        'Biosiglib conformance case "%s" does not exist: %s', caseId, casePath);
end

caseDefinition = jsondecode(fileread(casePath));
if ~isfield(caseDefinition, 'id') || ~strcmp(caseDefinition.id, caseId)
    error('biosigmat:ConformanceCaseIdMismatch', ...
        'Conformance case at %s must declare ID "%s".', casePath, caseId);
end

caseCache(caseId) = caseDefinition;
end
