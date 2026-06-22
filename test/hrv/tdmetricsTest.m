% Tests covering:
%   - Biosiglib conformance for tdmetrics

classdef tdmetricsTest < matlab.unittest.TestCase
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
        function testBasicFuntionality(tc)
            caseDefinition = loadBiosiglibConformanceCase( ...
                'hrv.tdmetrics.ecg_tk_001');
            dtk = loadBiosiglibFixtureColumn(caseDefinition, 'nn_intervals');
            tc.assertTrue(isnan(dtk(1)), ...
                'The shared dtk input must retain its leading NaN value.');

            metrics = tdmetrics(dtk);

            outputIdMap = containers.Map({'pnn50'}, {'pNN50'});
            verifyBiosiglibExpectedOutputs(tc, metrics, caseDefinition, outputIdMap);
        end
    end
end
