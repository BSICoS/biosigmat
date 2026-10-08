% trimnansTest.m - Test class for the trimnans function
% Tests covering:
%   - Basic functionality with different NaN combinations
%   - Edge cases with all NaN or no NaN signals

classdef trimnansTest < matlab.unittest.TestCase

    properties (TestParameter)
        caseId = getBiosiglibConformanceCaseIds('tools.trimnans')
    end

    methods (TestClassSetup)
        function addCodeToPath(tc)
            repositoryRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            originalPath = path;
            tc.addTeardown(@() path(originalPath));
            addpath(fullfile(repositoryRoot, 'src', 'tools'));
            addpath(fullfile(repositoryRoot, 'test', 'common'));
        end
    end

    methods (Test)
        function testBiosiglibConformanceCase(tc, caseId)
            caseDefinition = loadBiosiglibConformanceCase(caseId);
            signal = loadBiosiglibConformanceInput(caseDefinition, 'signal');
            actualOutputs = struct('trimmed_signal', trimnans(signal));
            verifyBiosiglibExpectedOutputs(tc, actualOutputs, caseDefinition);
        end

        function testEmptyInput(tc)
            tc.verifyEmpty(trimnans([]));
        end

        function testInvalidInputs(tc)
            invalidInputs = {Inf, -Inf, [NaN, Inf, 2], [1+2i, 3], ...
                'invalid', [1, 2; 3, 4]};
            for k = 1:numel(invalidInputs)
                tc.verifyError(@() trimnans(invalidInputs{k}), ...
                    'MATLAB:InputParser:ArgumentFailedValidation');
            end
        end

        function testBasicFunctionality(tc)
            signal = [NaN; NaN; 1; 2; NaN; 3; NaN; NaN];
            expected = [1; 2; NaN; 3];

            actual = trimnans(signal);

            tc.verifyEqual(actual, expected, 'Basic functionality with NaN at beginning and end failed');
        end

        function testNanAtBeginningOnly(tc)
            signal = [NaN; NaN; 1; 2; 3; 4];
            expected = [1; 2; 3; 4];

            actual = trimnans(signal);

            tc.verifyEqual(actual, expected, 'NaN at beginning only failed');
        end

        function testNanAtEndOnly(tc)
            signal = [1; 2; 3; 4; NaN; NaN];
            expected = [1; 2; 3; 4];

            actual = trimnans(signal);

            tc.verifyEqual(actual, expected, 'NaN at end only failed');
        end

        function testNanInMiddleOnly(tc)
            signal = [1; 2; NaN; NaN; 3; 4];
            expected = [1; 2; NaN; NaN; 3; 4];

            actual = trimnans(signal);

            tc.verifyEqual(actual, expected, 'NaN in middle only failed');
        end

        function testNoNan(tc)
            signal = [1; 2; 3; 4; 5];
            expected = [1; 2; 3; 4; 5];

            actual = trimnans(signal);

            tc.verifyEqual(actual, expected, 'No NaN values failed');
        end

        function testAllNan(tc)
            signal = [NaN; NaN; NaN; NaN];
            expected = [];

            actual = trimnans(signal);

            tc.verifyEqual(actual, expected, 'All NaN values failed');
        end

        function testSingleValidValue(tc)
            signal = [NaN; NaN; 5; NaN; NaN];
            expected = 5;

            actual = trimnans(signal);

            tc.verifyEqual(actual, expected, 'Single valid value failed');
        end

        function testRowVectorInput(tc)
            signal = [NaN, NaN, 1, 2, NaN, 3, NaN, NaN]; % Row vector
            expected = [1; 2; NaN; 3]; % Column vector

            actual = trimnans(signal);

            tc.verifyEqual(actual, expected, 'Row vector input failed');
        end
    end

end
