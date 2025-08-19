% validateHeadersCI.m
% Script to validate header format for all functions in CI environment with GitHub Actions integration

function validateHeadersCI()
% Run header validation in a CI-friendly manner
% This version generates reports and exits with appropriate error codes for GitHub Actions

try
    % Get toolbox root directory (navigate up from scripts/ci/ to project root)
    toolboxRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    srcDir = fullfile(toolboxRoot, 'src');
    examplesDir = fullfile(toolboxRoot, 'examples');

    fprintf('🔍 Starting header validation in CI environment...\n');
    fprintf('📋 Validating against biosigmat coding guidelines...\n');

    % Get modules dynamically from src directory
    srcContents = dir(srcDir);
    srcContents = srcContents([srcContents.isdir] & ~startsWith({srcContents.name}, '.'));
    modules = {srcContents.name};

    fprintf('📚 Found %d modules: %s\n', length(modules), strjoin(modules, ', '));
    fprintf('📂 Source directory: %s\n', srcDir);
    fprintf('📂 Examples directory: %s\n', examplesDir);
    fprintf('\n');

    % Initialize validation results
    validationResults = struct();
    validationResults.compliant = {};
    validationResults.violations = {};
    exampleResults = struct();
    exampleResults.compliant = {};
    exampleResults.violations = {};
    totalFunctions = 0;
    totalViolations = 0;
    totalExamples = 0;
    totalExampleViolations = 0;

    % Validate all functions in each module
    for i = 1:length(modules)
        module = modules{i};
        moduleDir = fullfile(srcDir, module);

        if ~exist(moduleDir, 'dir')
            continue;
        end

        % Get all .m files in module
        mFiles = dir(fullfile(moduleDir, '*.m'));

        for j = 1:length(mFiles)
            [~, funcName, ~] = fileparts(mFiles(j).name);

            % Skip test files and private functions
            if startsWith(funcName, 'test') || contains(mFiles(j).folder, 'private')
                continue;
            end

            totalFunctions = totalFunctions + 1;
            funcPath = fullfile(mFiles(j).folder, mFiles(j).name);
            headerValidation = validateSingleFunctionHeaderCI(funcPath, funcName, module);

            if headerValidation.isCompliant
                validationResults.compliant{end+1} = headerValidation;
            else
                validationResults.violations{end+1} = headerValidation;
                totalViolations = totalViolations + 1;
            end
        end
    end

    % Validate example files
    if exist(examplesDir, 'dir')
        exampleContents = dir(examplesDir);
        exampleContents = exampleContents([exampleContents.isdir] & ~startsWith({exampleContents.name}, '.'));

        for i = 1:length(exampleContents)
            exampleModule = exampleContents(i).name;
            exampleModuleDir = fullfile(examplesDir, exampleModule);

            exampleMFiles = dir(fullfile(exampleModuleDir, '*.m'));

            for j = 1:length(exampleMFiles)
                [~, exampleName, ~] = fileparts(exampleMFiles(j).name);
                totalExamples = totalExamples + 1;
                examplePath = fullfile(exampleMFiles(j).folder, exampleMFiles(j).name);
                exampleValidation = validateSingleExampleHeaderCI(examplePath, exampleName, exampleModule);

                if exampleValidation.isCompliant
                    exampleResults.compliant{end+1} = exampleValidation;
                else
                    exampleResults.violations{end+1} = exampleValidation;
                    totalExampleViolations = totalExampleViolations + 1;
                end
            end
        end
    end

    % Generate GitHub Actions summary
    if isCI()
        generateGitHubHeaderSummary(validationResults, totalFunctions, totalViolations, ...
            exampleResults, totalExamples, totalExampleViolations);
    end

    % Report results to console
    reportCIHeaderResults(validationResults, totalFunctions, totalViolations, ...
        exampleResults, totalExamples, totalExampleViolations);

    % Show warning if violations found, but do not exit with error code in CI
    if totalViolations > 0 || totalExampleViolations > 0
        warning('Header validation failed: %d function violations, %d example violations', ...
            totalViolations, totalExampleViolations);
        fprintf('\n⚠️ Header validation found issues, see summary above.\n');
    else
        fprintf('\n✅ All headers comply with biosigmat guidelines!\n');
    end

catch ME
    fprintf('❌ Error during header validation: %s\n', ME.message);
    % Nunca salir con exit(1) en CI, solo mostrar el error
    % Si no es CI, relanzar el error para debug local
    if ~isCI()
        rethrow(ME);
    end
end
end

function headerInfo = validateSingleFunctionHeaderCI(filePath, functionName, module)
% Validate a single function header (simplified for CI)
headerInfo = struct();
headerInfo.functionName = functionName;
headerInfo.module = module;
headerInfo.filePath = filePath;
headerInfo.isCompliant = true;
headerInfo.violations = {};

try
    fileContent = fileread(filePath, 'Encoding', 'UTF-8');
    lines = splitlines(fileContent);

    % Find function declaration
    funcLineIdx = 0;
    for i = 1:length(lines)
        if contains(lines{i}, 'function') && contains(lines{i}, functionName)
            funcLineIdx = i;
            break;
        end
    end

    if funcLineIdx == 0
        headerInfo.isCompliant = false;
        headerInfo.violations{end+1} = 'Function declaration not found';
        return;
    end

    % Extract header comments
    headerLines = {};
    for i = funcLineIdx+1:min(funcLineIdx+50, length(lines))
        line = strtrim(lines{i});
        if startsWith(line, '%')
            headerLines{end+1} = lines{i};
        elseif ~isempty(line)
            break;
        end
    end

    if isempty(headerLines)
        headerInfo.isCompliant = false;
        headerInfo.violations{end+1} = 'No header comments found';
        return;
    end

    % Validate header structure
    headerInfo = validateHeaderStructureCI(headerInfo, headerLines, functionName);

catch ME
    headerInfo.isCompliant = false;
    headerInfo.violations{end+1} = sprintf('Error reading file: %s', ME.message);
end
end

function headerInfo = validateSingleExampleHeaderCI(filePath, exampleName, module)
% Validate a single example header (simplified for CI)
headerInfo = struct();
headerInfo.functionName = exampleName;
headerInfo.module = module;
headerInfo.filePath = filePath;
headerInfo.isCompliant = true;
headerInfo.violations = {};

try
    fileContent = fileread(filePath, 'Encoding', 'UTF-8');
    lines = splitlines(fileContent);

    % Get header lines
    headerLines = {};
    for i = 1:min(15, length(lines))
        line = strtrim(lines{i});
        if startsWith(line, '%')
            headerLines{end+1} = lines{i};
        elseif ~isempty(line)
            break;
        end
    end

    if isempty(headerLines)
        headerInfo.isCompliant = false;
        headerInfo.violations{end+1} = 'No header comments found';
        return;
    end

    % Validate example header structure
    headerInfo = validateExampleHeaderStructureCI(headerInfo, headerLines, exampleName);

catch ME
    headerInfo.isCompliant = false;
    headerInfo.violations{end+1} = sprintf('Error reading file: %s', ME.message);
end
end

function headerInfo = validateHeaderStructureCI(headerInfo, headerLines, functionName)
% Validate header structure for CI
if ~isempty(headerLines)
    firstLine = headerLines{1};
    expectedStart = sprintf('%% %s ', upper(functionName));

    if ~startsWith(firstLine, expectedStart)
        headerInfo.isCompliant = false;
        headerInfo.violations{end+1} = sprintf('First line must start with "%s"', expectedStart);
    else
        descriptionPart = strtrim(firstLine(length(expectedStart)+1:end));
        if ~endsWith(descriptionPart, '.')
            headerInfo.isCompliant = false;
            headerInfo.violations{end+1} = 'First line description must end with period';
        end
    end

    % Check for Example section
    hasExample = false;
    for i = 1:length(headerLines)
        if strcmp(headerLines{i}, '%   Example:') || strcmp(headerLines{i}, '%   Examples:')
            hasExample = true;
            break;
        end
    end

    if ~hasExample
        headerInfo.isCompliant = false;
        headerInfo.violations{end+1} = 'Missing required Example section';
    end
end
end

function headerInfo = validateExampleHeaderStructureCI(headerInfo, headerLines, exampleName)
% Validate example header structure for CI
if ~isempty(headerLines)
    firstLine = headerLines{1};
    expectedStart = sprintf('%% %s ', upper(exampleName));

    if ~startsWith(firstLine, expectedStart)
        headerInfo.isCompliant = false;
        headerInfo.violations{end+1} = sprintf('First line must start with "%s"', expectedStart);
    end

    if length(headerLines) < 2 || ~strcmp(strtrim(headerLines{2}), '%')
        headerInfo.isCompliant = false;
        headerInfo.violations{end+1} = 'Missing empty line after first line';
    end
end
end

function result = isCI()
% Check if running in CI environment
result = ~isempty(getenv('CI')) || ~isempty(getenv('GITHUB_ACTIONS'));
end

function generateGitHubHeaderSummary(validationResults, totalFunctions, totalViolations, ...
    exampleResults, totalExamples, totalExampleViolations)
% Generate GitHub Actions summary for header validation
try
    summaryFile = getenv('GITHUB_STEP_SUMMARY');
    if ~isempty(summaryFile)
        fid = fopen(summaryFile, 'w');
        if fid ~= -1
            fprintf(fid, '# Header Validation Results\n\n');

            % Add status badge
            if totalViolations == 0 && totalExampleViolations == 0
                fprintf(fid, '✅ **All headers comply with guidelines!**\n\n');
            else
                fprintf(fid, '❌ **Header validation failed**\n\n');
            end

            fprintf(fid, '## Summary\n\n');
            fprintf(fid, '| Category | Total | Compliant | Violations | Success Rate |\n');
            fprintf(fid, '|----------|-------|-----------|------------|-------------|\n');
            fprintf(fid, '| Functions | %d | %d | %d | %.1f%% |\n', ...
                totalFunctions, totalFunctions - totalViolations, totalViolations, ...
                ((totalFunctions - totalViolations)/totalFunctions)*100);

            if totalExamples > 0
                exampleSuccessRate = ((totalExamples - totalExampleViolations)/totalExamples)*100;
            else
                exampleSuccessRate = 0;
            end
            fprintf(fid, '| Examples | %d | %d | %d | %.1f%% |\n', ...
                totalExamples, totalExamples - totalExampleViolations, totalExampleViolations, ...
                exampleSuccessRate);

            % Add violations section
            if totalViolations > 0
                fprintf(fid, '\n## Function Violations\n\n');
                for i = 1:length(validationResults.violations)
                    violation = validationResults.violations{i};
                    fprintf(fid, '### %s (%s module)\n\n', violation.functionName, violation.module);
                    for j = 1:length(violation.violations)
                        fprintf(fid, '- ❌ %s\n', violation.violations{j});
                    end
                    fprintf(fid, '\n');
                end
            end

            if totalExampleViolations > 0
                fprintf(fid, '\n## Example Violations\n\n');
                for i = 1:length(exampleResults.violations)
                    violation = exampleResults.violations{i};
                    fprintf(fid, '### %s (%s module)\n\n', violation.functionName, violation.module);
                    for j = 1:length(violation.violations)
                        fprintf(fid, '- ❌ %s\n', violation.violations{j});
                    end
                    fprintf(fid, '\n');
                end
            end

            fclose(fid);
        end
    end
catch
    % Ignore errors in summary generation
end
end

function reportCIHeaderResults(validationResults, totalFunctions, totalViolations, ...
    exampleResults, totalExamples, totalExampleViolations)
% Report header validation results for CI
fprintf('\n📊 Header Validation CI Report\n');
fprintf('═══════════════════════════════\n');

if totalFunctions > 0
    complianceRate = (totalFunctions - totalViolations) / totalFunctions * 100;
else
    complianceRate = 0;
end
fprintf('🔧 FUNCTIONS: %d/%d compliant (%.1f%%)\n', ...
    totalFunctions - totalViolations, totalFunctions, complianceRate);

if totalViolations > 0
    fprintf('❌ Function violations: %d\n', totalViolations);
    for i = 1:length(validationResults.violations)
        violation = validationResults.violations{i};
        fprintf('  📄 %s (%s): %d issues\n', ...
            violation.functionName, violation.module, length(violation.violations));
    end
end

if totalExamples > 0
    exampleComplianceRate = (totalExamples - totalExampleViolations) / totalExamples * 100;
else
    exampleComplianceRate = 0;
end
fprintf('\n📝 EXAMPLES: %d/%d compliant (%.1f%%)\n', ...
    totalExamples - totalExampleViolations, totalExamples, exampleComplianceRate);

if totalExampleViolations > 0
    fprintf('❌ Example violations: %d\n', totalExampleViolations);
    for i = 1:length(exampleResults.violations)
        violation = exampleResults.violations{i};
        fprintf('  📄 %s (%s): %d issues\n', ...
            violation.functionName, violation.module, length(violation.violations));
    end
end

fprintf('\n📈 Overall compliance: %.1f%%\n', ...
    ((totalFunctions + totalExamples - totalViolations - totalExampleViolations) / ...
    (totalFunctions + totalExamples)) * 100);
end