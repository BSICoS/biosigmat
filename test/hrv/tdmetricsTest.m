% Tests covering:
%   - Biosiglib conformance for tdmetrics

classdef tdmetricsTest < matlab.unittest.TestCase
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
        function testBasicFuntionality(tc)
            testDirectory = fileparts(mfilename('fullpath'));
            repositoryRoot = fileparts(fileparts(testDirectory));
            biosiglibRoot = getBiosiglibRoot();

            casePath = fullfile(biosiglibRoot, 'conformance', 'hrv', ...
                'tdmetrics', 'ecg_tk_001.json');
            caseDefinition = jsondecode(fileread(casePath));
            catalogPath = fullfile(biosiglibRoot, 'fixtures', 'catalog.json');
            fixtureCatalog = jsondecode(fileread(catalogPath));

            tc.assertEqual(caseDefinition.specification_id, 'hrv.tdmetrics', ...
                'The shared case must target hrv.tdmetrics.');

            manifest = jsondecode(fileread(fullfile(repositoryRoot, 'conformance.json')));
            specificationField = matlab.lang.makeValidName(caseDefinition.specification_id);
            tc.assertTrue(isfield(manifest.specifications, specificationField), ...
                sprintf('The Biosigmat manifest is missing specification "%s".', ...
                caseDefinition.specification_id));
            manifestEntry = manifest.specifications.(specificationField);
            tc.assertEqual(manifestEntry.entry_point, 'tdmetrics', ...
                'The Biosigmat manifest entry point for hrv.tdmetrics must be tdmetrics.');

            tc.assertEqual(numel(caseDefinition.inputs), 1, ...
                'The tdmetrics conformance case must define exactly one input.');
            inputDefinition = caseDefinition.inputs(1);

            fixtureIds = {fixtureCatalog.fixtures.id};
            fixtureIndex = find(strcmp(fixtureIds, inputDefinition.fixture_id), 1);
            tc.assertNotEmpty(fixtureIndex, sprintf( ...
                'Fixture "%s" referenced by the case was not found in fixtures/catalog.json.', ...
                inputDefinition.fixture_id));
            fixtureDefinition = fixtureCatalog.fixtures(fixtureIndex);

            fileRoles = {fixtureDefinition.files.role};
            fileIndex = find(strcmp(fileRoles, inputDefinition.file_role), 1);
            tc.assertNotEmpty(fileIndex, sprintf( ...
                'File role "%s" was not found for fixture "%s".', ...
                inputDefinition.file_role, inputDefinition.fixture_id));
            fixtureFile = fixtureDefinition.files(fileIndex);

            relativeCsvPath = strrep(fixtureFile.path, '/', filesep);
            csvPath = fullfile(biosiglibRoot, relativeCsvPath);
            tc.assertTrue(isfile(csvPath), sprintf( ...
                'Fixture CSV for role "%s" does not exist: %s', ...
                inputDefinition.file_role, csvPath));
            fixtureTable = readtable(csvPath, 'VariableNamingRule', 'preserve');

            inputColumn = inputDefinition.column;
            tc.assertTrue(ismember(inputColumn, fixtureTable.Properties.VariableNames), ...
                sprintf('Input column "%s" was not found in fixture CSV %s.', ...
                inputColumn, csvPath));
            dtk = fixtureTable.(inputColumn);
            tc.assertTrue(isnan(dtk(1)), ...
                'The shared dtk input must retain its leading NaN value.');

            metrics = tdmetrics(dtk);

            for outputIndex = 1:numel(caseDefinition.expected_outputs)
                expectedOutput = caseDefinition.expected_outputs(outputIndex);
                outputId = expectedOutput.id;
                switch outputId
                    case {'mhr', 'sdnn', 'sdsd', 'rmssd'}
                        matlabField = outputId;
                    case 'pnn50'
                        matlabField = 'pNN50';
                    otherwise
                        tc.assertFail(sprintf('Unknown expected output ID "%s".', outputId));
                end

                tc.assertTrue(isfield(metrics, matlabField), sprintf( ...
                    'MATLAB output field "%s" is missing for expected output ID "%s".', ...
                    matlabField, outputId));

                actualValue = metrics.(matlabField);
                expectedValue = expectedOutput.value;
                tolerance = expectedOutput.absolute_tolerance;
                if ischar(expectedValue)
                    tc.assertEqual(expectedValue, 'NaN', sprintf( ...
                        'Unsupported exact string value "%s" for output ID "%s".', ...
                        expectedValue, outputId));
                    diagnostic = sprintf( ...
                        'Output "%s" mismatch: expected NaN, actual %.17g, absolute tolerance %.17g.', ...
                        outputId, actualValue, tolerance);
                    tc.verifyTrue(caseDefinition.nan_equal && isnan(actualValue), diagnostic);
                else
                    diagnostic = sprintf( ...
                        'Output "%s" mismatch: expected %.17g, actual %.17g, absolute tolerance %.17g.', ...
                        outputId, expectedValue, actualValue, tolerance);
                    tc.verifyEqual(actualValue, expectedValue, 'AbsTol', tolerance, diagnostic);
                end
            end
        end
    end
end
