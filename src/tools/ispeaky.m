function isPeaky = ispeaky(pkl, akl, pklThreshold, aklThreshold)
% ISPEAKY Determines if spectra are considered peaky based on peakedness thresholds.
%
%   ISPEAKY = ISPEAKY(PKL, AKL, PKLTHRESHOLD, AKLTHRESHOLD) determines if spectra
%   are considered peaky based on peakedness thresholds. ISPEAKY is a logical array
%   indicating which spectra meet both criteria (PKL >= PKLTHRESHOLD and
%   AKL >= AKLTHRESHOLD).
%
%   Example:
%     % Using with peakedness function output
%     [pxx, f] = periodogram(signal, [], [], fs);
%     [pkl, akl] = peakedness(pxx, f, 0.3);
%     isPeaky = ispeaky(pkl, akl, 45, 85);
%
%     % Using with separate arrays
%     pkl = [30; 50; 70];
%     akl = [80; 90; 95];
%     isPeaky = ispeaky(pkl, akl, 45, 85);
%     % Result: [false; true; true] (only 2nd and 3rd spectra are peaky)
%
%   See also PEAKEDNESS, PERIODOGRAM

% Check number of input and output arguments
narginchk(4, 4);
nargoutchk(0, 1);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'ispeaky';
addRequired(parser, 'pkl', @(x) isnumeric(x) && ~isempty(x));
addRequired(parser, 'akl', @(x) isnumeric(x) && ~isempty(x));
addRequired(parser, 'ksi_p', @(x) isnumeric(x) && isscalar(x) && x >= 0 && x <= 100);
addRequired(parser, 'ksi_a', @(x) isnumeric(x) && isscalar(x) && x >= 0 && x <= 100);
parse(parser, pkl, akl, pklThreshold, aklThreshold);

pkl = parser.Results.pkl;
akl = parser.Results.akl;
pklThreshold = parser.Results.ksi_p;
aklThreshold = parser.Results.ksi_a;

% Validate that pkl and akl have the same dimensions
if ~isequal(size(pkl), size(akl))
    error('ispeaky:DimensionMismatch', ...
        'pkl and akl arrays must have the same dimensions');
end

% Determine if spectra are peaky based on both criteria
isPeaky = pkl >= pklThreshold & akl >= aklThreshold;

end
