function verifyBiosiglibExpectedOutputs(testCase, actualOutputs, caseDefinition, outputIdMap)
%VERIFYBIOSIGLIBEXPECTEDOUTPUTS Verify literal or fixture-column case outputs.

if nargin < 4
    outputIdMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
end

expectedOutputs = caseDefinition.expected_outputs;
for outputIndex = 1:numel(expectedOutputs)
    if iscell(expectedOutputs)
        expectedOutput = expectedOutputs{outputIndex};
    else
        expectedOutput = expectedOutputs(outputIndex);
    end
    outputId = expectedOutput.id;

    if isKey(outputIdMap, outputId)
        matlabField = outputIdMap(outputId);
        testCase.assertTrue(isfield(actualOutputs, matlabField), sprintf( ...
            'MATLAB output field "%s" is missing for output ID "%s".', ...
            matlabField, outputId));
    elseif isfield(actualOutputs, outputId)
        matlabField = outputId;
    else
        testCase.assertFail(sprintf('Unknown expected output ID "%s".', outputId));
    end

    actualValue = actualOutputs.(matlabField);
    tolerance = expectedOutput.absolute_tolerance;
    if isfield(expectedOutput, 'value')
        expectedValue = normalizeExpectedValue(expectedOutput.value);
        if isscalar(actualValue) && isscalar(expectedValue)
            verifyScalarOutput(testCase, outputId, actualValue, ...
                expectedValue, tolerance, caseDefinition.nan_equal);
        else
            verifyVectorOutput(testCase, outputId, actualValue, ...
                expectedValue, tolerance, caseDefinition.nan_equal);
        end
    elseif all(isfield(expectedOutput, {'fixture_id', 'file_role', 'column'}))
        columnName = expectedOutput.column;
        fixtureTable = loadBiosiglibFixtureTable( ...
            expectedOutput.fixture_id, expectedOutput.file_role, columnName);
        testCase.assertTrue(ismember(columnName, fixtureTable.Properties.VariableNames), ...
            sprintf('Output "%s" references missing fixture column "%s".', ...
            outputId, columnName));
        verifyVectorOutput(testCase, outputId, actualValue, ...
            fixtureTable.(columnName), tolerance, caseDefinition.nan_equal);
    else
        testCase.assertFail(sprintf( ...
            'Output "%s" defines neither a scalar value nor a fixture-column value.', outputId));
    end
end
end

function value = normalizeExpectedValue(rawValue)
if ischar(rawValue)
    if ~strcmp(rawValue, 'NaN')
        error('biosigmat:UnsupportedExpectedValue', ...
            'Unsupported expected string value "%s".', rawValue);
    end
    value = NaN;
elseif iscell(rawValue)
    normalized = cellfun(@normalizeExpectedValue, rawValue, ...
        'UniformOutput', false);
    if all(cellfun(@(item) isnumeric(item) && isscalar(item), normalized))
        value = cell2mat(normalized);
    else
        error('biosigmat:UnsupportedExpectedValue', ...
            'Expected literal arrays must contain numeric scalars or NaN markers.');
    end
else
    value = rawValue;
end
end

function verifyScalarOutput(testCase, outputId, actualValue, expectedValue, tolerance, nanEqual)
testCase.assertTrue(isnumeric(actualValue) && isscalar(actualValue), sprintf( ...
    'Output "%s" must be a numeric scalar; actual length %d.', outputId, numel(actualValue)));

if isnan(expectedValue)
    diagnostic = sprintf( ...
        'Output "%s" mismatch: expected NaN, actual %.17g, absolute tolerance %.17g.', ...
        outputId, actualValue, tolerance);
    testCase.verifyTrue(nanEqual && isnan(actualValue), diagnostic);
else
    diagnostic = sprintf( ...
        'Output "%s" mismatch: expected %.17g, actual %.17g, absolute tolerance %.17g.', ...
        outputId, expectedValue, actualValue, tolerance);
    testCase.verifyEqual(actualValue, expectedValue, 'AbsTol', tolerance, diagnostic);
end
end

function verifyVectorOutput(testCase, outputId, actualValue, expectedValue, tolerance, nanEqual)
actualVector = actualValue(:);
expectedVector = expectedValue(:);
lengthDiagnostic = sprintf( ...
    'Output "%s" length mismatch: expected %d, actual %d, absolute tolerance %.17g.', ...
    outputId, numel(expectedVector), numel(actualVector), tolerance);
testCase.assertEqual(numel(actualVector), numel(expectedVector), lengthDiagnostic);

nanMatches = nanEqual & isnan(actualVector) & isnan(expectedVector);
numericMatches = ~isnan(actualVector) & ~isnan(expectedVector) & ...
    abs(actualVector - expectedVector) <= tolerance;
matches = nanMatches | numericMatches;
if any(~matches)
    mismatchIndex = find(~matches, 1);
    diagnostic = sprintf( ...
        'Output "%s" mismatch at index %d: expected %.17g, actual %.17g, absolute tolerance %.17g.', ...
        outputId, mismatchIndex, expectedVector(mismatchIndex), ...
        actualVector(mismatchIndex), tolerance);
    testCase.verifyTrue(false, diagnostic);
end
end
