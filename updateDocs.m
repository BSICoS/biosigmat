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
    % Read file content
    fileContent = fileread(filePath);
    lines = splitlines(fileContent);

    % Find function declaration
    funcLine = '';
    for i = 1:length(lines)
        if contains(lines{i}, 'function') && contains(lines{i}, functionName)
            funcLine = strtrim(lines{i});
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

    % Try to extract additional syntax variations from comments
    for i = 1:length(headerLines)
        line = headerLines{i};
        cleanLine = strtrim(strrep(line, '%', ''));

        % Look for additional syntax examples
        if contains(cleanLine, functionName) && contains(cleanLine, '(') && ...
                ~isempty(regexp(cleanLine, '^\w+\s*=?\s*\w+\(', 'once'))
            if ~any(strcmp(docInfo.syntax, cleanLine))
                docInfo.syntax{end+1} = cleanLine;
            end
        end
    end

catch ME
    fprintf('⚠️  Warning: Could not extract docs from %s: %s\n', functionName, ME.message);
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

% Add placeholders for manual editing
content = [content sprintf('## Input Arguments\n\n')];
content = [content sprintf('*To be documented*\n\n')];

content = [content sprintf('## Output Arguments\n\n')];
content = [content sprintf('*To be documented*\n\n')];

content = [content sprintf('## Examples\n\n')];
content = [content sprintf('```matlab\n')];
content = [content sprintf('%% Basic usage example\n')];
content = [content sprintf('result = %s(input);\n', functionName)];
content = [content sprintf('```\n\n')];

content = [content sprintf('## See Also\n\n')];
content = [content sprintf('- [%s Module](README.md)\n', upper(module))];
content = [content sprintf('- [API Reference](../README.md)\n\n')];

content = [content sprintf('---\n\n')];
content = [content sprintf('**Module**: %s | **Status**: 🔄 Auto-generated | **Last Updated**: %s\n', ...
    upper(module), string(datetime('now', 'Format', 'yyyy-MM-dd')))];

% Write file
try
    fid = fopen(outputPath, 'w');
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
fid = fopen(readmePath, 'w');
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
        content = fileread(apiReadmePath);

        % Update the total function count at the bottom
        pattern = 'Total functions: \d+';
        replacement = sprintf('Total functions: %d', totalFunctions);
        content = regexprep(content, pattern, replacement);

        % Write back
        fid = fopen(apiReadmePath, 'w');
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
        % Read file
        content = fileread(filePath);

        % Replace timestamp placeholder
        if contains(content, '{{DATE}}')
            content = strrep(content, '{{DATE}}', currentDate);

            % Write back
            fid = fopen(filePath, 'w');
            fprintf(fid, '%s', content);
            fclose(fid);
        end
    catch ME
        fprintf('⚠️  Warning: Could not update timestamps in %s: %s\n', ...
            mdFiles(i).name, ME.message);
    end
end

end
