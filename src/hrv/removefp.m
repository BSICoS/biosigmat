function tk = removefp(tk)
% REMOVEFP Remove false positive detections from HRV event series.
%
%   TK = REMOVEFP(TK) removes false positive detections from the HRV event
%   series TK by identifying and eliminating beats that are too close together.
%   TK is a vector of event timestamps (beat or pulse occurrence times in seconds).
%   Returns the corrected event series with false positives removed.
%
%   The function uses an adaptive baseline approach to identify intervals
%   that are significantly shorter than expected, indicating likely false
%   positive detections. When such intervals are found, the second beat
%   in the pair is removed.
%
%   Example:
%     % Create synthetic HRV event series with false positives
%     tk = [0, 0.8, 1.6, 1.65, 2.4, 3.2, 4.0, 4.05, 4.8]; % Some beats too close
%     tkCleaned = removefp(tk);
%
%     % Compare intervals before and after
%     dtkOriginal = diff(tk);
%     dtkCleaned = diff(tkCleaned);
%
%     % Plot comparison
%     figure;
%     subplot(2,1,1);
%     stem(dtkOriginal, 'r');
%     title('Original RR Intervals (with false positives)');
%     ylabel('RR Interval (s)');
%
%     subplot(2,1,2);
%     stem(dtkCleaned, 'g');
%     title('Cleaned RR Intervals');
%     ylabel('RR Interval (s)');
%     xlabel('Beat Index');
%
%   See also FILLGAPS, MEDFILTTHRESHOLD
%
%   Status: Alpha


% Check number of input and output arguments
narginchk(1, 1);
nargoutchk(0, 1);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'removefp';
addRequired(parser, 'tk', @(x) isnumeric(x) && isvector(x) && ~isempty(x) && all(isfinite(x)));

parse(parser, tk);

tk = parser.Results.tk;

% Ensure tk is a column vector and sorted
tk = tk(:);
tk = sort(tk);

% Need at least 3 elements to compute intervals and remove false positives
if length(tk) < 3
    return;
end

% Compute inter-beat intervals
dtk = diff(tk);

% Calculate adaptive baseline for RR intervals
baseline = medfiltThreshold(dtk, 30, 1, 1.5);

% Identify intervals that are too short (false positives)
fp = dtk < 0.7 * baseline;

% Remove the second beat in each false positive pair
tk(find(fp) + 1) = [];

end
