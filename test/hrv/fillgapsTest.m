% Tests covering shared hrv.fillgaps conformance and MATLAB API behavior.

classdef fillgapsTest < matlab.unittest.TestCase
    properties (TestParameter)
        caseId = getBiosiglibConformanceCaseIds('hrv.fillgaps')
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

            [tn, dtn] = fillgaps(tk);

            outputs = struct('tn', tn, 'dtn', dtn);
            verifyBiosiglibExpectedOutputs(tc, outputs, caseDefinition);
        end

        function testRejectsUnsortedAndDuplicateEvents(tc)
            tc.verifyError(@() fillgaps([0, 2, 1]), ...
                'biosigmat:fillgaps:EventOrder');
            tc.verifyError(@() fillgaps([0, 1, 1]), ...
                'biosigmat:fillgaps:EventOrder');
        end

        function testDoesNotRemoveCloseEventsImplicitly(tc)
            tk = [0, 1, 1.2, 2.2, 3.2, 4.2];

            tn = fillgaps(tk);

            tc.verifyTrue(ismember(1.2, tn));
            tc.verifyTrue(all(ismember(tk, tn)));
        end

        function testCanonicalNamedParameters(tc)
            [tn, dtn] = fillgaps([0, 1, 2, 4, 5, 6], false, 10, ...
                'GapDetectionFactor', 1.5, ...
                'CorrectionUpperFactor', 1.15, ...
                'CorrectionLowerFactor', 0.75, ...
                'MinimumInterval', 0.5);

            tc.verifyEqual(tn, (0:6)');
            tc.verifyEqual(dtn, ones(6, 1));
        end
    end
end
