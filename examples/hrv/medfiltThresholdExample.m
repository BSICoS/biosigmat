% MEDFILTHRESHOLD EXAMPLE

% The example includes:
%   - Loading real ECG tk data from fixtures
%   - Creating artificial gaps by removing some beats
%   - Applying medfiltThreshold to detect outliers
%   - Visualizing the results

% Add required paths
addpath('../../src/hrv');

% Load real ECG tk data from fixtures
tkData = readtable('../../fixtures/ecg/ecg_tk.csv');
tk = tkData.tk;
dtk = diff(tk);

% Create artificial gaps by removing some beats randomly
rng(42);
numBeats = length(tk);
numToRemove = round(numBeats * 0.08);
indicesToRemove = randperm(numBeats-2, numToRemove) + 1;

% Create modified tk times with gaps
tkWithGaps = tk;
tkWithGaps(indicesToRemove) = [];
dtkWithGaps = diff(tkWithGaps);

% Apply medfiltThreshold to detect outliers
threshold = medfiltThreshold(dtkWithGaps);
outliers = dtkWithGaps > threshold;

% Outlier-removed (OR) intervals
dtkWithoutOutliers = dtkWithGaps(~outliers);


%% Create visualization

figure;
plot(cumsum(dtkWithoutOutliers), dtkWithoutOutliers, 'b-', 'LineWidth', 1.5);
hold on;
plot(cumsum(dtkWithGaps), dtkWithGaps, 'r-', 'LineWidth', 1);
xlabel('Time (s)');
ylabel('Interval (s)');
title('Outlier-removed intervals vs Intervals with gaps');
legend('Outlier-removed intervals', 'With gaps', 'Location', 'best');
grid on;