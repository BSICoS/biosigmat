function fixtureTable = loadBiosiglibFixtureTable(fixtureId, fileRole)
%LOADBIOSIGLIBFIXTURETABLE Load a CSV table declared by fixture ID and role.

fixtureId = char(fixtureId);
fileRole = char(fileRole);
biosiglibRoot = getBiosiglibRoot();
fixtureCatalog = loadBiosiglibFixtureCatalog();

fixtures = fixtureCatalog.fixtures;
if iscell(fixtures)
    fixtureIds = cellfun(@(fixture) fixture.id, fixtures, 'UniformOutput', false);
else
    fixtureIds = {fixtures.id};
end
fixtureIndex = find(strcmp(fixtureIds, fixtureId));
if numel(fixtureIndex) ~= 1
    error('biosigmat:FixtureNotFound', ...
        'Expected exactly one Biosiglib fixture with ID "%s"; found %d.', ...
        fixtureId, numel(fixtureIndex));
end
if iscell(fixtures)
    fixtureDefinition = fixtures{fixtureIndex};
else
    fixtureDefinition = fixtures(fixtureIndex);
end

fileRoles = {fixtureDefinition.files.role};
fileIndex = find(strcmp(fileRoles, fileRole));
if numel(fileIndex) ~= 1
    error('biosigmat:FixtureFileRoleNotFound', ...
        'Expected exactly one file role "%s" for fixture "%s"; found %d.', ...
        fileRole, fixtureId, numel(fileIndex));
end
fixtureFile = fixtureDefinition.files(fileIndex);
if ~strcmp(fixtureFile.format, 'csv')
    error('biosigmat:FixtureFileNotCsv', ...
        'Fixture "%s" file role "%s" must reference a CSV file.', fixtureId, fileRole);
end

relativePath = strrep(fixtureFile.path, '/', filesep);
csvPath = char(javaObject('java.io.File', ...
    fullfile(biosiglibRoot, relativePath)).getCanonicalPath());
rootPrefix = [lower(biosiglibRoot) filesep];
if ~startsWith(lower(csvPath), rootPrefix)
    error('biosigmat:FixturePathOutsideBiosiglib', ...
        'Fixture "%s" file role "%s" resolves outside Biosiglib: %s', ...
        fixtureId, fileRole, csvPath);
end
if ~isfile(csvPath)
    error('biosigmat:FixtureFileNotFound', ...
        'Fixture "%s" file role "%s" does not exist: %s', fixtureId, fileRole, csvPath);
end

fixtureTable = readtable(csvPath, 'VariableNamingRule', 'preserve');
end
