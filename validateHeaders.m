function validateHeaders()
% VALIDATEHEADERS Validate header format for all functions in the source directory
%
% This function validates that all functions in the biosigmat toolbox follow
% the standard header format and code structure requirements per the
% biosigmat coding guidelines.
%
% Syntax:
%   validateHeaders()
%
% Output:
%   Console report showing compliance rate and detailed violations
%
% Example:
%   % Validate all functions automatically
%   validateHeaders();
%
% See also: updateDocs

% Automatic mode: validate all functions in src/ directory
fprintf('🔍 Starting automatic header validation for biosigmat toolbox...\n');
fprintf('📋 Validating against biosigmat coding guidelines...\n');

% Get toolbox root directory
toolboxRoot = fileparts(mfilename('fullpath'));
srcDir = fullfile(toolboxRoot, 'src');

% Get modules dynamically from src directory
srcContents = dir(srcDir);
srcContents = srcContents([srcContents.isdir] & ~startsWith({srcContents.name}, '.'));
modules = {srcContents.name};

fprintf('📚 Found %d modules: %s\n', length(modules), strjoin(modules, ', '));

fprintf('📂 Source directory: %s\n', srcDir);
fprintf('\n');

% Initialize validation results
validationResults = struct();
validationResults.compliant = {};
validationResults.violations = {};
totalFunctions = 0;
totalViolations = 0;

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
        headerValidation = validateSingleFunctionHeader(funcPath, funcName, module);

        if headerValidation.isCompliant
            validationResults.compliant{end+1} = headerValidation;
        else
            validationResults.violations{end+1} = headerValidation;
            totalViolations = totalViolations + 1;
        end
    end
end

% Report validation results
reportHeaderValidationResults(validationResults, totalFunctions, totalViolations);

end

function headerInfo = validateSingleFunctionHeader(filePath, functionName, module)
% Validate a single function header against the standard format

headerInfo = struct();
headerInfo.functionName = functionName;
headerInfo.module = module;
headerInfo.filePath = filePath;
headerInfo.isCompliant = true;
headerInfo.violations = {};

try
    % Read file content
    fileContent = fileread(filePath, 'Encoding', 'UTF-8');
    lines = splitlines(fileContent);

    % Find function declaration
    funcLineIdx = 0;
    for i = 1:length(lines)
        currentLine = lines{i};
        if contains(currentLine, 'function') && contains(currentLine, functionName)
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
    headerStartIdx = 0;

    for i = funcLineIdx+1:min(funcLineIdx+50, length(lines))
        currentLine = lines{i};
        line = strtrim(currentLine);
        if startsWith(line, '%')
            if headerStartIdx == 0
                headerStartIdx = i;
            end
            headerLines{end+1} = currentLine; %#ok<*AGROW>
        elseif ~isempty(line) && headerStartIdx > 0
            break; % End of header
        end
    end

    if isempty(headerLines)
        headerInfo.isCompliant = false;
        headerInfo.violations{end+1} = 'No header comments found';
        return;
    end

    % Validate header structure
    headerInfo = validateHeaderStructure(headerInfo, headerLines, functionName);
    headerInfo = validateRequiredSections(headerInfo, headerLines);
    headerInfo = validateCodeStructure(headerInfo, lines, funcLineIdx);

catch ME
    headerInfo.isCompliant = false;
    headerInfo.violations{end+1} = sprintf('Error reading file: %s', ME.message);
end

end

function headerInfo = validateHeaderStructure(headerInfo, headerLines, functionName)
% Validate the basic structure of the header (biosigmat toolbox style)

% Check first line format: % FUNCTIONNAME Brief description.
if ~isempty(headerLines)
    firstLine = headerLines{1};

    % Check exact format: "% FUNCTIONNAME Description."
    expectedStart = sprintf('%% %s ', upper(functionName));

    if ~startsWith(firstLine, expectedStart)
        headerInfo.isCompliant = false;
        headerInfo.violations{end+1} = sprintf('First line must start exactly with "%s"', expectedStart);
    else
        % Extract description part after function name
        descriptionPart = strtrim(firstLine(length(expectedStart)+1:end));

        % Check if description ends with period
        if ~endsWith(descriptionPart, '.')
            headerInfo.violations{end+1} = 'First line description must end with period';
        end

        % Check if there's actually a description
        if isempty(descriptionPart) || strcmp(descriptionPart, '.')
            headerInfo.violations{end+1} = 'Missing description in first line';
        end
    end

    % Check total length
    if length(firstLine) > 100
        headerInfo.violations{end+1} = 'First line too long (>100 characters)';
    end
else
    headerInfo.isCompliant = false;
    headerInfo.violations{end+1} = 'Missing header comments';
end

% Check for detailed syntax descriptions with exact indentation
hasDetailedSyntax = false;
syntaxCount = 0;
for i = 1:length(headerLines)
    line = headerLines{i};

    % Check for syntax lines: must start with "%   " (3 spaces) and contain function name with parentheses
    if startsWith(line, '%   ') && ~startsWith(line, '%    ')  % exactly 3 spaces
        cleanLine = strtrim(strrep(line, '%', ''));
        if contains(upper(cleanLine), upper(functionName)) && contains(cleanLine, '(') && contains(cleanLine, ')')
            hasDetailedSyntax = true;
            syntaxCount = syntaxCount + 1;
        end
    end
end

if ~hasDetailedSyntax
    headerInfo.violations{end+1} = 'Missing detailed syntax descriptions with proper indentation';
end

% Store syntax count for potential future validation
headerInfo.syntaxCount = syntaxCount;

end

function headerInfo = validateRequiredSections(headerInfo, headerLines)
% Validate required sections in header (biosigmat toolbox style)

foundSections = {};

% Check for Example section with exact format
hasExample = false;
for i = 1:length(headerLines)
    line = headerLines{i};

    % Must be exactly "Example:" with proper indentation
    if strcmp(line, '%   Example:') || strcmp(line, '%   Examples:')
        hasExample = true;
        foundSections{end+1} = 'Example';
        break;
    end
end

if ~hasExample
    headerInfo.isCompliant = false;
    headerInfo.violations{end+1} = 'Missing required section: "Example"';
end

% Check for See also section with exact format (optional - warning only)
hasSeeAlso = false;
for i = 1:length(headerLines)
    line = headerLines{i};

    % Must start with "%   See also" with proper indentation (case-sensitive)
    if startsWith(line, '%   See also')
        hasSeeAlso = true;
        foundSections{end+1} = 'See also';
        break;
    end
end

% Add warning for missing See also section (optional)
if ~hasSeeAlso
    if ~isfield(headerInfo, 'warnings')
        headerInfo.warnings = {};
    end
    headerInfo.warnings{end+1} = 'Missing optional section: "See also"';
end

% Store found sections for reporting
headerInfo.foundSections = foundSections;
headerInfo.hasSeeAlso = hasSeeAlso;

end

function headerInfo = validateCodeStructure(headerInfo, lines, funcLineIdx)
% Validate the code structure after header comments (biosigmat requirements)

% Find where header comments end
headerEndIdx = funcLineIdx;
for i = funcLineIdx+1:min(funcLineIdx+100, length(lines))
    currentLine = lines{i};
    line = strtrim(currentLine);
    if startsWith(line, '%')
        continue;
    elseif isempty(line)
        continue;
    else
        headerEndIdx = i - 1;
        break;
    end
end

% Check for required function structure elements after header
hasNarginchk = false;
hasNargoutchk = false;
hasInputParser = false;

% Look for these elements in the first 30 lines after header
for i = headerEndIdx+1:min(headerEndIdx+30, length(lines))
    currentLine = lines{i};
    line = strtrim(currentLine);

    if contains(line, 'narginchk')
        hasNarginchk = true;
    end
    if contains(line, 'nargoutchk')
        hasNargoutchk = true;
    end
    if contains(line, 'inputParser') || contains(line, 'parser = inputParser')
        hasInputParser = true;
    end
end

% Validate required structure elements per biosigmat guidelines
if ~hasNarginchk
    headerInfo.violations{end+1} = 'Missing narginchk() call - required per biosigmat guidelines';
end

if ~hasNargoutchk
    headerInfo.violations{end+1} = 'Missing nargoutchk() call - required per biosigmat guidelines';
end

% inputParser is strongly recommended but not always required
if ~hasInputParser
    headerInfo.violations{end+1} = 'Missing inputParser usage - recommended per biosigmat guidelines';
end

% Store structure validation results
headerInfo.hasNarginchk = hasNarginchk;
headerInfo.hasNargoutchk = hasNargoutchk;
headerInfo.hasInputParser = hasInputParser;

end

function reportHeaderValidationResults(validationResults, totalFunctions, totalViolations)
% Report header validation results to console

fprintf('\n📊 Biosigmat Header Validation Report\n');
fprintf('═══════════════════════════════════════\n');

complianceRate = (totalFunctions - totalViolations) / totalFunctions * 100;

fprintf('✅ Compliant functions: %d/%d (%.1f%%)\n', ...
    totalFunctions - totalViolations, totalFunctions, complianceRate);

if totalViolations > 0
    fprintf('❌ Functions with violations: %d\n\n', totalViolations);

    % Group violations by type for summary
    violationCounts = struct();

    for i = 1:length(validationResults.violations)
        violation = validationResults.violations{i};
        for j = 1:length(violation.violations)
            violationType = violation.violations{j};
            if ~isfield(violationCounts, 'types')
                violationCounts.types = {};
                violationCounts.counts = [];
            end

            % Find if this violation type already exists
            typeIdx = find(strcmp(violationCounts.types, violationType), 1);
            if isempty(typeIdx)
                violationCounts.types{end+1} = violationType;
                violationCounts.counts(end+1) = 1;
            else
                violationCounts.counts(typeIdx) = violationCounts.counts(typeIdx) + 1;
            end
        end
    end

    % Report detailed violations and warnings
    fprintf('📋 Detailed Function Report:\n');
    fprintf('════════════════════════════');

    % First show functions with violations
    for i = 1:length(validationResults.violations)
        violation = validationResults.violations{i};
        fprintf('\n📄 %s (%s module):\n', violation.functionName, violation.module);
        for j = 1:length(violation.violations)
            fprintf('  ❌ %s\n', violation.violations{j});
        end
        % Show warnings for this function if any
        if isfield(violation, 'warnings') && ~isempty(violation.warnings)
            for k = 1:length(violation.warnings)
                fprintf('  ⚠️  %s\n', violation.warnings{k});
            end
        end
    end

    % Then show compliant functions that have warnings
    if ~isempty(validationResults.compliant)
        for i = 1:length(validationResults.compliant)
            compliant = validationResults.compliant{i};
            if isfield(compliant, 'warnings') && ~isempty(compliant.warnings)
                fprintf('\n📄 %s (%s module):\n', compliant.functionName, compliant.module);
                for k = 1:length(compliant.warnings)
                    fprintf('  ⚠️  %s\n', compliant.warnings{k});
                end
            end
        end
    end
else
    fprintf('🎉 All function headers comply with biosigmat guidelines!\n');
end

end
