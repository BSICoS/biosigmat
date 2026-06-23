function values = loadBiosiglibFixtureColumn(caseDefinition, inputId)
%LOADBIOSIGLIBFIXTURECOLUMN Load an input column declared by a conformance case.

inputId = char(inputId);
inputDefinition = getBiosiglibConformanceInput(caseDefinition, inputId);
requiredFixtureFields = {'fixture_id', 'file_role', 'column'};
if ~all(isfield(inputDefinition, requiredFixtureFields))
    error('biosigmat:ConformanceInputNotFixtureBacked', ...
        'Case "%s" input "%s" is not fixture-backed.', ...
        caseDefinition.id, inputId);
end
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
