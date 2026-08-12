function specificationIds = discoverBiosiglibSpecificationIds()
%DISCOVERBIOSIGLIBSPECIFICATIONIDS Get every spec ID from the pinned checkout.

biosiglibRoot = getBiosiglibRoot();
specificationFiles = dir(fullfile(biosiglibRoot, 'specs', '*', '*', 'spec.json'));
specificationIds = cell(numel(specificationFiles), 1);
for iFile = 1:numel(specificationFiles)
    specificationPath = fullfile( ...
        specificationFiles(iFile).folder, specificationFiles(iFile).name);
    specification = jsondecode(fileread(specificationPath));
    if ~isfield(specification, 'metadata') || ...
            ~isfield(specification.metadata, 'id')
        error('biosigmat:InvalidBiosiglibSpecification', ...
            'Biosiglib specification has no canonical ID: %s', ...
            specificationPath);
    end
    specificationIds{iFile} = char(specification.metadata.id);
end

if isempty(specificationIds)
    error('biosigmat:MissingBiosiglibSpecifications', ...
        'No Biosiglib specifications were found in the pinned checkout.');
end
if numel(unique(specificationIds)) ~= numel(specificationIds)
    error('biosigmat:DuplicateBiosiglibSpecificationId', ...
        'The pinned Biosiglib checkout contains duplicate specification IDs.');
end
specificationIds = sort(specificationIds);
end
