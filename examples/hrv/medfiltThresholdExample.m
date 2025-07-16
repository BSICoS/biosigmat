% MEDFILTHRESHOLD EXAMPLE

% The example includes:
%   - Loading real ECG tk data from fixtures
%   - Creating artificial gaps by removing some beats
%   - Applying medfiltThreshold to detect outliers
%   - Visualizing the results

% Add required paths
addpath('../../src/hrv');

% Load real ECG tk data from fixtures
fprintf('Loading ECG data from fixtures...\n');
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

% Compute adaptive threshold using different parameters
thresholdDefault = medfiltThreshold(dtkWithGaps);
thresholdStrict = medfiltThreshold(dtkWithGaps, 30, 1.2, 1.0);
thresholdLenient = medfiltThreshold(dtkWithGaps, 70, 2.0, 2.0);

% Detect outliers using different thresholds
outliersDefault = dtkWithGaps > thresholdDefault;
outliersStrict = dtkWithGaps > thresholdStrict;
outliersLenient = dtkWithGaps > thresholdLenient;


%% Create visualization
figure;

% Plot 1: Original vs Modified intervals
subplot(2, 1, 1);
plot(cumsum(dtk), dtk, 'b-', 'LineWidth', 1.5);
hold on;
plot(cumsum(dtkWithGaps), dtkWithGaps, 'r-', 'LineWidth', 1);
xlabel('Beat Number');
ylabel('Interval (s)');
title('Original vs Modified Intervals');
legend('Original', 'With Gaps', 'Location', 'best');
grid on;

% Plot 2: Comparison of different threshold strategies
subplot(2, 1, 2);
plot(cumsum(dtkWithGaps), dtkWithGaps, 'k-', 'LineWidth', 1);
hold on;
plot(cumsum(dtkWithGaps), thresholdDefault, 'g-', 'LineWidth', 1.5);
plot(cumsum(dtkWithGaps), thresholdStrict, 'r-', 'LineWidth', 1.5);
plot(cumsum(dtkWithGaps), thresholdLenient, 'b-', 'LineWidth', 1.5);
xlabel('Beat Number');
ylabel('Interval (s)');
title('Threshold Comparison');
legend('Intervals', 'Default', 'Strict', 'Lenient', 'Location', 'best');
grid on;