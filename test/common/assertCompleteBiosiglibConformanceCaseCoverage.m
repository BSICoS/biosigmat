function assertCompleteBiosiglibConformanceCaseCoverage(discoveredIds, collectedIds)
%ASSERTCOMPLETEBIOSIGLIBCONFORMANCECASECOVERAGE Reject uncollected cases.

missingIds = setdiff(cellstr(discoveredIds), cellstr(collectedIds));
if ~isempty(missingIds)
    error('biosigmat:IncompleteConformanceCaseCoverage', ...
        'Discovered Biosiglib cases were not collected: %s', ...
        strjoin(missingIds, ', '));
end
end
