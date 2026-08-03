classdef versionTest < matlab.unittest.TestCase
    % Tests for the public Biosigmat implementation-version API.

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
