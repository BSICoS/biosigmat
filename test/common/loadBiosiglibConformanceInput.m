function values = loadBiosiglibConformanceInput(caseDefinition, inputId)
%LOADBIOSIGLIBCONFORMANCEINPUT Load a literal or fixture-backed case input.

inputDefinition = getBiosiglibConformanceInput(caseDefinition, inputId);
if isfield(inputDefinition, 'value')
    values = inputDefinition.value;
    return;
end

requiredFixtureFields = {'fixture_id', 'file_role', 'column'};
if ~all(isfield(inputDefinition, requiredFixtureFields))
    error('biosigmat:ConformanceInputInvalid', ...
        'Case "%s" input "%s" is neither literal nor fixture-backed.', ...
        caseDefinition.id, inputId);
end

values = loadBiosiglibFixtureColumn(caseDefinition, inputId);
end
