function verifyBiosiglibExpectedWarnings( ...
        testCase, functionHandle, caseDefinition, warningIdMap)
%VERIFYBIOSIGLIBEXPECTEDWARNINGS Verify canonical warning IDs and affected IDs.

canonicalIds = keys(warningIdMap);
matlabIds = values(warningIdMap, canonicalIds);
expectedWarnings = getExpectedWarnings(caseDefinition);
expectedIds = cellfun(@(item) char(item.id), expectedWarnings, ...
    'UniformOutput', false);

unknownExpectedIds = setdiff(expectedIds, canonicalIds, 'stable');
testCase.assertEmpty(unknownExpectedIds, sprintf( ...
    'Case "%s" expects warning IDs missing from the MATLAB warning map: %s.', ...
    caseDefinition.id, strjoin(unknownExpectedIds, ', ')));

warningState = warning;
restoreWarnings = onCleanup(@() warning(warningState)); %#ok<NASGU>
for iExpected = 1:numel(expectedWarnings)
    setWarningStates(matlabIds, 'off');
    expectedId = expectedIds{iExpected};
    matlabId = warningIdMap(expectedId);
    warning('error', matlabId);
    [didWarn, message] = executeForWarning(functionHandle, matlabId);
    testCase.assertTrue(didWarn, sprintf( ...
        'Expected canonical warning "%s" for case "%s".', ...
        expectedId, caseDefinition.id));

    actualAffectedIds = parseAffectedIds(message);
    expectedAffectedIds = normalizeStringList( ...
        expectedWarnings{iExpected}.affected_ids);
    testCase.verifyEqual(sort(actualAffectedIds(:)), ...
        sort(expectedAffectedIds(:)), sprintf( ...
        'Warning "%s" must aggregate the complete affected_ids set.', ...
        expectedId));

    setWarningStates(matlabIds, 'off');
    warning('on', matlabId);
    commandOutput = evalc('functionHandle();');
    occurrences = regexp(commandOutput, ...
        [regexptranslate('escape', expectedId) ' affected_ids:'], 'match');
    testCase.verifyNumElements(occurrences, 1, sprintf( ...
        'Warning "%s" must be emitted once per call.', expectedId));
end

setWarningStates(matlabIds, 'off');
warning('error', 'all');
expectedMatlabIds = cellfun(@(id) warningIdMap(id), expectedIds, ...
    'UniformOutput', false);
setWarningStates(expectedMatlabIds, 'off');
try
    functionHandle();
catch exception
    error('biosigmat:UnexpectedWarning', ...
        ['Case "%s" emitted an unexpected warning or error "%s": %s'], ...
        caseDefinition.id, exception.identifier, exception.message);
end
end

function [didWarn, message] = executeForWarning(functionHandle, matlabId)
didWarn = false;
message = '';
try
    functionHandle();
catch exception
    if strcmp(exception.identifier, matlabId)
        didWarn = true;
        message = exception.message;
    else
        rethrow(exception);
    end
end
end

function warnings = getExpectedWarnings(caseDefinition)
if ~isfield(caseDefinition, 'expected_warnings')
    warnings = {};
    return;
end

rawWarnings = caseDefinition.expected_warnings;
if iscell(rawWarnings)
    warnings = rawWarnings;
else
    warnings = arrayfun(@(item) item, rawWarnings, ...
        'UniformOutput', false);
end
end

function setWarningStates(matlabIds, state)
for iWarning = 1:numel(matlabIds)
    warning(state, matlabIds{iWarning});
end
end

function affectedIds = parseAffectedIds(message)
match = regexp(message, 'affected_ids:\s*([a-z0-9_, ]+)$', ...
    'tokens', 'once');
if isempty(match)
    affectedIds = {};
else
    affectedIds = cellfun(@strtrim, strsplit(match{1}, ','), ...
        'UniformOutput', false);
end
end

function values = normalizeStringList(rawValues)
if ischar(rawValues)
    values = {rawValues};
elseif isstring(rawValues)
    values = cellstr(rawValues);
elseif iscell(rawValues)
    values = cellfun(@char, rawValues, 'UniformOutput', false);
else
    error('biosigmat:UnsupportedExpectedWarning', ...
        'expected_warnings affected_ids must contain strings.');
end
end
