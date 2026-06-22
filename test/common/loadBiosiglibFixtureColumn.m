function values = loadBiosiglibFixtureColumn(caseDefinition, inputId)
%LOADBIOSIGLIBFIXTURECOLUMN Load an input column declared by a conformance case.

inputId = char(inputId);
inputIds = {caseDefinition.inputs.id};
inputIndex = find(strcmp(inputIds, inputId));
if numel(inputIndex) ~= 1
    error('biosigmat:ConformanceInputNotFound', ...
        'Expected exactly one input "%s" in case "%s"; found %d.', ...
        inputId, caseDefinition.id, numel(inputIndex));
end

inputDefinition = caseDefinition.inputs(inputIndex);
columnName = inputDefinition.column;
fixtureTable = loadBiosiglibFixtureTable( ...
    inputDefinition.fixture_id, inputDefinition.file_role, columnName);
if ~ismember(columnName, fixtureTable.Properties.VariableNames)
    error('biosigmat:FixtureColumnNotFound', ...
        'Case "%s" input "%s" references missing column "%s".', ...
        caseDefinition.id, inputId, columnName);
end

values = fixtureTable.(columnName);
end
