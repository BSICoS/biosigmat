function updateDocs()
% UPDATEDOCS - Generate and update toolbox documentation automatically
%
% This script scans the source code and automatically generates/updates
% documentation files in the docs/ directory.
%
% Usage:
%   updateDocs()           % Update all documentation
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

    % Get modules dynamically from src directory
    srcContents = dir(srcDir);
    srcContents = srcContents([srcContents.isdir] & ~startsWith({srcContents.name}, '.'));
    modules = {srcContents.name};

    fprintf('📚 Found %d modules: %s\n', length(modules), strjoin(modules, ', '));

    % Update API documentation for each module
    for i = 1:length(modules)
        module = modules{i};
        fprintf('📚 Processing %s module...\n', module);
        updateModuleDocs(srcDir, docsDir, module);
    end

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
docInfo.briefDescription = '';
docInfo.longDescription = '';
docInfo.syntax = {};
docInfo.examples = '';
docInfo.seeAlso = {};
docInfo.status = 'Stable'; % Default status

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

    % Extract function syntax from declaration
    if ~isempty(funcLine)
        % Clean up function declaration for display
        docInfo.syntax{1} = funcLine;
    end

    % Extract header comments - all consecutive lines starting with '%' after function declaration
    headerLines = {};

    for i = funcLineIdx+1:length(lines)
        line = lines{i};

        % If line starts with '%', it's part of the header
        if startsWith(strtrim(line), '%')
            headerLines{end+1} = line;
        else
            % First non-comment line means header has ended
            break;
        end
    end

    % Parse the new header format
    if ~isempty(headerLines)
        % First line should be function name and brief description
        firstLine = strtrim(strrep(headerLines{1}, '%', ''));
        if startsWith(upper(firstLine), upper(functionName))
            % Extract brief description (everything after function name)
            spaceIdx = strfind(firstLine, ' ');
            if ~isempty(spaceIdx) && length(spaceIdx) >= 1
                % Find the first space after the function name and take everything after it
                docInfo.briefDescription = strtrim(firstLine(spaceIdx(1)+1:end));
            end
        end

        % Parse sections
        currentSection = '';
        longDesc = {};
        currentParagraph = {};
        currentExample = {};
        seeAlsoList = {};

        i = 2; % Start from second line
        while i <= length(headerLines)
            line = headerLines{i};
            cleanLine = strtrim(strrep(line, '%', ''));

            % Check for section headers
            if strcmpi(cleanLine, 'Example:') || strcmpi(cleanLine, 'Examples:')
                % Before switching to example, save any remaining paragraph
                if ~isempty(currentParagraph) && strcmp(currentSection, '')
                    longDesc{end+1} = formatParagraph(currentParagraph);
                    currentParagraph = {};
                end
                currentSection = 'example';
                i = i + 1;
                continue;
            elseif startsWith(cleanLine, 'See also')
                % Before switching to see also, save any remaining paragraph
                if ~isempty(currentParagraph) && strcmp(currentSection, '')
                    longDesc{end+1} = formatParagraph(currentParagraph);
                    currentParagraph = {};
                end
                currentSection = 'seealso';
                % Extract see also items from the same line (starts with "See also")
                if length(cleanLine) > 8
                    seeAlsoText = strtrim(cleanLine(9:end)); % Remove "See also" prefix
                    if ~isempty(seeAlsoText)
                        seeAlsoList = [seeAlsoList; split(seeAlsoText, ',')];
                    end
                end
                i = i + 1;
                continue;
            elseif isempty(cleanLine)
                % Empty line handling
                if strcmp(currentSection, 'example')
                    % In example section, preserve empty lines
                    currentExample{end+1} = '';
                elseif strcmp(currentSection, '') && ~isempty(currentParagraph)
                    % End current paragraph if we're in description section
                    longDesc{end+1} = formatParagraph(currentParagraph);
                    currentParagraph = {};
                end
                i = i + 1;
                continue;
            end

            % Process content based on current section
            switch currentSection
                case 'example'
                    % For examples, always process the line (including empty ones handled above)
                    % For examples, preserve the original line with '%' characters
                    originalLine = line;

                    if contains(originalLine, '%')
                        % Find the first '%' character
                        percentPos = strfind(originalLine, '%');
                        if ~isempty(percentPos)
                            % Take everything from the first '%' onward
                            lineFromPercent = originalLine(percentPos(1):end);
                            % Remove the '%' and one following space if present
                            if length(lineFromPercent) > 1 && lineFromPercent(2) == ' '
                                exampleLine = lineFromPercent(3:end);
                            else
                                exampleLine = lineFromPercent(2:end);
                            end

                            % For comment lines starting with %, remove all leading spaces
                            % For code lines, remove only the standard 5 leading spaces
                            if startsWith(strtrim(exampleLine), '%')
                                % This is a comment line, remove all leading spaces
                                exampleLine = strtrim(exampleLine);
                            else
                                % This is code, remove exactly 5 leading spaces if present
                                trimmedLine = strtrim(exampleLine);
                                leadingSpaces = length(exampleLine) - length(trimmedLine);
                                spacesToRemove = min(5, leadingSpaces);
                                if spacesToRemove > 0
                                    exampleLine = exampleLine(spacesToRemove+1:end);
                                end
                            end
                        else
                            exampleLine = strtrim(originalLine);
                        end
                    else
                        exampleLine = strtrim(originalLine);
                    end
                    currentExample{end+1} = exampleLine;
                case 'seealso'
                    if ~isempty(cleanLine)
                        seeAlsoList = [seeAlsoList; split(cleanLine, ',')];
                    end
                otherwise
                    % Long description section (before Example)
                    if ~isempty(cleanLine)
                        currentParagraph{end+1} = cleanLine;
                    end
            end

            i = i + 1;
        end

        % Save any remaining paragraph
        if ~isempty(currentParagraph) && strcmp(currentSection, '')
            longDesc{end+1} = formatParagraph(currentParagraph);
        end

        % Store extracted information - join paragraphs with double newline
        docInfo.longDescription = strjoin(longDesc, '\n\n');

        % Remove trailing empty lines from examples
        while ~isempty(currentExample) && isempty(currentExample{end})
            currentExample(end) = [];
        end

        docInfo.examples = strjoin(currentExample, newline);

        % Clean up see also list - only include items from header, exclude status
        cleanSeeAlso = {};
        for j = 1:length(seeAlsoList)
            item = strtrim(seeAlsoList{j});
            if ~isempty(item) && ~startsWith(item, 'Status:')
                cleanSeeAlso{end+1} = item;
            end
        end
        docInfo.seeAlso = cleanSeeAlso;

        % Extract status information (look for "Status:" at the beginning of lines)
        for j = length(headerLines):-1:max(1, length(headerLines)-5)
            line = headerLines{j};
            cleanLine = strtrim(strrep(line, '%', ''));
            if startsWith(cleanLine, 'Status:')
                statusText = strtrim(cleanLine(8:end)); % Remove "Status:" prefix
                if ~isempty(statusText)
                    docInfo.status = statusText;
                end
                break;
            end
        end
    end

catch ME
    fprintf('⚠️  Warning: Could not extract docs from %s: %s\n', functionName, ME.message);
end

end

function formattedParagraph = formatParagraph(paragraphLines)
% Format a paragraph preserving special formatting for parameter lists

if isempty(paragraphLines)
    formattedParagraph = '';
    return;
end

% Check if this paragraph contains parameter definitions (lines starting with quotes)
% or output definitions (lines with uppercase words followed by dash)
% or column definitions (lines with ordinal numbers followed by col.)
hasParameters = false;
hasOutputs = false;
hasColumns = false;
for i = 1:length(paragraphLines)
    line = paragraphLines{i};
    % Check for parameter definitions (quotes and dash)
    if contains(line, '''') && contains(line, '-')
        hasParameters = true;
        break;
    end
    % Check for output definitions (uppercase word followed by dash)
    trimmedLine = strtrim(line);
    if ~isempty(trimmedLine) && ~isempty(regexp(trimmedLine, '^[A-Z][A-Z0-9]*\s*-', 'once'))
        hasOutputs = true;
        break;
    end
    % Check for column definitions (ordinal numbers + col. + dash)
    if ~isempty(trimmedLine) && ~isempty(regexp(trimmedLine, '^\d+(st|nd|rd|th)\s+col\.\s*-', 'once'))
        hasColumns = true;
        break;
    end
end

if hasParameters || hasOutputs || hasColumns
    % For parameter/output/column lists, preserve line breaks and add bullet points
    formattedLines = {};
    for i = 1:length(paragraphLines)
        line = strtrim(paragraphLines{i});
        if ~isempty(line)
            % Check if this line is a parameter definition (starts with quote)
            if startsWith(line, '''')
                % Add bullet point for parameter lines
                formattedLines{end+1} = ['- ' line];
                % Check if this line is an output definition (starts with uppercase word + dash)
            elseif ~isempty(regexp(line, '^[A-Z][A-Z0-9]*\s*-', 'once'))
                % Add bullet point for output lines
                formattedLines{end+1} = ['- ' line];
                % Check if this line is a column definition (ordinal + col. + dash)
            elseif ~isempty(regexp(line, '^\d+(st|nd|rd|th)\s+col\.\s*-', 'once'))
                % Add bullet point for column lines
                formattedLines{end+1} = ['- ' line];
            else
                % Regular line in the parameter/output/column paragraph
                formattedLines{end+1} = line;
            end
        end
    end
    formattedParagraph = strjoin(formattedLines, '\n');
else
    % For regular text, join with spaces
    formattedParagraph = strjoin(paragraphLines, ' ');
end

end

function generateFunctionDoc(moduleDocsDir, functionName, docInfo, module)
% Generate markdown documentation for a function

outputPath = fullfile(moduleDocsDir, [functionName '.md']);

% Create markdown content with brief description
content = sprintf('# `%s` - %s\n\n', functionName, docInfo.briefDescription);

% Add syntax section
content = [content sprintf('## Syntax\n\n')];
content = [content sprintf('```matlab\n')];
if ~isempty(docInfo.syntax)
    for i = 1:length(docInfo.syntax)
        content = [content sprintf('%s\n', docInfo.syntax{i})];
    end
else
    % Fallback if no syntax found
    content = [content sprintf('function result = %s(input)\n', functionName)];
end
content = [content sprintf('```\n\n')];

% Add description section (long description)
content = [content sprintf('## Description\n\n')];
if ~isempty(docInfo.longDescription)
    content = [content sprintf('%s\n\n', docInfo.longDescription)];
else
    content = [content sprintf('%s\n\n', docInfo.briefDescription)];
end

% Add source code link
content = [content sprintf('## Source Code\n\n')];
content = [content sprintf('[View source code](../../../src/%s/%s.m)\n\n', module, functionName)];

% Add examples section
content = [content sprintf('## Examples\n\n')];
if ~isempty(docInfo.examples)
    content = [content sprintf('```matlab\n')];
    content = [content sprintf('%s\n', docInfo.examples)];
    content = [content sprintf('```\n\n')];
else
    content = [content sprintf('```matlab\n')];
    content = [content sprintf('%% Basic usage example\n')];
    content = [content sprintf('result = %s(input);\n', functionName)];
    content = [content sprintf('```\n\n')];
end

% Add see also section
content = [content sprintf('## See Also\n\n')];
if ~isempty(docInfo.seeAlso)
    for i = 1:length(docInfo.seeAlso)
        seeAlsoItem = strtrim(docInfo.seeAlso{i});
        if ~isempty(seeAlsoItem)
            content = [content sprintf('- %s\n', seeAlsoItem)];
        end
    end
    content = [content newline];
end
content = [content sprintf('- [API Reference](../README.md)\n\n')];

content = [content sprintf('---\n\n')];
content = [content sprintf('**Module**: [%s](README.md) | **Status**: 🔄 Auto-generated | **Last Updated**: %s\n', ...
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
content = [content sprintf('- [API Reference](../README.md)\n\n')];

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
    % Collect all functions with their information
    allFunctions = {};
    functionsByModule = struct();
    totalFunctions = 0;

    for i = 1:length(modules)
        module = modules{i};
        srcDir = fullfile(fileparts(docsDir), 'src', module);

        if exist(srcDir, 'dir')
            % Get all .m files in the source module
            mFiles = dir(fullfile(srcDir, '*.m'));
            moduleFunctions = {};

            for j = 1:length(mFiles)
                [~, funcName, ~] = fileparts(mFiles(j).name);

                % Skip private directories and test files
                if startsWith(funcName, 'test') || contains(mFiles(j).folder, 'private')
                    continue;
                end

                % Extract function documentation
                funcPath = fullfile(mFiles(j).folder, mFiles(j).name);
                docInfo = extractFunctionDoc(funcPath, funcName);

                funcInfo = struct();
                funcInfo.name = funcName;
                funcInfo.description = docInfo.briefDescription;

                % Format status with appropriate emoji
                statusText = docInfo.status;
                switch lower(statusText)
                    case 'alpha'
                        funcInfo.status = 'α Alpha';
                    case 'beta'
                        funcInfo.status = 'β Beta';
                    case 'deprecated'
                        funcInfo.status = '❌ Deprecated';
                    case 'stable'
                        funcInfo.status = '✅ Stable';
                    otherwise
                        funcInfo.status = '✅ Stable'; % Default
                end

                funcInfo.module = module;

                moduleFunctions{end+1} = funcInfo;
                allFunctions{end+1} = funcInfo;
                totalFunctions = totalFunctions + 1;
            end

            functionsByModule.(module) = moduleFunctions;
        end
    end

    % Generate the complete API README
    generateApiReadme(docsDir, functionsByModule, allFunctions, totalFunctions);

    fprintf('  ✅ Generated API index with %d total functions\n', totalFunctions);

catch ME
    fprintf('⚠️  Warning: Could not update API index: %s\n', ME.message);
end

end

function generateApiReadme(docsDir, functionsByModule, allFunctions, totalFunctions)
% Generate the complete API README file

apiReadmePath = fullfile(docsDir, 'api', 'README.md');

% Create the content
content = sprintf('# biosigmat API Reference\n\n');
content = [content sprintf('Complete reference documentation for all functions in the biosigmat toolbox.\n\n')];
content = [content sprintf('## Function Categories\n\n')];

% Define module information
moduleInfo = struct();
moduleInfo.ecg = struct('title', 'ECG Processing', 'desc', 'Functions for electrocardiography signal analysis and QRS detection.');
moduleInfo.ppg = struct('title', 'PPG Processing', 'desc', 'Functions for photoplethysmography signal analysis and pulse detection.');
moduleInfo.hrv = struct('title', 'HRV Analysis', 'desc', 'Functions for heart rate variability analysis and metrics calculation.');
moduleInfo.tools = struct('title', 'General Tools', 'desc', 'Utility functions for signal processing and data manipulation.');

% Generate sections for each module
moduleNames = fieldnames(functionsByModule);
for i = 1:length(moduleNames)
    module = moduleNames{i};
    functions = functionsByModule.(module);

    if isempty(functions)
        continue;
    end

    % Add module header
    if isfield(moduleInfo, module)
        content = [content sprintf('### %s\n', moduleInfo.(module).title)];
        content = [content sprintf('%s\n\n', moduleInfo.(module).desc)];
    else
        content = [content sprintf('### %s\n', upper(module))];
        content = [content sprintf('Functions for %s processing.\n\n', module)];
    end

    % Add function table
    content = [content sprintf('| Function | Description | Status |\n')];
    content = [content sprintf('| -------- | ----------- | ------ |\n')];

    for j = 1:length(functions)
        func = functions{j};
        content = [content sprintf('| [`%s`](%s/%s.md) | %s | %s |\n', ...
            func.name, module, func.name, func.description, func.status)];
    end

    content = [content sprintf('\n**[%s Module Documentation](%s/README.md)**\n\n', ...
        upper(module), module)];
end

% Add alphabetical index
content = [content sprintf('## Function Index\n\n')];
content = [content sprintf('### Alphabetical Index\n')];
content = [content sprintf('All functions sorted alphabetically:\n\n')];

% Sort all functions alphabetically
sortedFunctions = allFunctions;
[~, sortIdx] = sort(cellfun(@(x) x.name, sortedFunctions, 'UniformOutput', false));
sortedFunctions = sortedFunctions(sortIdx);

for i = 1:length(sortedFunctions)
    func = sortedFunctions{i};
    content = [content sprintf('- [`%s`](%s/%s.md)\n', func.name, func.module, func.name)];
end

% Add legend and footer
content = [content sprintf('\n\n## Development Status Legend\n')];
content = [content sprintf('- ✅ **Stable**: Well-tested, production ready\n')];
content = [content sprintf('- β **Beta**: Feature complete, undergoing testing\n')];
content = [content sprintf('- α **Alpha**: Under development, API may change\n')];
content = [content sprintf('- ❌ **Deprecated**: No longer recommended for use\n')];

content = [content sprintf('---\n\n')];
content = [content sprintf('*Last updated: %s | Total functions: %d*\n', ...
    string(datetime('now', 'Format', 'yyyy-MM-dd')), totalFunctions)];

% Write the file
try
    fid = fopen(apiReadmePath, 'w', 'n', 'UTF-8');
    if fid == -1
        error('Could not open file for writing: %s', apiReadmePath);
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

content = [content sprintf('## See Also\n\n')];
content = [content sprintf('- [API Reference](../api/README.md)\n\n')];

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