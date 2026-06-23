% Tests covering:
%   - Biosiglib conformance for tdmetrics

classdef tdmetricsTest < matlab.unittest.TestCase
    properties (TestParameter)
        expectedErrorCaseId = {
            'hrv.tdmetrics.invalid_tk_non_numeric'
            'hrv.tdmetrics.invalid_tk_matrix'
            'hrv.tdmetrics.invalid_tk_non_monotonic'
            'hrv.tdmetrics.invalid_tk_repeated'
            'hrv.tdmetrics.invalid_tk_negative'
        }
    end

    methods (TestClassSetup)
        function addCodeToPath(tc)
            testDirectory = fileparts(mfilename('fullpath'));
            repositoryRoot = fileparts(fileparts(testDirectory));
            originalPath = path;
            tc.addTeardown(@() path(originalPath));
            addpath(fullfile(repositoryRoot, 'src', 'hrv'));
            addpath(fullfile(repositoryRoot, 'test', 'common'));
        end
    end

    methods (Test)
        function testBasicFunctionality(tc)
            caseDefinition = loadBiosiglibConformanceCase( ...
                'hrv.tdmetrics.ecg_tk_001');
            tk = loadBiosiglibConformanceInput(caseDefinition, 'tk');
            dtk = diff(tk);

            metrics = tdmetrics(dtk);

            outputIdMap = containers.Map({'pnn50'}, {'pNN50'});
            verifyBiosiglibExpectedOutputs(tc, metrics, caseDefinition, outputIdMap);
        end

        function testExpectedError(tc, expectedErrorCaseId)
            caseDefinition = loadBiosiglibConformanceCase(expectedErrorCaseId);
            tk = loadBiosiglibConformanceInput(caseDefinition, 'tk');

            verifyBiosiglibExpectedError(tc, ...
                @() tdmetricsFromCanonicalTk(tk), caseDefinition);
        end
    end
end

function metrics = tdmetricsFromCanonicalTk(tk)
%TDMETRICSFROMCANONICALTK Adapt canonical event times to interval input.

if ~isnumeric(tk)
    error('biosigmat:TdmetricsInvalidCanonicalType', ...
        'Canonical tk input must be numeric.');
end
if ~isvector(tk)
    error('biosigmat:TdmetricsInvalidCanonicalShape', ...
        'Canonical tk input must be a vector.');
end
if any(~isfinite(tk)) || any(tk < 0) || any(diff(tk) <= 0)
    error('biosigmat:TdmetricsInvalidCanonicalValue', ...
        'Canonical tk input must be finite, non-negative, and strictly increasing.');
end

metrics = tdmetrics(diff(tk));
end
