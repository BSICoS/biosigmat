function caseIds = getBiosiglibConformanceCaseIds(specificationId)
%GETBIOSIGLIBCONFORMANCECASEIDS Get all cases for one conformant spec.

specificationId = char(specificationId);
manifest = loadBiosigmatConformanceManifest();
manifestField = matlab.lang.makeValidName(specificationId);
if ~isfield(manifest.specifications, manifestField) || ...
        ~strcmp(manifest.specifications.(manifestField).status, 'conformant')
    error('biosigmat:SpecificationNotConformant', ...
        'Specification "%s" is not declared conformant.', specificationId);
end

cases = discoverBiosiglibConformanceCases();
matchingCases = arrayfun(@(item) strcmp( ...
    item.specificationId, specificationId), cases);
caseIds = reshape({cases(matchingCases).id}, [], 1);
if isempty(caseIds)
    error('biosigmat:MissingConformanceCases', ...
        'No Biosiglib cases were discovered for "%s".', specificationId);
end
end
