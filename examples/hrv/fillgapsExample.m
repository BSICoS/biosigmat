% FILLGAPSEXAMPLE Example demonstrating gap filling in RR interval time series.
%
% This example loads ECG event times, removes some detections to create gaps,
% applies the explicit REMOVEFP then FILLGAPS preprocessing sequence, and compares
% the reference RR intervals with the reconstructed intervals. Set DEBUG to true
% to inspect every reconstruction attempt interactively before this final plot.

% Add required paths
addpath('../../src/tools');
addpath('../../src/hrv');

% Load ECG timing data from CSV file
data = readtable('../../fixtures/ecg/medicom_mtd_r_wave_timing.csv');
tk = data.r_wave_times;
tk = tk(1:100);

% Randomly remove 10-15% of the detections to create gaps
rng(40);
originalLength = length(tk);
numToRemove = round(0.1 * originalLength) + randi(round(0.05 * originalLength));
indicesToRemove = sort(randperm(originalLength, numToRemove));
tkRemoved = tk;
tkRemoved(indicesToRemove) = [];

% Fill gaps in the event series
debug = false; % Set to true to enable debug output
tkCleaned = removefp(tkRemoved);
[~, dtn] = fillgaps(tkCleaned, debug);

%% Visualize the original and filled RR interval series
figure;
plot(diff(tk), 'o-', 'DisplayName', 'Reference RR Intervals');
hold on;
plot(dtn, 'x-', 'DisplayName', 'Filled RR Intervals');
xlabel('Interval Index');
ylabel('RR Interval (s)');
title('Reference and Filled RR Intervals');
legend show;
grid on;
