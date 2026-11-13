classdef versionTest < matlab.unittest.TestCase
    % Tests for the public Biosigmat implementation-version API.

    methods (TestClassSetup)
        function addPackageRootToPath(testCase)
            testDirectory = fileparts(mfilename('fullpath'));
            repositoryRoot = fileparts(fileparts(testDirectory));
            originalPath = path;
            testCase.addTeardown(@() path(originalPath));
            addpath(fullfile(repositoryRoot, 'src'));
        end
    end

    methods (Test)
        function versionIsStableOrBetaSemanticVersion(testCase)
            actual = biosigmat.version();

            testCase.verifyClass(actual, 'char');
            testCase.verifyNotEmpty(regexp(actual, '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-beta)?$', 'once'));
        end

        function packageFunctionDoesNotShadowMatlabVersion(testCase)
            testCase.verifyNotEqual(which('version'), which('biosigmat.version'));
        end
    end
end
