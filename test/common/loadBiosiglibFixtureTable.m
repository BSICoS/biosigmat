function fixtureTable = loadBiosiglibFixtureTable(fixtureId, fileRole, columnName)
%LOADBIOSIGLIBFIXTURETABLE Load a CSV table declared by fixture ID and role.

persistent cachedScope tableCache

fixtureId = char(fixtureId);
fileRole = char(fileRole);
if nargin < 3
    columnName = '';
else
    columnName = char(columnName);
end
biosiglibRoot = getBiosiglibRoot();
manifest = loadBiosigmatConformanceManifest();
cacheScope = [biosiglibRoot '|' manifest.biosiglib.commit];
if isempty(tableCache) || ~strcmp(cachedScope, cacheScope)
    tableCache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    cachedScope = cacheScope;
end
cacheKey = [fixtureId '|' fileRole];
if isKey(tableCache, cacheKey)
    cacheEntry = tableCache(cacheKey);
    if isempty(columnName) && cacheEntry.hasFullTable
        fixtureTable = cacheEntry.fullTable;
        return;
    elseif ~isempty(columnName) && cacheEntry.hasFullTable
        if ~ismember(columnName, cacheEntry.fullTable.Properties.VariableNames)
            error('biosigmat:FixtureColumnNotFound', ...
                'Fixture "%s" file role "%s" has no column "%s".', ...
                fixtureId, fileRole, columnName);
        end
        fixtureTable = cacheEntry.fullTable(:, {columnName});
        return;
    elseif ~isempty(columnName) && isKey(cacheEntry.columnTables, columnName)
        fixtureTable = cacheEntry.columnTables(columnName);
        return;
    end
else
    cacheEntry = [];
end

if isempty(cacheEntry)
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
            'Fixture "%s" file role "%s" does not exist: %s', ...
            fixtureId, fileRole, csvPath);
    end

    variableNames = readCsvHeader(csvPath, fixtureId, fileRole);
    cacheEntry = struct( ...
        'csvPath', csvPath, ...
        'variableNames', {variableNames}, ...
        'hasFullTable', false, ...
        'fullTable', table(), ...
        'columnTables', containers.Map('KeyType', 'char', 'ValueType', 'any'));
end

if isempty(columnName)
    fixtureTable = readNumericCsvTable( ...
        cacheEntry.csvPath, cacheEntry.variableNames, 1:numel(cacheEntry.variableNames));
    cacheEntry.fullTable = fixtureTable;
    cacheEntry.hasFullTable = true;
else
    columnIndex = find(strcmp(cacheEntry.variableNames, columnName));
    if numel(columnIndex) ~= 1
        error('biosigmat:FixtureColumnNotFound', ...
            'Fixture "%s" file role "%s" has no column "%s".', ...
            fixtureId, fileRole, columnName);
    end
    fixtureTable = readNumericCsvTable( ...
        cacheEntry.csvPath, cacheEntry.variableNames, columnIndex);
    cacheEntry.columnTables(columnName) = fixtureTable;
end
tableCache(cacheKey) = cacheEntry;
end

function variableNames = readCsvHeader(csvPath, fixtureId, fileRole)
fileId = fopen(csvPath, 'r');
if fileId == -1
    error('biosigmat:FixtureFileUnreadable', ...
        'Unable to read fixture "%s" file role "%s": %s', ...
        fixtureId, fileRole, csvPath);
end
cleanup = onCleanup(@() fclose(fileId));
headerLine = fgetl(fileId);
if ~ischar(headerLine)
    error('biosigmat:FixtureFileUnreadable', ...
        'Fixture "%s" file role "%s" has no CSV header: %s', ...
        fixtureId, fileRole, csvPath);
end
variableNames = strtrim(strsplit(headerLine, ','));
variableNames = cellfun(@(name) strrep(name, '"', ''), ...
    variableNames, 'UniformOutput', false);
end

function fixtureTable = readNumericCsvTable(csvPath, variableNames, selectedIndexes)
formatFields = repmat({'%*f'}, 1, numel(variableNames));
formatFields(selectedIndexes) = {'%f'};
formatSpec = strjoin(formatFields, '');

fileId = fopen(csvPath, 'r');
if fileId == -1
    error('biosigmat:FixtureFileUnreadable', ...
        'Unable to read Biosiglib fixture CSV: %s', csvPath);
end
cleanup = onCleanup(@() fclose(fileId));
fgetl(fileId);
parsedColumns = textscan(fileId, formatSpec, ...
    'Delimiter', ',', 'CollectOutput', true, 'EmptyValue', NaN, 'ReturnOnError', false);
fixtureTable = array2table(parsedColumns{1}, ...
    'VariableNames', variableNames(selectedIndexes));
end
