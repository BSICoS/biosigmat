function caseIds = getBiosiglibConformanceCaseIds(specificationId)
%GETBIOSIGLIBCONFORMANCECASEIDS Get all cases for one pinned spec.

specificationId = char(specificationId);
if ~ismember(specificationId, discoverBiosiglibSpecificationIds())
    error('biosigmat:UnknownBiosiglibSpecification', ...
        'Unknown Biosiglib specification "%s".', specificationId);
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
