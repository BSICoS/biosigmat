% Tests covering:
%   - Biosiglib conformance for tdmetrics

classdef tdmetricsTest < matlab.unittest.TestCase
    properties (TestParameter)
        caseId = getBiosiglibConformanceCaseIds('hrv.tdmetrics')
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
        function testBiosiglibConformanceCase(tc, caseId)
            caseDefinition = loadBiosiglibConformanceCase(caseId);
            dtk = loadBiosiglibConformanceInput(caseDefinition, 'dtk');

            if isfield(caseDefinition, 'expected_error')
                verifyBiosiglibExpectedError(tc, ...
                    @() tdmetrics(dtk), caseDefinition);
                return;
            end

            metrics = tdmetrics(dtk);

            verifyBiosiglibExpectedOutputs(tc, metrics, caseDefinition);
        end

        function testAllNanInputReturnsAllNanMetrics(tc)
            metrics = tdmetrics([NaN, NaN]);

            tc.verifyTrue(all(structfun(@isnan, metrics)));
        end
    end
end
