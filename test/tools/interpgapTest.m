% interpgapTest.m - Test class for the interpgap function
% Tests covering:
%   - Basic functionality
%   - Optional interpolation method parameter

classdef interpgapTest < matlab.unittest.TestCase

    properties (TestParameter)
        caseId = getBiosiglibConformanceCaseIds('tools.interpgap')
    end

    methods (TestClassSetup)
        function addCodeToPath(tc)
            root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            originalPath = path;
            tc.addTeardown(@() path(originalPath));
            addpath(fullfile(root, 'src', 'tools'));
            addpath(fullfile(root, 'test', 'common'));
        end
    end

    methods (Test)
        function testBiosiglibConformanceCase(tc, caseId)
            caseDefinition = loadBiosiglibConformanceCase(caseId);
            x = loadBiosiglibConformanceInput(caseDefinition, 'signal');
            maxgap = loadBiosiglibConformanceInput(caseDefinition, 'max_gap');
            method = 'linear';
            if isfield(caseDefinition.parameters, 'method')
                method = caseDefinition.parameters.method;
            end
            actual = struct('interpolated_signal', interpgap(x, maxgap, method));
            verifyBiosiglibExpectedOutputs(tc, actual, caseDefinition);
        end

        function testIdentityPaths(tc)
            methods = {'linear', 'nearest', 'pchip', 'spline'};
            inputs = {[], zeros(1, 0), zeros(0, 1), [NaN, NaN], ...
                [1, 2], [NaN, 2, NaN]};
            for m = 1:numel(methods)
                for k = 1:numel(inputs)
                    tc.verifyEqual(interpgap(inputs{k}, 2, methods{m}), inputs{k});
                end
            end
            tc.verifyEqual(interpgap([0, NaN, 4], 0), [0, NaN, 4]);
        end

        function testOrientation(tc)
            tc.verifyEqual(interpgap([0, NaN, 4], 1), [0, 2, 4]);
            tc.verifyEqual(interpgap([0; NaN; 4], 1), [0; 2; 4]);
        end

        function testValidation(tc)
            inputs = {Inf, -Inf, [NaN, Inf, 2], [1i, 2], ones(2)};
            for k = 1:numel(inputs)
                tc.verifyError(@() interpgap(inputs{k}, 1), ...
                    'MATLAB:InputParser:ArgumentFailedValidation');
            end
            gaps = {-1, 1.5, Inf, NaN, 1i, [1, 2]};
            for k = 1:numel(gaps)
                tc.verifyError(@() interpgap([], gaps{k}), ...
                    'MATLAB:InputParser:ArgumentFailedValidation');
            end
            tc.verifyError(@() interpgap([], 1, 'invalid'), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
            tc.verifyEqual(interpgap([0, NaN, 4], 1, "linear"), [0, 2, 4]);
        end

        function testBasicFunctionality(tc)
            signal = [1, 2, NaN, 4, 5, NaN, NaN, 8, 9, 10]';
            maxgap = 1;

            expected = [1, 2, 3, 4, 5, NaN, NaN, 8, 9, 10]';

            actual = interpgap(signal, maxgap);

            % Verify results with tolerance
            tc.verifyEqual(actual, expected, 'AbsTol', 1e-10, ...
                'Basic functionality failed');
        end

        function testInterpolationMethod(tc)
            signal = [1, 3, 5, NaN, 9, 11, 13]';
            maxgap = 1;

            expectedLinear = [1, 3, 5, 7, 9, 11, 13]';

            resultSpline = interpgap(signal, maxgap, 'spline');
            tc.verifyEqual(resultSpline, expectedLinear, 'AbsTol', 1e-10, ...
                'Spline interpolation failed');

            resultsPchip = interpgap(signal, maxgap, 'pchip');
            tc.verifyEqual(resultsPchip, expectedLinear, 'AbsTol', 1e-10, ...
                'PCHIP interpolation failed');

            resultNearest = interpgap(signal, maxgap, 'nearest');
            expectedNearest = [1, 3, 5, 9, 9, 11, 13]';
            tc.verifyEqual(resultNearest, expectedNearest, 'AbsTol', 1e-10, ...
                'Nearest interpolation failed');
        end
    end

end
