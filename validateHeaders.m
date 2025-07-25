function validateHeaders()
% VALIDATEHEADERS Validate header format for all functions in the source directory
%
% This function validates that all functions in the biosigmat toolbox follow
% the standard header format and code structure requirements.
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
    headerStartIdx = 0;

    for i = funcLineIdx+1:min(funcLineIdx+50, length(lines))
        line = strtrim(lines{i});
        if startsWith(line, '%')
            if headerStartIdx == 0
                headerStartIdx = i;
            end
            headerLines{end+1} = line; %#ok<*AGROW>
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
% Validate the basic structure of the header (MATLAB toolbox style)

% Check first line format: %FUNCTIONNAME Brief description.
if ~isempty(headerLines)
    firstLine = headerLines{1};
    cleanFirstLine = strtrim(strrep(firstLine, '%', ''));

    % Should start with FUNCTIONNAME in uppercase (no dash)
    expectedStart = functionName;
    words = strsplit(cleanFirstLine, ' ');

    if isempty(words) || ~strcmpi(words{1}, expectedStart)
        headerInfo.isCompliant = false;
        headerInfo.violations{end+1} = 'First line format incorrect';
    else
        % Check if description ends with period
        if ~endsWith(cleanFirstLine, '.')
            headerInfo.violations{end+1} = 'First line should end with period';
        end

        % Check if there's actually a description after function name
        if length(words) < 2
            headerInfo.violations{end+1} = 'Missing description in first line';
        end
    end

    % Check if description is too long
    if length(cleanFirstLine) > 80
        headerInfo.violations{end+1} = 'First line description too long (>80 characters)';
    end
else
    headerInfo.isCompliant = false;
    headerInfo.violations{end+1} = 'Missing header comments';
end

% Check for detailed syntax descriptions (should have multiple usage forms)
hasDetailedSyntax = false;
for i = 1:length(headerLines)
    cleanLine = strtrim(strrep(headerLines{i}, '%', ''));
    if contains(upper(cleanLine), upper(functionName)) && contains(cleanLine, '(') && contains(cleanLine, ')')
        hasDetailedSyntax = true;
        break;
    end
end

if ~hasDetailedSyntax
    headerInfo.violations{end+1} = 'Missing detailed syntax descriptions';
end

end

function headerInfo = validateRequiredSections(headerInfo, headerLines)
% Validate required sections in header (MATLAB toolbox style)

% MATLAB style doesn't require explicit "Inputs:" section
% Inputs are described within syntax descriptions
foundSections = {};

% Check for EXAMPLE section
hasExample = false;
for i = 1:length(headerLines)
    cleanLine = strtrim(strrep(headerLines{i}, '%', ''));

    if strcmpi(strtrim(cleanLine), 'EXAMPLE:') || ...
            strcmpi(strtrim(cleanLine), 'EXAMPLES:') || ...
            strcmpi(strtrim(cleanLine), 'Example:') || ...
            strcmpi(strtrim(cleanLine), 'Examples:') || ...
            (contains(upper(cleanLine), 'EXAMPLE') && endsWith(strtrim(cleanLine), ':'))
        hasExample = true;
        foundSections{end+1} = 'EXAMPLE:';
        break;
    end
end

if ~hasExample
    headerInfo.isCompliant = false;
    headerInfo.violations{end+1} = 'Missing required section: EXAMPLE';
end

% Check for See also section
hasSeeAlso = false;
for i = 1:length(headerLines)
    cleanLine = strtrim(strrep(headerLines{i}, '%', ''));
    if startsWith(upper(cleanLine), 'SEE ALSO')
        hasSeeAlso = true;
        break;
    end
end

% Store found sections for reporting
headerInfo.foundSections = foundSections;
if hasSeeAlso
    headerInfo.foundSections{end+1} = 'See also';
end

end

function headerInfo = validateCodeStructure(headerInfo, lines, funcLineIdx)
% Validate the code structure after header comments

% Find where header comments end
headerEndIdx = funcLineIdx;
for i = funcLineIdx+1:min(funcLineIdx+100, length(lines))
    line = strtrim(lines{i});
    if startsWith(line, '%')
        continue;
    elseif isempty(line)
        continue;
    else
        headerEndIdx = i - 1;
        break;
    end
end

% Check for narginchk and nargoutchk
hasNarginchk = false;
hasNargoutchk = false;

for i = headerEndIdx+1:min(headerEndIdx+20, length(lines))
    line = strtrim(lines{i});

    if contains(line, 'narginchk')
        hasNarginchk = true;
    end
    if contains(line, 'nargoutchk')
        hasNargoutchk = true;
    end
end

% Validate required structure elements
if ~hasNarginchk
    headerInfo.violations{end+1} = 'Missing narginchk() call';
end

if ~hasNargoutchk
    headerInfo.violations{end+1} = 'Missing nargoutchk() call';
end

end

function reportHeaderValidationResults(validationResults, totalFunctions, totalViolations)
% Report header validation results to console

fprintf('\n📊 Header Validation Report\n');
fprintf('═══════════════════════════\n');

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

    % Report detailed violations
    fprintf('\n📋 Functions with Header Violations:\n');
    fprintf('════════════════════════════════════');
    for i = 1:length(validationResults.violations)
        violation = validationResults.violations{i};
        fprintf('\n📄 %s (%s module):\n', violation.functionName, violation.module);
        for j = 1:length(violation.violations)
            fprintf('  ❌ %s\n', violation.violations{j});
        end
    end
else
    fprintf('🎉 All function headers are compliant!\n');
end

fprintf('\n');

end
