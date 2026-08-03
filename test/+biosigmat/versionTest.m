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
        function versionIsPreOneSemanticVersion(testCase)
            actual = biosigmat.version();

            testCase.verifyClass(actual, 'char');
            testCase.verifyNotEmpty(regexp(actual, '^0\.\d+\.\d+$', 'once'));
        end

        function packageFunctionDoesNotShadowMatlabVersion(testCase)
            testCase.verifyNotEqual(which('version'), which('biosigmat.version'));
        end
    end
end
