function fixtureCatalog = loadBiosiglibFixtureCatalog()
%LOADBIOSIGLIBFIXTURECATALOG Load the pinned Biosiglib fixture catalog.

biosiglibRoot = getBiosiglibRoot();
catalogPath = fullfile(biosiglibRoot, 'fixtures', 'catalog.json');
fixtureCatalog = jsondecode(fileread(catalogPath));
end
