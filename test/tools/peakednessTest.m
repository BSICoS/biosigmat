% Tests covering:
%   - Basic functionality with vector input
%   - Matrix input handling
%   - Invalid input handling
%   - Parameter validation

classdef peakednessTest < matlab.unittest.TestCase

    properties (TestParameter)
        caseId = getBiosiglibConformanceCaseIds('tools.peakedness')
    end

    properties
        resp
        fs
    end

    methods (TestClassSetup)
        function addCodeToPath(~)
            addpath('../../src/tools');
        end
    end

    methods (TestMethodSetup)
        function loadFixtures(tc)
            data = readmatrix('../../fixtures/ecg/medicom_mtd_ecg_respiration.csv');
            tc.resp = detrend(data(2:end, 3));
            tc.fs = 256;
        end
    end

    methods (Test)
        function testConformance(tc, caseId)
            c = loadBiosiglibConformanceCase(caseId);
            pxx = decodeLiteral(loadBiosiglibConformanceInput(c, 'pxx'));
            f = loadBiosiglibConformanceInput(c, 'f');
            reference = [];
            window = 0.125;
            if isfield(c.parameters, 'reference_freq'), reference = c.parameters.reference_freq; end
            if isfield(c.parameters, 'window'), window = c.parameters.window; end
            if isfield(c, 'expected_error')
                tc.verifyError(@() peakedness(pxx, f, reference, window), ...
                    'MATLAB:InputParser:ArgumentFailedValidation');
                return;
            end
            [pkl, akl] = peakedness(pxx, f, reference, window);
            verifyBiosiglibExpectedOutputs(tc, struct('pkl', pkl, 'akl', akl), c);
        end

        function testSpectrumAndFrequencyValidation(tc)
            invalidSpectra = {[1; Inf; 2], [1; -1; 2], [1; 1i; 2]};
            for k = 1:numel(invalidSpectra)
                tc.verifyError(@() peakedness(invalidSpectra{k}, [0; 1; 2]), ...
                    'MATLAB:InputParser:ArgumentFailedValidation');
            end
            invalidFrequencies = {[0; 1; 1], [0; 2; 1], [0; NaN; 2], [0; Inf; 2]};
            for k = 1:numel(invalidFrequencies)
                tc.verifyError(@() peakedness([1; 3; 1], invalidFrequencies{k}), ...
                    'MATLAB:InputParser:ArgumentFailedValidation');
            end
            tc.verifyError(@() peakedness([1; 3; 1], [0; 1; 2], [], Inf), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function testVectorOrientationAndIntegerInput(tc)
            [pkl, akl] = peakedness([1; 3; 1], [0; 1; 2], [], 4);
            [rowPkl, rowAkl] = peakedness([1, 3, 1], [0, 1, 2], [], 4);
            [integerPkl, integerAkl] = peakedness(uint8([1; 3; 1]), [0; 1; 2], [], 4);
            tc.verifyEqual([rowPkl, rowAkl], [pkl, akl]);
            tc.verifyEqual([integerPkl, integerAkl], [pkl, akl]);
        end

        function testVectorInput(tc)
            [pxx, f] = periodogram(tc.resp, [], [], tc.fs);
            [pkl, akl] = peakedness(pxx, f);

            % Verify outputs are valid
            tc.verifyTrue(isnumeric(pkl), 'pkl should be numeric');
            tc.verifyTrue(isnumeric(akl), 'akl should be numeric');
            tc.verifyEqual(length(pkl), 1, 'pkl should have one value for single spectrum');
            tc.verifyEqual(length(akl), 1, 'akl should have one value for single spectrum');

            % Verify peakedness values are within expected range
            tc.verifyGreaterThanOrEqual(pkl, 0, 'pkl should be non-negative');
            tc.verifyLessThanOrEqual(pkl, 100, 'pkl should be <= 100%');
            tc.verifyGreaterThanOrEqual(akl, 0, 'akl should be non-negative');
            tc.verifyLessThanOrEqual(akl, 100, 'akl should be <= 100%');
        end

        function testMatrixInput(tc)
            sliced = slicesignal(tc.resp, tc.fs*30, tc.fs*15, tc.fs);
            [pxx, f] = periodogram(sliced, [], [], tc.fs);
            [pkl, akl] = peakedness(pxx, f);

            % Verify outputs are valid
            tc.verifyTrue(isnumeric(pkl), 'pkl should be numeric');
            tc.verifyTrue(isnumeric(akl), 'akl should be numeric');
            tc.verifyEqual(length(pkl), size(pxx, 2), 'pkl should match number of spectra');
            tc.verifyEqual(length(akl), size(pxx, 2), 'akl should match number of spectra');

            % Verify peakedness values are within expected range
            tc.verifyGreaterThanOrEqual(pkl, 0, 'pkl should be non-negative');
            tc.verifyLessThanOrEqual(pkl, 100, 'pkl should be <= 100%');
            tc.verifyGreaterThanOrEqual(akl, 0, 'akl should be non-negative');
            tc.verifyLessThanOrEqual(akl, 100, 'akl should be <= 100%');
        end

        function testInvalidInputs(tc)
            % Test with empty pxx input
            tc.verifyError(@() peakedness([], [1, 2, 3], 0.3), 'MATLAB:InputParser:ArgumentFailedValidation');

            % Test with empty f input
            tc.verifyError(@() peakedness([1, 2, 3], [], 0.3), 'MATLAB:InputParser:ArgumentFailedValidation');

            % Test with mismatched dimensions
            pxx = rand(100, 2);
            f = (1:50)';  % Different length than pxx rows
            tc.verifyError(@() peakedness(pxx, f, 0.3), 'peakedness:DimensionMismatch');

            % Test with invalid referenceFreq (NaN)
            pxx = rand(100, 1);
            f = (1:100)';
            tc.verifyError(@() peakedness(pxx, f, NaN), 'MATLAB:InputParser:ArgumentFailedValidation');

            % Test with invalid referenceFreq (Inf)
            tc.verifyError(@() peakedness(pxx, f, Inf), 'MATLAB:InputParser:ArgumentFailedValidation');

            % An empty reference selects the adaptive method.
            tc.verifyWarningFree(@() peakedness(pxx, f, []));

            % Test with invalid window size (negative)
            tc.verifyError(@() peakedness(pxx, f, 0.3, -0.1), 'MATLAB:InputParser:ArgumentFailedValidation');

            % Test with NaN values in pxx
            pxx = NaN(100, 1);
            f = (1:100)';
            tc.verifyError(@() peakedness(pxx, f, 0.3), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function testParameterValidation(tc)
            % Test with valid parameters
            [pxx, f] = periodogram(tc.resp, [], [], tc.fs);

            % Test with custom reference frequency
            referenceFreq = 0.3;  % Example reference frequency
            [pkl, akl] = peakedness(pxx, f, referenceFreq);
            tc.verifyTrue(isnumeric(pkl), 'pkl should be numeric with custom reference frequency');
            tc.verifyTrue(isnumeric(akl), 'akl should be numeric with custom reference frequency');

            % Test with custom window size
            [pkl, akl] = peakedness(pxx, f, 0.3, 0.2);
            tc.verifyTrue(isnumeric(pkl), 'pkl should be numeric with custom window');
            tc.verifyTrue(isnumeric(akl), 'akl should be numeric with custom window');
        end
    end

end

function values = decodeLiteral(values)
% Decode numerical JSON literals that contain NaN markers.
if iscell(values)
    decoded = cellfun(@decodeLiteral, values, 'UniformOutput', false);
    if all(cellfun(@isscalar, decoded))
        values = cell2mat(decoded);
    else
        values = cell2mat(cellfun(@(row) row(:).', decoded, ...
            'UniformOutput', false));
    end
elseif ischar(values) || isstring(values)
    values = str2double(values);
end
end
