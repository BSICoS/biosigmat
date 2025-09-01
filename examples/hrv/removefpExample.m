% REMOVEFPEXAMPLE Example demonstrating false positive removal from RR interval time series.
%
% This example demonstrates how to remove false positive detections from RR
% interval time series using the removefp function. The process involves loading
% ECG timing data from a CSV file and applying the false positive removal
% algorithm to eliminate beats that are too close together. The example shows
% the comparison between original and cleaned RR interval series through
% visualization, highlighting the effectiveness of the false positive removal
% algorithm in improving signal quality.

% Add required paths
addpath('../../src/tools');
addpath('../../src/hrv');

% Load ECG timing data from CSV file
data = readtable('../../fixtures/ecg/ecg_tk.csv');
tk = data.tk;
tk = tk(1:50);

% Insert synthetic false positives to demonstrate the algorithm
tkWithFPs = tk;
fpIndices = [10, 20, 30]; % Insert FPs after these beats
fpOffsets = [0.05, 0.08, 0.06]; % Very short intervals (50-80ms)

for i = 1:length(fpIndices)
    idx = fpIndices(i);
    fpBeat = tk(idx) + fpOffsets(i);
    tkWithFPs = [tkWithFPs; fpBeat]; %#ok<AGROW>
end

% Sort the series with false positives
tkWithFPs = sort(tkWithFPs);

% Apply false positive removal
tkCleaned = removefp(tkWithFPs);

% Compute interval series
dtkWithFPs = diff(tkWithFPs);
dtkCleaned = diff(tkCleaned);

%% Plot results
figure;
subplot(2,1,1);
stem(dtkWithFPs, 'r');
title('RR Intervals with False Positives');
ylabel('RR Interval (s)');

subplot(2,1,2);
stem(dtkCleaned, 'g');
title('Cleaned RR Intervals (False Positives Removed)');
ylabel('RR Interval (s)');
xlabel('Beat Index');

% Display summary statistics
fprintf('Original number of beats: %d\n', length(tk));
fprintf('With false positives: %d\n', length(tkWithFPs));
fprintf('Cleaned number of beats: %d\n', length(tkCleaned));
fprintf('Removed beats: %d\n', length(tkWithFPs) - length(tkCleaned));
fprintf('Minimum interval (with FPs): %.3f s\n', min(dtkWithFPs));
fprintf('Minimum interval (cleaned): %.3f s\n', min(dtkCleaned));
