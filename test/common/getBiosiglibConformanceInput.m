function inputDefinition = getBiosiglibConformanceInput(caseDefinition, inputId)
%GETBIOSIGLIBCONFORMANCEINPUT Find one case input by canonical ID.

inputId = char(inputId);
inputs = caseDefinition.inputs;
if iscell(inputs)
    inputMatches = cellfun(@(input) isfield(input, 'id') && ...
        strcmp(input.id, inputId), inputs);
else
    inputMatches = strcmp({inputs.id}, inputId);
end

inputIndex = find(inputMatches);
if numel(inputIndex) ~= 1
    error('biosigmat:ConformanceInputNotFound', ...
        'Expected exactly one input "%s" in case "%s"; found %d.', ...
        inputId, caseDefinition.id, numel(inputIndex));
end

if iscell(inputs)
    inputDefinition = inputs{inputIndex};
else
    inputDefinition = inputs(inputIndex);
end
end
