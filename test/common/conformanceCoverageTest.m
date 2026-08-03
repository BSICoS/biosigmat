classdef conformanceCoverageTest < matlab.unittest.TestCase
    methods (Test)
        function testEveryDiscoveredCaseIsCollected(tc)
            testDirectory = fileparts(mfilename('fullpath'));
            repositoryRoot = fileparts(fileparts(testDirectory));
            suite = testsuite(fullfile(repositoryRoot, 'test'), ...
                'IncludeSubfolders', true);
            suiteNames = {suite.Name};
            discoveredCases = discoverBiosiglibConformanceCases();
            discoveredIds = {discoveredCases.id};
            isCollected = cellfun(@(caseId) any(contains( ...
                suiteNames, caseId)), discoveredIds);
            collectedIds = discoveredIds(isCollected);

            assertCompleteBiosiglibConformanceCaseCoverage( ...
                discoveredIds, collectedIds);
            tc.verifyEqual(numel(collectedIds), numel(discoveredIds));
        end

        function testNewlyDiscoveredUncollectedCaseFails(tc)
            discoveredIds = {
                'hrv.tdmetrics.existing_case'
                'hrv.tdmetrics.new_case'
                };
            collectedIds = {'hrv.tdmetrics.existing_case'};

            tc.verifyError(@() ...
                assertCompleteBiosiglibConformanceCaseCoverage( ...
                discoveredIds, collectedIds), ...
                'biosigmat:IncompleteConformanceCaseCoverage');
        end
    end
end
