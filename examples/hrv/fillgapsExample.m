% FILLGAPSEXAMPLE Example demonstrating gap filling in RR interval time series.
%
% This example demonstrates how to fill gaps in RR interval time series using the
% fillgaps function. The process involves loading ECG timing data from a CSV file,
% simulating missing detections by removing some R-peak timing values, and then
% applying the gap filling algorithm to interpolate the missing intervals. The
% example shows the comparison between original and filled RR interval series
% through visualization, highlighting the effectiveness of the gap filling
% algorithm in maintaining physiological plausibility of the RR intervals.

% Add required paths
addpath('../../src/tools');
addpath('../../src/hrv');

% Load ECG timing data from CSV file
data = readtable('../../fixtures/ecg/ecg_tk.csv');
tk = data.tk;
tk = tk(1:100);

% Randomly remove 10-15% of the detections to create gaps
rng(40);
originalLength = length(tk);
numToRemove = round(0.1 * originalLength) + randi(round(0.05 * originalLength));
indicesToRemove = sort(randperm(originalLength, numToRemove));
tkRemoved = tk;
tkRemoved(indicesToRemove) = [];

% Fill gaps in the event series
tn = fillgaps(tkRemoved,true);

%% Visualize the original and filled RR interval series
figure;
plot(tk, 'o-', 'DisplayName', 'Original RR Intervals');
hold on;
plot(tn, 'x-', 'DisplayName', 'Filled RR Intervals');
xlabel('Sample Index');
ylabel('RR Interval (ms)');
title('Comparison of Original and Filled RR Intervals');
legend show;
grid on;