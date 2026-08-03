function cases = discoverBiosiglibConformanceCases()
%DISCOVERBIOSIGLIBCONFORMANCECASES Discover cases for conformant specs.

biosiglibRoot = getBiosiglibRoot();
manifest = loadBiosigmatConformanceManifest();
caseFiles = dir(fullfile(biosiglibRoot, 'conformance', '*', '*', '*.json'));

cases = struct('id', {}, 'specificationId', {});
seenCaseIds = containers.Map('KeyType', 'char', 'ValueType', 'logical');
for iFile = 1:numel(caseFiles)
    casePath = fullfile(caseFiles(iFile).folder, caseFiles(iFile).name);
    caseDefinition = jsondecode(fileread(casePath));
    if ~isfield(caseDefinition, 'id') || ...
            ~isfield(caseDefinition, 'specification_id')
        error('biosigmat:InvalidConformanceCase', ...
            'Conformance case must declare id and specification_id: %s', casePath);
    end

    specificationId = char(caseDefinition.specification_id);
    manifestField = matlab.lang.makeValidName(specificationId);
    if ~isfield(manifest.specifications, manifestField)
        continue;
    end
    manifestEntry = manifest.specifications.(manifestField);
    if ~strcmp(manifestEntry.status, 'conformant')
        continue;
    end

    [~, caseName] = fileparts(caseFiles(iFile).name);
    expectedCaseId = [specificationId '.' caseName];
    if ~strcmp(caseDefinition.id, expectedCaseId)
        error('biosigmat:ConformanceCaseIdMismatch', ...
            'Conformance case at %s must declare ID "%s".', ...
            casePath, expectedCaseId);
    end
    if isKey(seenCaseIds, caseDefinition.id)
        error('biosigmat:DuplicateConformanceCaseId', ...
            'Duplicate conformance case ID "%s".', caseDefinition.id);
    end

    hasOutputs = isfield(caseDefinition, 'expected_outputs');
    hasError = isfield(caseDefinition, 'expected_error');
    if hasOutputs == hasError
        error('biosigmat:InvalidConformanceCase', ...
            ['Conformance case "%s" must define exactly one of ' ...
            'expected_outputs or expected_error.'], caseDefinition.id);
    end

    seenCaseIds(caseDefinition.id) = true;
    cases(end + 1).id = char(caseDefinition.id); %#ok<AGROW>
    cases(end).specificationId = specificationId;
end

if ~isempty(cases)
    [~, order] = sort({cases.id});
    cases = cases(order);
end

manifestFields = fieldnames(manifest.specifications);
for iSpecification = 1:numel(manifestFields)
    manifestEntry = manifest.specifications.(manifestFields{iSpecification});
    if ~strcmp(manifestEntry.status, 'conformant')
        continue;
    end
    matchingCases = arrayfun(@(item) strcmp( ...
        matlab.lang.makeValidName(item.specificationId), ...
        manifestFields{iSpecification}), cases);
    if ~any(matchingCases)
        error('biosigmat:MissingConformanceCases', ...
            ['No Biosiglib conformance cases were discovered for conformant ' ...
            'manifest entry "%s".'], manifestFields{iSpecification});
    end
end
end
