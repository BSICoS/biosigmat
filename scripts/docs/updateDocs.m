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
% 3. Generates/updates corresponding API .md files
% 4. Updates API index files

fprintf('🔄 Starting documentation update...\n');

try
    % Get toolbox root directory (navigate up from scripts/docs/ to project root)
    toolboxRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    srcDir = fullfile(toolboxRoot, 'src');
    docsDir = fullfile(toolboxRoot, 'docs');

    % Ensure docs directory exists
    if ~exist(docsDir, 'dir')
        mkdir(docsDir);
        fprintf('📁 Created docs directory\n');
    end

    % Generated API Markdown is a build artifact. Function headers are the
    % source of truth; CI regenerates these files before MkDocs builds.
    cleanGeneratedDocs(docsDir);

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

    % Update main API index
    updateApiIndex(docsDir, modules);

    fprintf('✅ Documentation update completed successfully!\n');

catch ME
    fprintf('❌ Error updating documentation: %s\n', ME.message);
    rethrow(ME);
end

end

function cleanGeneratedDocs(docsDir)
% Remove stale generated API Markdown.

fprintf('Cleaning generated API Markdown...\n');

generatedRoot = fullfile(docsDir, 'api');

removedCount = 0;
if exist(generatedRoot, 'dir')
    generatedFiles = dir(fullfile(generatedRoot, '**', '*.md'));
    for fileIndex = 1:numel(generatedFiles)
        filePath = fullfile(generatedFiles(fileIndex).folder, generatedFiles(fileIndex).name);
        if exist(filePath, 'file')
            delete(filePath);
            removedCount = removedCount + 1;
        end
    end
end

fprintf('Removed %d generated Markdown files.\n', removedCount);

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

    %#ok<*AGROW>
end

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

        % Clean up the See also list.
        cleanSeeAlso = {};
        for j = 1:length(seeAlsoList)
            item = strtrim(seeAlsoList{j});
            if ~isempty(item)
                cleanSeeAlso{end+1} = item;
            end
        end
        docInfo.seeAlso = cleanSeeAlso;
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
content = sprintf('# `%s`\n\n', functionName);
content = [content sprintf('%s\n\n', docInfo.briefDescription)];

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
content = [content sprintf('## Source\n\n')];
content = [content sprintf('[View source code](https://github.com/BSICoS/biosigmat/blob/main/src/%s/%s.m)\n\n', module, functionName)];

% Link a matching executable example outside tools.
exampleExists = false;
if ~strcmp(module, 'tools')
    toolboxRoot = fileparts(fileparts(fileparts(moduleDocsDir)));
    examplePath = fullfile(toolboxRoot, 'examples', module, [functionName 'Example.m']);
    exampleExists = exist(examplePath, 'file') == 2;
end

% Include examples only when the source provides useful content.
if ~isempty(docInfo.examples) || exampleExists
    content = [content sprintf('## Example\n\n')];
end
if ~isempty(docInfo.examples)
    content = [content sprintf('```matlab\n')];
    content = [content sprintf('%s\n', docInfo.examples)];
    content = [content sprintf('```\n\n')];
end

if exampleExists
    content = [content sprintf('[View executable example](https://github.com/BSICoS/biosigmat/blob/main/examples/%s/%sExample.m)\n\n', module, functionName)];
end

% Add see also section
if ~isempty(docInfo.seeAlso)
    content = [content sprintf('## See also\n\n')];
    for i = 1:length(docInfo.seeAlso)
        seeAlsoItem = strtrim(docInfo.seeAlso{i});
        if ~isempty(seeAlsoItem)
            content = [content sprintf('- %s\n', seeAlsoItem)];
        end
    end
    content = [content newline];
end

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

function updateApiIndex(docsDir, modules)
% Update the main API index file

fprintf('📋 Updating API index...\n');

try
    % Collect functions by source module.
    functionsByModule = struct();

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

                funcInfo.module = module;

                moduleFunctions{end+1} = funcInfo;
            end

            moduleKey = matlab.lang.makeValidName(erase(module, '+'));
            functionsByModule.(moduleKey) = moduleFunctions;
        end
    end

    % Generate the complete API index.md
    generateApiIndex(docsDir, functionsByModule);

    fprintf('  ✅ Generated API index\n');

catch ME
    fprintf('⚠️  Warning: Could not update API index: %s\n', ME.message);
end

end

function generateApiIndex(docsDir, functionsByModule)
% Generate the complete API index.md file

apiReadmePath = fullfile(docsDir, 'api', 'index.md');

% Create the content
content = sprintf('# API\n\n');
content = [content sprintf(['The API pages document MATLAB signatures and link to executable examples. ' ...
    'For expected inputs and outputs, scientific interpretation, limitations, and references, use the ' ...
    '[Biosiglib method catalog](https://bsicos.github.io/biosiglib/methods/).\n'])];

% Define module information
moduleInfo = struct();
moduleInfo.ecg = 'ECG';
moduleInfo.ppg = 'PPG';
moduleInfo.resp = 'Respiration';
moduleInfo.hrv = 'HRV';
moduleInfo.tools = 'Tools';
moduleInfo.biosigmat = 'Package';

% Generate sections for each module
moduleNames = fieldnames(functionsByModule);
for i = 1:length(moduleNames)
    moduleKey = moduleNames{i};
    functions = functionsByModule.(moduleKey);

    if isempty(functions)
        continue;
    end

    module = functions{1}.module;

    % Add a direct function table for the module.
    if isfield(moduleInfo, moduleKey)
        content = [content sprintf('\n## %s\n\n', moduleInfo.(moduleKey))];
    else
        content = [content sprintf('\n## %s\n\n', upper(module))];
    end

    content = [content sprintf('| Function | Description |\n')];
    content = [content sprintf('| --- | --- |\n')];

    for j = 1:length(functions)
        func = functions{j};
        content = [content sprintf('| [`%s`](%s/%s.md) | %s |\n', ...
            func.name, module, func.name, func.description)];
    end
end

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

% End of documentation generator.
