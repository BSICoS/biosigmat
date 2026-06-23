function verifyBiosiglibExpectedError(testCase, functionHandle, caseDefinition)
%VERIFYBIOSIGLIBEXPECTEDERROR Verify that an expected-error case is rejected.

testCase.assertTrue(isfield(caseDefinition, 'expected_error'), sprintf( ...
    'Case "%s" does not define expected_error.', caseDefinition.id));
expectedError = caseDefinition.expected_error;
testCase.assertTrue(isfield(expectedError, 'category'), sprintf( ...
    'Case "%s" expected_error does not define a category.', caseDefinition.id));

supportedCategories = {
    'invalid_type'
    'invalid_shape'
    'invalid_value'
    'insufficient_data'
};
testCase.assertTrue(any(strcmp(expectedError.category, supportedCategories)), sprintf( ...
    'Case "%s" uses unsupported expected-error category "%s".', ...
    caseDefinition.id, expectedError.category));

didError = false;
try
    functionHandle();
catch
    didError = true;
end

testCase.verifyTrue(didError, sprintf( ...
    'Case "%s" expected MATLAB to reject input category "%s", but the call succeeded.', ...
    caseDefinition.id, expectedError.category));
end
