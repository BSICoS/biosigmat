function fixtureCatalog = loadBiosiglibFixtureCatalog()
%LOADBIOSIGLIBFIXTURECATALOG Load the pinned Biosiglib fixture catalog.

persistent cachedScope cachedCatalog

biosiglibRoot = getBiosiglibRoot();
manifest = loadBiosigmatConformanceManifest();
cacheScope = [biosiglibRoot '|' manifest.biosiglib.commit];
if ~isempty(cachedCatalog) && strcmp(cachedScope, cacheScope)
    fixtureCatalog = cachedCatalog;
    return;
end

catalogPath = fullfile(biosiglibRoot, 'fixtures', 'catalog.json');
fixtureCatalog = jsondecode(fileread(catalogPath));
cachedScope = cacheScope;
cachedCatalog = fixtureCatalog;
end
