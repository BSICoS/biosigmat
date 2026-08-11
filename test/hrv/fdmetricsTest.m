% Tests covering:
%   - Shared hrv.fdmetrics conformance cases and normative warnings
%   - Conventional LF/HF metrics with limited and unlimited HF bands
%   - OSP-based unrelated and respiration-related metrics
%   - Retained OSP threshold behavior

classdef fdmetricsTest < matlab.unittest.TestCase

    properties (TestParameter)
        caseId = getBiosiglibConformanceCaseIds('hrv.fdmetrics')
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
        function testBiosiglibConformanceCase(tc, caseId)
            caseDefinition = loadBiosiglibConformanceCase(caseId);

            warningIdMap = containers.Map( ...
                {'excessive_vlf_power', 'zero_required_power'}, ...
                {'biosigmat:fdmetrics:excessive_vlf_power', ...
                'biosigmat:fdmetrics:zero_required_power'});
            verifyBiosiglibExpectedWarnings(tc, ...
                @() executeBiosiglibFdmetricsCase(caseDefinition), ...
                caseDefinition, warningIdMap);
            warningState = warning;
            restoreWarnings = onCleanup(@() warning(warningState)); %#ok<NASGU>
            warning('off', 'biosigmat:fdmetrics:excessive_vlf_power');
            warning('off', 'biosigmat:fdmetrics:zero_required_power');
            outputs = executeBiosiglibFdmetricsCase(caseDefinition);
            verifyBiosiglibExpectedOutputs(tc, outputs, caseDefinition);
        end

        function testClassicBandsUseLimitedHighFrequencyWindowByDefault(tc)
            f = (0.04:0.01:0.5)';
            pxx = ones(size(f));

            metrics = fdmetrics(pxx, f);

            tc.verifyEqual(metrics.lf, 0.11, 'AbsTol', 1e-12, ...
                'LF power should integrate the 0.04 Hz to 0.15 Hz band.');
            tc.verifyEqual(metrics.hf, 0.25, 'AbsTol', 1e-12, ...
                'HF power should integrate the 0.15 Hz to 0.4 Hz band.');
            tc.verifyEqual(metrics.lfn, 0.11 / 0.36, 'AbsTol', 1e-12, ...
                'Normalized LF power should use LF divided by LF plus HF.');
            tc.verifyEqual(metrics.lfhf, 0.11 / 0.25, 'AbsTol', 1e-12, ...
                'LF/HF should equal LF divided by HF.');
            tc.verifyFalse(isfield(metrics, 'urlf'), ...
                'Single-spectrum mode should not expose OSP-only metrics.');
            tc.verifyFalse(isfield(metrics, 're'), ...
                'Single-spectrum mode should not expose OSP-only metrics.');
            tc.verifyFalse(isfield(metrics, 'r'), ...
                'Single-spectrum mode should not expose OSP-only metrics.');
            tc.verifyFalse(isfield(metrics, 'respPeak'), ...
                'fdmetrics should not expose the respPeak field used by freqind.');
        end

        function testLogicalThirdInputUnlimitsHighFrequencyWindow(tc)
            f = (0.04:0.01:0.5)';
            pxx = ones(size(f));

            metrics = fdmetrics(pxx, f, false);

            tc.verifyEqual(metrics.lf, 0.11, 'AbsTol', 1e-12, ...
                'LF power should remain on the conventional band when HF is unlimited.');
            tc.verifyEqual(metrics.hf, 0.35, 'AbsTol', 1e-12, ...
                'HF power should expand to the highest frequency available in F.');
        end

        function testOspModeReturnsOnlySeparatedMetrics(tc)
            f = (0.04:0.01:0.4)';
            respPxx = 0.01 * ones(size(f));
            unrelatedPxx = 0.001 * ones(size(f));

            metrics = fdmetrics(respPxx, unrelatedPxx, f);

            tc.verifyEqual(metrics.re, 0.0036, 'AbsTol', 1e-12, ...
                'Re should integrate the respiration-related spectrum over the full band.');
            tc.verifyEqual(metrics.urlf, 0.00011, 'AbsTol', 1e-12, ...
                'UrLF should integrate the unrelated spectrum over the LF band.');
            tc.verifyEqual(metrics.r, 0.00011 / 0.00371, 'AbsTol', 1e-12, ...
                'R should compare unrelated LF power with the total separated power.');
            tc.verifyFalse(isfield(metrics, 'hf'), ...
                'Two-spectrum mode should not expose single-spectrum LF/HF metrics.');
            tc.verifyFalse(isfield(metrics, 'lf'), ...
                'Two-spectrum mode should not expose single-spectrum LF/HF metrics.');
            tc.verifyFalse(isfield(metrics, 'lfn'), ...
                'Two-spectrum mode should not expose single-spectrum LF/HF metrics.');
            tc.verifyFalse(isfield(metrics, 'lfhf'), ...
                'Two-spectrum mode should not expose single-spectrum LF/HF metrics.');
        end

        function testOspThresholdsReturnNan(tc)
            f = (0.04:0.01:0.4)';
            respPxx = 0.2 * ones(size(f));
            unrelatedPxx = 0.1 * ones(size(f));

            metrics = fdmetrics(respPxx, unrelatedPxx, f);

            tc.verifyTrue(isnan(metrics.re), ...
                'Re should be NaN when it exceeds the freqind maximum allowed value.');
            tc.verifyTrue(isnan(metrics.urlf), ...
                'UrLF should be NaN when it exceeds the freqind maximum allowed value.');
            tc.verifyTrue(isnan(metrics.r), ...
                'R should become NaN when Re or UrLF are rejected.');
        end
    end
end

function metrics = executeBiosiglibFdmetricsCase(caseDefinition)
f = loadBiosiglibConformanceInput(caseDefinition, 'f');
if hasBiosiglibConformanceInput(caseDefinition, 'pxx')
    pxx = loadBiosiglibConformanceInput(caseDefinition, 'pxx');
    if isfield(caseDefinition.parameters, 'limit_hf')
        metrics = fdmetrics(pxx, f, caseDefinition.parameters.limit_hf);
    else
        metrics = fdmetrics(pxx, f);
    end
else
    relatedPxx = loadBiosiglibConformanceInput( ...
        caseDefinition, 'related_pxx');
    unrelatedPxx = loadBiosiglibConformanceInput( ...
        caseDefinition, 'unrelated_pxx');
    metrics = fdmetrics(relatedPxx, unrelatedPxx, f);
end
end

function tf = hasBiosiglibConformanceInput(caseDefinition, inputId)
try
    getBiosiglibConformanceInput(caseDefinition, inputId);
    tf = true;
catch exception
    if strcmp(exception.identifier, 'biosigmat:ConformanceInputNotFound')
        tf = false;
    else
        rethrow(exception);
    end
end
end
