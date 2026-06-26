% Tests covering:
%   - Biosiglib conformance for tdmetrics

classdef tdmetricsTest < matlab.unittest.TestCase
    properties (TestParameter)
        validCaseId = {
            'hrv.tdmetrics.valid_dtk_001'
            'hrv.tdmetrics.valid_dtk_with_nan_001'
        }
        expectedErrorCaseId = {
            'hrv.tdmetrics.invalid_dtk_non_numeric'
            'hrv.tdmetrics.invalid_dtk_matrix'
            'hrv.tdmetrics.invalid_dtk_negative'
            'hrv.tdmetrics.invalid_dtk_zero'
            'hrv.tdmetrics.invalid_dtk_inf'
        }
    end

    methods (TestClassSetup)
        function addCodeToPath(tc)
            testDirectory = fileparts(mfilename('fullpath'));
            repositoryRoot = fileparts(fileparts(testDirectory));
            originalPath = path;
            tc.addTeardown(@() path(originalPath));
            addpath(fullfile(repositoryRoot, 'src', 'hrv'));
            addpath(fullfile(repositoryRoot, 'test', 'common'));
        end
    end

    methods (Test)
        function testBasicFunctionality(tc, validCaseId)
            caseDefinition = loadBiosiglibConformanceCase(validCaseId);
            dtk = loadBiosiglibConformanceInput(caseDefinition, 'dtk');

            metrics = tdmetrics(dtk);

            outputIdMap = containers.Map({'pnn50'}, {'pNN50'});
            verifyBiosiglibExpectedOutputs(tc, metrics, caseDefinition, outputIdMap);
        end

        function testExpectedError(tc, expectedErrorCaseId)
            caseDefinition = loadBiosiglibConformanceCase(expectedErrorCaseId);
            dtk = loadBiosiglibConformanceInput(caseDefinition, 'dtk');

            verifyBiosiglibExpectedError(tc, ...
                @() tdmetrics(dtk), caseDefinition);
        end
    end
end
