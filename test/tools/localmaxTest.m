% Tests covering:
%   - Basic functionality with small known matrix
%   - Input parsing validation
%   - No local maxima case

classdef localmaxTest < matlab.unittest.TestCase

    methods (TestClassSetup)
        function addToPath(tc)
            tc.addTeardown(@() rmpath(fullfile(fileparts(mfilename('fullpath')), '..', '..', 'src', 'tools')));
            addpath(fullfile(fileparts(mfilename('fullpath')), '..', '..', 'src', 'tools'));
        end
    end

    methods (Test)

        function testBasicFunctionality(tc)
            X = [1, 3, 2, 5, 1; 2, 1, 4, 1, 3];
            [maxValue, maxLoc] = localmax(X, 2);

            tc.verifyEqual(maxValue, [5; 4]);
            tc.verifyEqual(maxLoc, [4; 3]);
        end

        function testNoLocalMaxima(tc)
            X = [1, 2, 3, 4, 5; 5, 4, 3, 2, 1];
            [maxValue, maxLoc] = localmax(X, 2);

            tc.verifyTrue(all(isnan(maxValue)));
            tc.verifyTrue(all(isnan(maxLoc)));
        end

        function testEmptyMatrix(tc)
            X = [];
            tc.verifyError(@() localmax(X, 2), 'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function testInvalidDimension(tc)
            X = [1, 2, 3];
            tc.verifyError(@() localmax(X, 3), 'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function testInvalidMinProminence(tc)
            X = [1, 2, 3];
            tc.verifyError(@() localmax(X, 2, 'MinProminence', -1), 'MATLAB:InputParser:ArgumentFailedValidation');
        end

    end

end
