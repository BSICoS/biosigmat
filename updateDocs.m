function updateDocs()
% UPDATEDOCS - Generate and update toolbox documentation automatically
%
% This script scans the source code and automatically generates/updates
% documentation files in the docs/ directory.
%
% Usage:
%   updateDocs()           % Update all documentation
%   updateDocs('module')   % Update specific module (e.g. 'ecg', 'ppg')
%
% The script performs the following tasks:
% 1. Scans all .m files in src/ directory
% 2. Extracts function headers and documentation
% 3. Generates/updates corresponding .md files
% 4. Updates API index files
% 5. Validates internal links

fprintf('🔄 Starting documentation update...\n');

try
    % Get toolbox root directory
    toolboxRoot = fileparts(mfilename('fullpath'));
    srcDir = fullfile(toolboxRoot, 'src');
    docsDir = fullfile(toolboxRoot, 'docs');

    % Ensure docs directory exists
    if ~exist(docsDir, 'dir')
        mkdir(docsDir);
        fprintf('📁 Created docs directory\n');
    end

    % Update API documentation for each module
    modules = {'ecg', 'ppg', 'hrv', 'tools'};

    for i = 1:length(modules)
        module = modules{i};
        fprintf('📚 Processing %s module...\n', module);
        updateModuleDocs(srcDir, docsDir, module);
    end

    % Validate header formats for all functions
    fprintf('🔍 Validating function header formats...\n');
    validateAllFunctionHeaders(srcDir, modules);

    % Validate header formats for all functions
    fprintf('🔍 Validating function header formats...\n');
    validateAllFunctionHeaders(srcDir, modules);

    % Update examples documentation
    examplesDir = fullfile(toolboxRoot, 'examples');
    fprintf('📋 Processing examples...\n');
    updateExamplesDocs(examplesDir, docsDir);

    % Update workflows documentation
    workflowsDir = fullfile(examplesDir, 'workflows');
    fprintf('⚙️ Processing workflows...\n');
    updateWorkflowsDocs(workflowsDir, docsDir);

    % Update main API index
    updateApiIndex(docsDir, modules);

    % Update timestamps
    updateTimestamps(docsDir);

    fprintf('✅ Documentation update completed successfully!\n');

catch ME
    fprintf('❌ Error updating documentation: %s\n', ME.message);
    rethrow(ME);
end

end

function updateModuleDocs(srcDir, docsDir, module)
% Update documentation for a specific module

moduleDir = fullfile(srcDir, module);
if ~exist(moduleDir, 'dir')
    fprintf('⚠️  Module directory not found: %s\n', module);
    return;
end

% Get all .m files in module
mFiles = dir(fullfile(moduleDir, '*.m'));

% Create module docs directory
moduleDocsDir = fullfile(docsDir, 'api', module);
if ~exist(moduleDocsDir, 'dir')
    mkdir(moduleDocsDir);
end

functionList = {};

% Process each function
for i = 1:length(mFiles)
    [~, funcName, ~] = fileparts(mFiles(i).name);

    % Skip private directories and test files
    if startsWith(funcName, 'test') || contains(mFiles(i).folder, 'private')
        continue;
    end

    fprintf('  📄 Processing %s...\n', funcName);

    % Extract function documentation
    funcPath = fullfile(mFiles(i).folder, mFiles(i).name);
    docInfo = extractFunctionDoc(funcPath, funcName);

    % Generate markdown documentation
    generateFunctionDoc(moduleDocsDir, funcName, docInfo, module);

    functionList{end+1} = funcName; %#ok<*AGROW>
end

% Update module README
updateModuleReadme(moduleDocsDir, module, functionList);

end

function docInfo = extractFunctionDoc(filePath, functionName)
% Extract documentation from function header comments

% Initialize structure
docInfo = struct();
docInfo.name = functionName;
docInfo.description = '';
docInfo.syntax = {};
docInfo.inputs = {};
docInfo.outputs = {};
docInfo.examples = {};
docInfo.references = {};

try
    % Read file content with UTF-8 encoding
    fileContent = fileread(filePath, 'Encoding', 'UTF-8');
    lines = splitlines(fileContent);

    % Find function declaration
    funcLine = '';
    funcLineIdx = 0;
    for i = 1:length(lines)
        if contains(lines{i}, 'function') && contains(lines{i}, functionName)
            funcLine = strtrim(lines{i});
            funcLineIdx = i;
            break;
        end
    end

    % Extract basic syntax from function declaration
    if ~isempty(funcLine)
        % Clean up function declaration for display
        docInfo.syntax{1} = funcLine;
    end

    % Extract header comments (improved version)
    inHeader = false;
    headerLines = {};
    inInputsSection = false;
    inOutputsSection = false;
    currentInputs = {};
    currentOutputs = {};

    for i = 1:min(100, length(lines)) % Check first 100 lines
        line = strtrim(lines{i});

        if startsWith(line, '%') && ~inHeader
            inHeader = true;
            % First comment line is usually the short description
            if isempty(docInfo.description) && length(line) > 1
                desc = strrep(line, '%', '');
                desc = strtrim(desc);
                % Remove function name if it's at the start
                if startsWith(upper(desc), upper(functionName))
                    desc = strtrim(desc(length(functionName)+1:end));
                    if startsWith(desc, '-')
                        desc = strtrim(desc(2:end));
                    end
                end
                docInfo.description = desc;
            end
            headerLines{end+1} = line;
        elseif inHeader && ~startsWith(line, '%')
            break; % End of header comments
        elseif inHeader && startsWith(line, '%')
            headerLines{end+1} = line;
        end
    end

    % Parse header comments for inputs and outputs
    inExampleSection = false;
    currentExample = '';

    for i = 1:length(headerLines)
        line = headerLines{i};
        cleanLine = strtrim(strrep(line, '%', ''));

        % Check for Inputs section
        if strcmpi(strtrim(cleanLine), 'Inputs:') || strcmpi(strtrim(cleanLine), 'Input Arguments:')
            inInputsSection = true;
            inOutputsSection = false;
            inExampleSection = false;
            continue;
        end

        % Check for Outputs section
        if strcmpi(strtrim(cleanLine), 'Outputs:') || strcmpi(strtrim(cleanLine), 'Output Arguments:')
            inOutputsSection = true;
            inInputsSection = false;
            inExampleSection = false;
            continue;
        end

        % Check for Example section
        if strcmpi(strtrim(cleanLine), 'Example:') || strcmpi(strtrim(cleanLine), 'Examples:')
            inExampleSection = true;
            inInputsSection = false;
            inOutputsSection = false;
            if ~isempty(currentExample)
                docInfo.examples{end+1} = currentExample;
            end
            currentExample = '';
            continue;
        end

        % Reset sections when we hit other section headers
        if ~isempty(cleanLine) && endsWith(cleanLine, ':') && ...
                ~contains(lower(cleanLine), 'input') && ~contains(lower(cleanLine), 'output') && ...
                ~contains(lower(cleanLine), 'example')
            inInputsSection = false;
            inOutputsSection = false;
            inExampleSection = false;
        end

        % Parse input arguments
        if inInputsSection && ~isempty(cleanLine)
            % Look for parameter descriptions (e.g., "ECG - Single-lead ECG signal")
            if contains(cleanLine, ' - ') && ~startsWith(cleanLine, '-')
                parts = split(cleanLine, ' - ', 2);
                if length(parts) >= 2
                    paramName = strtrim(parts{1});
                    paramDesc = strtrim(parts{2});
                    currentInputs{end+1} = struct('name', paramName, 'description', paramDesc);
                end
            elseif startsWith(cleanLine, '''') && contains(cleanLine, ':')
                % Handle name-value pairs (e.g., "'BandpassFreq': Two-element vector...")
                parts = split(cleanLine, ':', 2);
                if length(parts) >= 2
                    paramName = strtrim(strrep(parts{1}, '''', ''));
                    paramDesc = strtrim(parts{2});
                    currentInputs{end+1} = struct('name', paramName, 'description', paramDesc);
                end
            end
        end

        % Parse output arguments
        if inOutputsSection && ~isempty(cleanLine)
            % Look for output descriptions (e.g., "TK - Column vector containing...")
            if contains(cleanLine, ' - ') && ~startsWith(cleanLine, '-')
                parts = split(cleanLine, ' - ', 2);
                if length(parts) >= 2
                    paramName = strtrim(parts{1});
                    paramDesc = strtrim(parts{2});
                    currentOutputs{end+1} = struct('name', paramName, 'description', paramDesc);
                end
            end
        end

        % Parse examples
        if inExampleSection && ~isempty(cleanLine)
            if isempty(currentExample)
                currentExample = cleanLine;
            else
                currentExample = [currentExample newline cleanLine];
            end
        end

        % Try to extract additional syntax variations from comments
        if contains(cleanLine, functionName) && contains(cleanLine, '(') && ...
                ~isempty(regexp(cleanLine, '^\w*\s*=?\s*\w+\(', 'once'))
            if ~any(strcmp(docInfo.syntax, cleanLine))
                docInfo.syntax{end+1} = cleanLine;
            end
        end
    end

    % Add the last example if it exists
    if ~isempty(currentExample)
        docInfo.examples{end+1} = currentExample;
    end

    % Store parsed inputs and outputs
    docInfo.inputs = currentInputs;
    docInfo.outputs = currentOutputs;

    % If few inputs found in comments, supplement with inputParser calls
    if length(docInfo.inputs) <= 2 && funcLineIdx > 0
        parserInputs = extractInputsFromParser(lines, funcLineIdx);
        % Merge with existing inputs, avoiding duplicates
        for i = 1:length(parserInputs)
            parserInput = parserInputs{i};
            % Check if this input already exists
            exists = false;
            for j = 1:length(docInfo.inputs)
                if strcmpi(docInfo.inputs{j}.name, parserInput.name)
                    exists = true;
                    break;
                end
            end
            if ~exists
                docInfo.inputs{end+1} = parserInput;
            end
        end
    end

    % If no outputs found in comments, try to extract from function signature
    if isempty(docInfo.outputs) && ~isempty(funcLine)
        docInfo.outputs = extractOutputsFromSignature(funcLine);
    end

catch ME
    fprintf('⚠️  Warning: Could not extract docs from %s: %s\n', functionName, ME.message);
end

end

function inputs = extractInputsFromParser(lines, startIdx)
% Extract input arguments from inputParser calls

inputs = {};

try
    % Look for inputParser usage in the lines following the function declaration
    for i = startIdx:min(startIdx+50, length(lines))
        line = strtrim(lines{i});

        % Look for addRequired calls
        if contains(line, 'addRequired') && contains(line, 'parser')
            % Extract parameter name from addRequired call
            tokens = regexp(line, 'addRequired\s*\(\s*parser\s*,\s*[''"]([^''"]+)[''"]', 'tokens');
            if ~isempty(tokens)
                paramName = tokens{1}{1};
                inputs{end+1} = struct('name', upper(paramName), 'description', sprintf('%s - Required input parameter', paramName));
            end
        end

        % Look for addParameter calls
        if contains(line, 'addParameter') && contains(line, 'parser')
            % Extract parameter name from addParameter call
            tokens = regexp(line, 'addParameter\s*\(\s*parser\s*,\s*[''"]([^''"]+)[''"]', 'tokens');
            if ~isempty(tokens)
                paramName = tokens{1}{1};
                % Try to extract default value
                defaultTokens = regexp(line, ',\s*([^,@]+)\s*,\s*@', 'tokens');
                defaultValue = '';
                if ~isempty(defaultTokens)
                    defVal = strtrim(defaultTokens{1}{1});
                    % Clean up common default values
                    if isnumeric(str2double(defVal)) && ~isnan(str2double(defVal))
                        defaultValue = sprintf(' (default: %s)', defVal);
                    elseif startsWith(defVal, '[') || startsWith(defVal, '''') || strcmpi(defVal, 'true') || strcmpi(defVal, 'false')
                        defaultValue = sprintf(' (default: %s)', defVal);
                    end
                end
                inputs{end+1} = struct('name', paramName, 'description', sprintf('Optional parameter%s', defaultValue));
            end
        end

        % Look for addOptional calls
        if contains(line, 'addOptional') && contains(line, 'parser')
            % Extract parameter name from addOptional call
            tokens = regexp(line, 'addOptional\s*\(\s*parser\s*,\s*[''"]([^''"]+)[''"]', 'tokens');
            if ~isempty(tokens)
                paramName = tokens{1}{1};
                inputs{end+1} = struct('name', paramName, 'description', sprintf('Optional parameter'));
            end
        end
    end
catch ME
    % If parsing fails, return empty
    inputs = {};
end

end

function outputs = extractOutputsFromSignature(funcLine)
% Extract output arguments from function signature

outputs = {};

try
    % Parse function signature to extract output variables
    if contains(funcLine, '=')
        % Extract the left side of the assignment
        parts = split(funcLine, '=');
        leftSide = strtrim(parts{1});

        % Remove 'function' keyword if present
        leftSide = regexprep(leftSide, '^function\s+', '');

        if startsWith(leftSide, '[') && endsWith(leftSide, ']')
            % Multiple outputs: [out1, out2, out3]
            outputStr = leftSide(2:end-1); % Remove brackets
            outputNames = split(outputStr, ',');
            for i = 1:length(outputNames)
                outputName = strtrim(outputNames{i});
                if ~isempty(outputName)
                    outputs{end+1} = struct('name', outputName, 'description', sprintf('%s output', outputName));
                end
            end
        elseif contains(leftSide, 'varargout')
            % Variable number of outputs
            outputs{end+1} = struct('name', 'varargout', 'description', 'Variable number of output arguments');
        else
            % Single output
            outputName = strtrim(leftSide);
            if ~isempty(outputName)
                outputs{end+1} = struct('name', outputName, 'description', sprintf('%s output', outputName));
            end
        end
    end
catch ME
    % If parsing fails, return empty
    outputs = {};
end

end

function generateFunctionDoc(moduleDocsDir, functionName, docInfo, module)
% Generate markdown documentation for a function

outputPath = fullfile(moduleDocsDir, [functionName '.md']);

% Create markdown content
content = sprintf('# `%s` - %s\n\n', functionName, docInfo.description);

% Add syntax section
content = [content sprintf('## Syntax\n\n')];
content = [content sprintf('```matlab\n')];
for i = 1:length(docInfo.syntax)
    content = [content sprintf('%s\n', docInfo.syntax{i})];
end
content = [content sprintf('```\n\n')];

% Add description
content = [content sprintf('## Description\n\n')];
content = [content sprintf('%s\n\n', docInfo.description)];

% Add source code link
content = [content sprintf('## Source Code\n\n')];
content = [content sprintf('[View source code](../../../src/%s/%s.m)\n\n', module, functionName)];

% Add placeholders for manual editing
content = [content sprintf('## Input Arguments\n\n')];
if ~isempty(docInfo.inputs)
    for i = 1:length(docInfo.inputs)
        input = docInfo.inputs{i};
        content = [content sprintf('- **%s**: %s\n', input.name, input.description)];
    end
    content = [content newline];
else
    content = [content sprintf('*To be documented*\n\n')];
end

content = [content sprintf('## Output Arguments\n\n')];
if ~isempty(docInfo.outputs)
    for i = 1:length(docInfo.outputs)
        output = docInfo.outputs{i};
        content = [content sprintf('- **%s**: %s\n', output.name, output.description)];
    end
    content = [content newline];
else
    content = [content sprintf('*To be documented*\n\n')];
end

content = [content sprintf('## Examples\n\n')];
if ~isempty(docInfo.examples)
    content = [content sprintf('```matlab\n')];
    for i = 1:length(docInfo.examples)
        content = [content sprintf('%s\n', docInfo.examples{i})];
        if i < length(docInfo.examples)
            content = [content newline];
        end
    end
    content = [content sprintf('```\n\n')];
else
    content = [content sprintf('```matlab\n')];
    content = [content sprintf('%% Basic usage example\n')];
    content = [content sprintf('result = %s(input);\n', functionName)];
    content = [content sprintf('```\n\n')];
end

content = [content sprintf('## See Also\n\n')];
content = [content sprintf('- [%s Module](README.md)\n', upper(module))];
content = [content sprintf('- [API Reference](../README.md)\n\n')];

content = [content sprintf('---\n\n')];
content = [content sprintf('**Module**: %s | **Status**: 🔄 Auto-generated | **Last Updated**: %s\n', ...
    upper(module), string(datetime('now', 'Format', 'yyyy-MM-dd')))];

% Write file
try
    fid = fopen(outputPath, 'w', 'n', 'UTF-8');
    if fid == -1
        error('Could not open file for writing: %s', outputPath);
    end
    fprintf(fid, '%s', content);
    fclose(fid);
catch ME
    if fid ~= -1
        fclose(fid);
    end
    rethrow(ME);
end

end

function updateModuleReadme(moduleDocsDir, module, functionList)
% Update the README file for a module

readmePath = fullfile(moduleDocsDir, 'README.md');

% Create basic module README content
content = sprintf('# %s Module\n\n', upper(module));
content = [content sprintf('## Functions\n\n')];

for i = 1:length(functionList)
    funcName = functionList{i};
    content = [content sprintf('- [`%s`](%s.md)\n', funcName, funcName)];
end

content = [content sprintf('\n## See Also\n\n')];
content = [content sprintf('- [API Reference](../README.md)\n')];
content = [content sprintf('- [Examples](../../examples/%s-examples.md)\n\n', module)];

content = [content sprintf('---\n\n')];
content = [content sprintf('**Functions**: %d | **Last Updated**: %s\n', ...
    length(functionList), string(datetime('now', 'Format', 'yyyy-MM-dd')))];

% Write file
fid = fopen(readmePath, 'w', 'n', 'UTF-8');
if fid == -1
    error('Could not open file for writing: %s', readmePath);
end
fprintf(fid, '%s', content);
fclose(fid);

end

function updateApiIndex(docsDir, modules)
% Update the main API index file

fprintf('📋 Updating API index...\n');

try
    % Count functions in each module
    functionCounts = struct();
    totalFunctions = 0;

    for i = 1:length(modules)
        module = modules{i};
        moduleDocsDir = fullfile(docsDir, 'api', module);

        if exist(moduleDocsDir, 'dir')
            % Count .md files (excluding README.md)
            mdFiles = dir(fullfile(moduleDocsDir, '*.md'));
            mdFiles = mdFiles(~strcmp({mdFiles.name}, 'README.md'));
            functionCounts.(module) = length(mdFiles);
            totalFunctions = totalFunctions + length(mdFiles);
        else
            functionCounts.(module) = 0;
        end
    end

    % Update the count in the main API README if it exists
    apiReadmePath = fullfile(docsDir, 'api', 'README.md');
    if exist(apiReadmePath, 'file')
        content = fileread(apiReadmePath, 'Encoding', 'UTF-8');

        % Update the total function count at the bottom
        pattern = 'Total functions: \d+';
        replacement = sprintf('Total functions: %d', totalFunctions);
        content = regexprep(content, pattern, replacement);

        % Write back
        fid = fopen(apiReadmePath, 'w', 'n', 'UTF-8');
        if fid ~= -1
            fprintf(fid, '%s', content);
            fclose(fid);
            fprintf('  ✅ Updated function count: %d total functions\n', totalFunctions);
        end
    end

catch ME
    fprintf('⚠️  Warning: Could not update API index: %s\n', ME.message);
end

end

function updateTimestamps(docsDir)
% Update timestamps in documentation files

fprintf('🕐 Updating timestamps...\n');

% Find all .md files and update {{DATE}} placeholders
mdFiles = dir(fullfile(docsDir, '**', '*.md'));

currentDate = string(datetime('now', 'Format', 'yyyy-MM-dd'));

for i = 1:length(mdFiles)
    filePath = fullfile(mdFiles(i).folder, mdFiles(i).name);

    try
        % Read file with UTF-8 encoding
        content = fileread(filePath, 'Encoding', 'UTF-8');

        % Replace timestamp placeholder
        if contains(content, '{{DATE}}')
            content = strrep(content, '{{DATE}}', currentDate);

            % Write back with UTF-8 encoding
            fid = fopen(filePath, 'w', 'n', 'UTF-8');
            if fid == -1
                error('Could not open file for writing: %s', filePath);
            end
            fprintf(fid, '%s', content);
            fclose(fid);
        end
    catch ME
        fprintf('⚠️  Warning: Could not update timestamps in %s: %s\n', ...
            mdFiles(i).name, ME.message);
    end
end

end

function updateExamplesDocs(examplesDir, docsDir)
% Update documentation for examples

if ~exist(examplesDir, 'dir')
    fprintf('⚠️  Examples directory not found: %s\n', examplesDir);
    return;
end

% Create examples docs directory
examplesDocsDir = fullfile(docsDir, 'examples');
if ~exist(examplesDocsDir, 'dir')
    mkdir(examplesDocsDir);
end

% Get module directories in examples
modulesList = dir(examplesDir);
modulesList = modulesList([modulesList.isdir] & ~startsWith({modulesList.name}, '.'));

examplesByModule = struct();

for i = 1:length(modulesList)
    module = modulesList(i).name;

    % Skip workflows directory (handled separately)
    if strcmp(module, 'workflows')
        continue;
    end

    moduleExamplesDir = fullfile(examplesDir, module);

    % Get all .m files in module examples
    mFiles = dir(fullfile(moduleExamplesDir, '*.m'));

    examplesList = {};

    for j = 1:length(mFiles)
        [~, exampleName, ~] = fileparts(mFiles(j).name);

        fprintf('  📄 Processing example %s...\n', exampleName);

        % Extract example documentation
        examplePath = fullfile(mFiles(j).folder, mFiles(j).name);
        docInfo = extractExampleDoc(examplePath, exampleName);

        % Generate markdown documentation
        generateExampleDoc(examplesDocsDir, exampleName, docInfo, module);

        examplesList{end+1} = exampleName; %#ok<*AGROW>
    end

    examplesByModule.(module) = examplesList;
end

% Update examples README
updateExamplesReadme(examplesDocsDir, examplesByModule);

end

function updateWorkflowsDocs(workflowsDir, docsDir)
% Update documentation for workflows

if ~exist(workflowsDir, 'dir')
    fprintf('⚠️  Workflows directory not found: %s\n', workflowsDir);
    return;
end

% Create workflows docs directory
workflowsDocsDir = fullfile(docsDir, 'examples');
if ~exist(workflowsDocsDir, 'dir')
    mkdir(workflowsDocsDir);
end

% Get all .m files in workflows
mFiles = dir(fullfile(workflowsDir, '*.m'));

workflowsList = {};

for i = 1:length(mFiles)
    [~, workflowName, ~] = fileparts(mFiles(i).name);

    fprintf('  📄 Processing workflow %s...\n', workflowName);

    % Extract workflow documentation
    workflowPath = fullfile(mFiles(i).folder, mFiles(i).name);
    docInfo = extractWorkflowDoc(workflowPath, workflowName);

    % Generate markdown documentation
    generateWorkflowDoc(workflowsDocsDir, workflowName, docInfo);

    workflowsList{end+1} = workflowName;
end

% Update workflows section in examples README
updateWorkflowsReadme(workflowsDocsDir, workflowsList);

end

function docInfo = extractExampleDoc(filePath, exampleName)
% Extract documentation from example file header comments

% Initialize structure
docInfo = struct();
docInfo.name = exampleName;
docInfo.title = '';
docInfo.description = '';
docInfo.steps = {};
docInfo.requirements = {};

try
    % Read file content with UTF-8 encoding
    fileContent = fileread(filePath, 'Encoding', 'UTF-8');
    lines = splitlines(fileContent);

    % Extract header comments
    inHeader = false;
    headerLines = {};

    for i = 1:min(50, length(lines)) % Check first 50 lines
        line = strtrim(lines{i});

        if startsWith(line, '%') && ~inHeader
            inHeader = true;
            % First comment line is usually the title
            if isempty(docInfo.title) && length(line) > 1
                title = strrep(line, '%', '');
                title = strtrim(title);
                docInfo.title = title;
            end
            headerLines{end+1} = line;
        elseif inHeader && startsWith(line, '%')
            headerLines{end+1} = line;

            % Look for description
            cleanLine = strtrim(strrep(line, '%', ''));
            if ~isempty(cleanLine) && isempty(docInfo.description) && ...
                    ~contains(upper(cleanLine), upper(exampleName)) && ...
                    ~startsWith(cleanLine, 'This example')
                docInfo.description = cleanLine;
            elseif startsWith(cleanLine, 'This example')
                docInfo.description = cleanLine;
            end
        elseif inHeader && ~startsWith(line, '%')
            break; % End of header comments
        end
    end

    % Extract steps from comments (look for numbered lists or workflow descriptions)
    currentStep = '';
    for i = 1:length(headerLines)
        line = headerLines{i};
        cleanLine = strtrim(strrep(line, '%', ''));

        % Look for numbered steps or workflow descriptions
        if ~isempty(regexp(cleanLine, '^\d+\.', 'once')) || ...
                contains(cleanLine, ':') && length(cleanLine) > 10
            if ~isempty(currentStep)
                docInfo.steps{end+1} = currentStep;
            end
            currentStep = cleanLine;
        elseif ~isempty(currentStep) && ~isempty(cleanLine)
            currentStep = [currentStep ' ' cleanLine];
        end
    end
    if ~isempty(currentStep)
        docInfo.steps{end+1} = currentStep;
    end

catch ME
    fprintf('⚠️  Warning: Could not extract docs from example %s: %s\n', exampleName, ME.message);
end

end

function docInfo = extractWorkflowDoc(filePath, workflowName)
% Extract documentation from workflow file header comments

% Initialize structure
docInfo = struct();
docInfo.name = workflowName;
docInfo.title = '';
docInfo.description = '';
docInfo.workflow = {};
docInfo.requirements = {};

try
    % Read file content with UTF-8 encoding
    fileContent = fileread(filePath, 'Encoding', 'UTF-8');
    lines = splitlines(fileContent);

    % Extract header comments
    inHeader = false;
    headerLines = {};

    for i = 1:min(100, length(lines)) % Check first 100 lines for workflows
        line = strtrim(lines{i});

        if startsWith(line, '%') && ~inHeader
            inHeader = true;
            % First comment line is usually the title
            if isempty(docInfo.title) && length(line) > 1
                title = strrep(line, '%', '');
                title = strtrim(title);
                docInfo.title = title;
            end
            headerLines{end+1} = line;
        elseif inHeader && startsWith(line, '%')
            headerLines{end+1} = line;
        elseif inHeader && ~startsWith(line, '%')
            break; % End of header comments
        end
    end

    % Parse workflow description and steps
    inWorkflowSection = false;
    for i = 1:length(headerLines)
        line = headerLines{i};
        cleanLine = strtrim(strrep(line, '%', ''));

        if contains(cleanLine, 'workflow:') || contains(cleanLine, 'The workflow')
            inWorkflowSection = true;
            if ~isempty(cleanLine) && isempty(docInfo.description)
                docInfo.description = cleanLine;
            end
        elseif inWorkflowSection && ~isempty(regexp(cleanLine, '^\d+\.', 'once'))
            docInfo.workflow{end+1} = cleanLine;
        elseif ~inWorkflowSection && ~isempty(cleanLine) && ...
                isempty(docInfo.description) && ~contains(upper(cleanLine), upper(workflowName))
            docInfo.description = cleanLine;
        end
    end

catch ME
    fprintf('⚠️  Warning: Could not extract docs from workflow %s: %s\n', workflowName, ME.message);
end

end

function generateExampleDoc(examplesDocsDir, exampleName, docInfo, module)
% Generate markdown documentation for an example

outputPath = fullfile(examplesDocsDir, [exampleName '.md']);

% Create markdown content
if ~isempty(docInfo.title)
    content = sprintf('# %s\n\n', docInfo.title);
else
    content = sprintf('# %s Example\n\n', exampleName);
end

% Add description
if ~isempty(docInfo.description)
    content = [content sprintf('## Description\n\n')];
    content = [content sprintf('%s\n\n', docInfo.description)];
end

% Add module reference
content = [content sprintf('**Module**: %s\n\n', upper(module))];

% Add steps if available
if ~isempty(docInfo.steps)
    content = [content sprintf('## Steps\n\n')];
    for i = 1:length(docInfo.steps)
        content = [content sprintf('%d. %s\n', i, docInfo.steps{i})];
    end
    content = [content newline];
end

% Add usage section
content = [content sprintf('## Usage\n\n')];
content = [content sprintf('Run the example from the MATLAB command window:\n\n')];
content = [content sprintf('```matlab\n')];
content = [content sprintf('run(''examples/%s/%s.m'');\n', module, exampleName)];
content = [content sprintf('```\n\n')];

% Add file location
content = [content sprintf('## File Location\n\n')];
content = [content sprintf('`examples/%s/%s.m`\n\n', module, exampleName)];

% Add see also section
content = [content sprintf('## See Also\n\n')];
content = [content sprintf('- [%s Module](../api/%s/README.md)\n', upper(module), module)];
content = [content sprintf('- [Examples Overview](README.md)\n\n')];

content = [content sprintf('---\n\n')];
content = [content sprintf('**Type**: Example | **Module**: %s | **Last Updated**: %s\n', ...
    upper(module), string(datetime('now', 'Format', 'yyyy-MM-dd')))];

% Write file
try
    fid = fopen(outputPath, 'w', 'n', 'UTF-8');
    if fid == -1
        error('Could not open file for writing: %s', outputPath);
    end
    fprintf(fid, '%s', content);
    fclose(fid);
catch ME
    if fid ~= -1
        fclose(fid);
    end
    rethrow(ME);
end

end

function generateWorkflowDoc(workflowsDocsDir, workflowName, docInfo)
% Generate markdown documentation for a workflow

outputPath = fullfile(workflowsDocsDir, [workflowName '.md']);

% Create markdown content
if ~isempty(docInfo.title)
    content = sprintf('# %s\n\n', docInfo.title);
else
    content = sprintf('# %s Workflow\n\n', workflowName);
end

% Add description
if ~isempty(docInfo.description)
    content = [content sprintf('## Description\n\n')];
    content = [content sprintf('%s\n\n', docInfo.description)];
end

% Add workflow type
content = [content sprintf('**Type**: Workflow\n\n')];

% Add workflow steps if available
if ~isempty(docInfo.workflow)
    content = [content sprintf('## Workflow Steps\n\n')];
    for i = 1:length(docInfo.workflow)
        content = [content sprintf('%s\n', docInfo.workflow{i})];
    end
    content = [content newline];
end

% Add usage section
content = [content sprintf('## Usage\n\n')];
content = [content sprintf('Run the workflow from the MATLAB command window:\n\n')];
content = [content sprintf('```matlab\n')];
content = [content sprintf('run(''examples/workflows/%s.m'');\n', workflowName)];
content = [content sprintf('```\n\n')];

% Add file location
content = [content sprintf('## File Location\n\n')];
content = [content sprintf('`examples/workflows/%s.m`\n\n', workflowName)];

% Add see also section
content = [content sprintf('## See Also\n\n')];
content = [content sprintf('- [Workflows Overview](README.md#workflows)\n')];
content = [content sprintf('- [Examples Overview](README.md)\n\n')];

content = [content sprintf('---\n\n')];
content = [content sprintf('**Type**: Workflow | **Last Updated**: %s\n', ...
    string(datetime('now', 'Format', 'yyyy-MM-dd')))];

% Write file
try
    fid = fopen(outputPath, 'w', 'n', 'UTF-8');
    if fid == -1
        error('Could not open file for writing: %s', outputPath);
    end
    fprintf(fid, '%s', content);
    fclose(fid);
catch ME
    if fid ~= -1
        fclose(fid);
    end
    rethrow(ME);
end

end

function updateExamplesReadme(examplesDocsDir, examplesByModule)
% Update the README file for examples

readmePath = fullfile(examplesDocsDir, 'README.md');

% Create examples README content
content = sprintf('# Examples and Workflows\n\n');
content = [content sprintf('This section contains practical examples and workflows demonstrating the usage of biosigmat functions.\n\n')];

% Add examples by module
content = [content sprintf('## Examples by Module\n\n')];

moduleNames = fieldnames(examplesByModule);
totalExamples = 0;

for i = 1:length(moduleNames)
    module = moduleNames{i};
    examples = examplesByModule.(module);

    if ~isempty(examples)
        content = [content sprintf('### %s Module\n\n', upper(module))];

        for j = 1:length(examples)
            exampleName = examples{j};
            content = [content sprintf('- [`%s`](%s.md)\n', exampleName, exampleName)];
            totalExamples = totalExamples + 1;
        end
        content = [content newline];
    end
end

% Add workflows section placeholder
content = [content sprintf('## Workflows\n\n')];
content = [content sprintf('*Workflows will be listed here after processing*\n\n')];

% Add getting started section
content = [content sprintf('## Getting Started\n\n')];
content = [content sprintf('1. Make sure biosigmat is properly installed\n')];
content = [content sprintf('2. Add the required paths to MATLAB\n')];
content = [content sprintf('3. Load any necessary fixture data\n')];
content = [content sprintf('4. Run the example scripts\n\n')];

content = [content sprintf('## See Also\n\n')];
content = [content sprintf('- [API Reference](../api/README.md)\n')];
content = [content sprintf('- [Getting Started](../getting-started.md)\n\n')];

content = [content sprintf('---\n\n')];
content = [content sprintf('**Examples**: %d | **Last Updated**: %s\n', ...
    totalExamples, string(datetime('now', 'Format', 'yyyy-MM-dd')))];

% Write file
fid = fopen(readmePath, 'w', 'n', 'UTF-8');
if fid == -1
    error('Could not open file for writing: %s', readmePath);
end
fprintf(fid, '%s', content);
fclose(fid);

end

function updateWorkflowsReadme(examplesDocsDir, workflowsList)
% Update the workflows section in examples README

readmePath = fullfile(examplesDocsDir, 'README.md');

if exist(readmePath, 'file')
    % Read existing content
    content = fileread(readmePath, 'Encoding', 'UTF-8');

    % Replace workflows placeholder
    workflowsSection = sprintf('## Workflows\n\n');

    if ~isempty(workflowsList)
        for i = 1:length(workflowsList)
            workflowName = workflowsList{i};
            workflowsSection = [workflowsSection sprintf('- [`%s`](%s.md)\n', workflowName, workflowName)];
        end
    else
        workflowsSection = [workflowsSection sprintf('*No workflows found*\n')];
    end
    workflowsSection = [workflowsSection newline];

    % Replace the placeholder
    content = regexprep(content, '## Workflows\n\n\*Workflows will be listed here after processing\*\n\n', workflowsSection);

    % Update workflow count in footer
    pattern = '\*\*Examples\*\*: (\d+)';
    if ~isempty(regexp(content, pattern, 'once'))
        matches = regexp(content, pattern, 'tokens');
        if ~isempty(matches)
            exampleCount = str2double(matches{1}{1});
            replacement = sprintf('**Examples**: %d | **Workflows**: %d', exampleCount, length(workflowsList));
            content = regexprep(content, '\*\*Examples\*\*: \d+', replacement);
        end
    end

    % Write back
    fid = fopen(readmePath, 'w', 'n', 'UTF-8');
    if fid ~= -1
        fprintf(fid, '%s', content);
        fclose(fid);
    end
end

end

function validateAllFunctionHeaders(srcDir, modules)
% Validate header format for all functions in the source directory

validationResults = struct();
validationResults.compliant = {};
validationResults.violations = {};
totalFunctions = 0;
totalViolations = 0;

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
headerInfo.suggestions = {};

try
    % Read file content
    fileContent = fileread(filePath, 'Encoding', 'UTF-8');
    lines = splitlines(fileContent);

    % Find function declaration
    funcLineIdx = 0;
    funcLine = '';
    for i = 1:length(lines)
        if contains(lines{i}, 'function') && contains(lines{i}, functionName)
            funcLineIdx = i;
            funcLine = strtrim(lines{i});
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
            headerLines{end+1} = line;
        elseif ~isempty(line) && headerStartIdx > 0
            break; % End of header
        end
    end

    if isempty(headerLines)
        headerInfo.isCompliant = false;
        headerInfo.violations{end+1} = 'No header comments found';
        headerInfo.suggestions{end+1} = sprintf('Add header: %% %s - Brief description', upper(functionName));
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
        headerInfo.suggestions{end+1} = sprintf('Change first line to: %%%s Brief description.', upper(functionName));
    else
        % Check if description ends with period
        if ~endsWith(cleanFirstLine, '.')
            headerInfo.violations{end+1} = 'First line should end with period';
            headerInfo.suggestions{end+1} = 'Add period at end of first line description';
        end

        % Check if there's actually a description after function name
        if length(words) < 2
            headerInfo.violations{end+1} = 'Missing description in first line';
            headerInfo.suggestions{end+1} = 'Add brief description after function name';
        end
    end

    % Check if description is too long
    if length(cleanFirstLine) > 80
        headerInfo.violations{end+1} = 'First line description too long (>80 characters)';
        headerInfo.suggestions{end+1} = 'Keep first line brief, add details below';
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
    headerInfo.suggestions{end+1} = 'Add syntax forms like: %   OUTPUT = FUNCTIONNAME(INPUT1,INPUT2) description';
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
    headerInfo.violations{end+1} = 'Missing required section: EXAMPLE:';
    headerInfo.suggestions{end+1} = 'Add EXAMPLE: section with usage example';
end

% Check for See also section (common in MATLAB functions)
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
    headerInfo.suggestions{end+1} = 'Add: narginchk(minArgs, maxArgs);';
end

if ~hasNargoutchk
    headerInfo.violations{end+1} = 'Missing nargoutchk() call';
    headerInfo.suggestions{end+1} = 'Add: nargoutchk(0, maxOutputs);';
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

    % Report most common violations
    if isfield(violationCounts, 'types')
        fprintf('🔍 Most Common Violations:\n');
        [~, sortIdx] = sort(violationCounts.counts, 'descend');
        for i = 1:min(5, length(sortIdx))
            idx = sortIdx(i);
            fprintf('  • %s: %d functions\n', violationCounts.types{idx}, violationCounts.counts(idx));
        end
        fprintf('\n');
    end

    % Report detailed violations
    fprintf('📋 Functions with Header Violations:\n');
    for i = 1:length(validationResults.violations)
        violation = validationResults.violations{i};
        fprintf('\n📄 %s (%s module):\n', violation.functionName, violation.module);
        for j = 1:length(violation.violations)
            fprintf('  ❌ %s\n', violation.violations{j});
        end
        if ~isempty(violation.suggestions)
            fprintf('  💡 Suggestions:\n');
            for j = 1:length(violation.suggestions)
                fprintf('     %s\n', violation.suggestions{j});
            end
        end
    end
else
    fprintf('🎉 All function headers are compliant!\n');
end

fprintf('\n');

end
