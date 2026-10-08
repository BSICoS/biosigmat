% Tests covering:
%   - No NaNs (identity)
%   - Expansion around NaN segments (vector, preserves orientation)
%   - Column-wise processing for matrix inputs
%   - No expansion when seconds = 0
%   - Invalid input handling

classdef expandnansTest < matlab.unittest.TestCase

    properties (TestParameter)
        caseId = getBiosiglibConformanceCaseIds('tools.expandnans')
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
            fs = loadBiosiglibConformanceInput(caseDefinition, 'sampling_frequency');
            seconds = loadBiosiglibConformanceInput(caseDefinition, 'expansion_duration');
            actualOutputs = struct('expanded_signal', expandnans(signal, fs, seconds));
            verifyBiosiglibExpectedOutputs(tc, actualOutputs, caseDefinition);
        end

        function testEmptyInput(tc)
            tc.verifyEmpty(expandnans([], 10, 0.2));
        end

        function testInvalidSignalValues(tc)
            invalidInputs = {Inf, -Inf, [NaN, Inf, 2], [1+2i, 3]};
            for k = 1:numel(invalidInputs)
                tc.verifyError(@() expandnans(invalidInputs{k}, 10, 0.2), ...
                    'MATLAB:InputParser:ArgumentFailedValidation');
            end
            tc.verifyError(@() expandnans([], Inf, 0.2), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
            tc.verifyError(@() expandnans([], 10, NaN), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function testIdentityPathsPreserveRowOrientation(tc)
            tc.verifyEqual(expandnans([1, 2, 3], 10, 0.2), [1, 2, 3]);
            tc.verifyEqual(expandnans([1, NaN, 3], 10, 0), [1, NaN, 3]);
            tc.verifyEqual(expandnans([1, NaN, 3], 10, 0.04), [1, NaN, 3]);
        end

        function testNoNansReturnsSame(tc)
            signal = (1:20)';
            fs = 10;
            seconds = 0.5;

            actual = expandnans(signal, fs, seconds);

            tc.verifyEqual(actual, signal);
        end

        function testVectorExpansionPreservesOrientation(tc)
            signal = 1:20; % row vector input
            fs = 10;
            seconds = 0.2; % cleanWindow = 2 samples

            signal(11) = NaN;
            actual = expandnans(signal, fs, seconds);

            expected = 1:20;
            expected(9:13) = NaN;

            tc.verifyTrue(isrow(actual), 'Output should preserve row-vector orientation');
            tc.verifyEqual(actual, expected);
        end

        function testMatrixProcessedColumnwise(tc)
            fs = 10;
            seconds = 0.1; % cleanWindow = 1 sample

            signal = repmat((1:12)', 1, 2);
            signal(5, 1) = NaN;  % should expand to 4:6 in col 1
            signal(9, 2) = NaN;  % should expand to 8:10 in col 2

            actual = expandnans(signal, fs, seconds);

            expected = signal;
            expected(4:6, 1) = NaN;
            expected(8:10, 2) = NaN;

            tc.verifyEqual(actual, expected);
        end

        function testSecondsZeroDoesNotExpand(tc)
            fs = 10;
            seconds = 0;

            signal = (1:20)';
            signal(10) = NaN;

            actual = expandnans(signal, fs, seconds);

            tc.verifyEqual(actual, signal);
        end

        function testInvalidInputs(tc)
            signal = (1:10)';

            tc.verifyError(@() expandnans(signal, 0, 0.1), 'MATLAB:InputParser:ArgumentFailedValidation');
            tc.verifyError(@() expandnans(signal, 10, -0.1), 'MATLAB:InputParser:ArgumentFailedValidation');
        end
    end
end
