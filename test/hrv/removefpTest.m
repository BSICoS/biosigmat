% Tests covering shared hrv.removefp conformance and MATLAB API behavior.

classdef removefpTest < matlab.unittest.TestCase
    properties (TestParameter)
        caseId = getBiosiglibConformanceCaseIds('hrv.removefp')
    end

    methods (TestClassSetup)
        function addCodeToPath(tc)
            testDirectory = fileparts(mfilename('fullpath'));
            repositoryRoot = fileparts(fileparts(testDirectory));
            originalPath = path;
            tc.addTeardown(@() path(originalPath));
            addpath(fullfile(repositoryRoot, 'src', 'hrv'));
            addpath(fullfile(repositoryRoot, 'src', 'tools'));
            addpath(fullfile(repositoryRoot, 'test', 'common'));
        end
    end

    methods (Test)
        function testBiosiglibConformanceCase(tc, caseId)
            caseDefinition = loadBiosiglibConformanceCase(caseId);
            tk = loadBiosiglibConformanceInput(caseDefinition, 'tk');

            tn = removefp(tk);

            verifyBiosiglibExpectedOutputs(tc, struct('tn', tn), caseDefinition);
        end

        function testRejectsUnsortedAndDuplicateEvents(tc)
            tc.verifyError(@() removefp([0, 2, 1]), ...
                'biosigmat:removefp:EventOrder');
            tc.verifyError(@() removefp([0, 1, 1]), ...
                'biosigmat:removefp:EventOrder');
        end

        function testOutputUsesCanonicalColumnOrientation(tc)
            actual = removefp([0, 1, 2, 2.2, 3, 4, 5]);

            tc.verifySize(actual, [6, 1]);
        end
    end
end
