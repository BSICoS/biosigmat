% TDMETRICSEXAMPLE Example demonstrating time-domain heart rate variability analysis.
%
% This example demonstrates how to compute time-domain heart rate variability (HRV)
% metrics from ECG R-peak timing data using the tdmetrics function. The process
% begins by loading pre-calculated R-peak timing data from CSV fixture files.
% The R-peak intervals are then computed and used as input to the tdmetrics function,
% which calculates various time-domain HRV parameters including statistical measures
% of RR interval variability.


% Add required paths
addpath('../../src/tools');
addpath('../../src/hrv');

% Load ECG timing data from CSV file
data = readtable('../../fixtures/ecg/ecg_tk.csv');
tk = data.tk;

% Compute interval series (dtk = diff(tk))
dtk = diff(tk);

% Apply medfiltThreshold to detect outliers
threshold = medfiltThreshold(dtk, 50, 1.5, 1.5);
outliers = dtk > threshold;

% Remove outliers
dtkWithoutOutliers = dtk(~outliers);

% Calculate time domain metrics
metrics = tdmetrics(dtkWithoutOutliers);

% Display results
fprintf('Time Domain HRV Metrics:\n');
fprintf('========================\n');
fprintf('Mean Heart Rate (mhr):    %.2f beats/min\n', metrics.mhr);
fprintf('SDNN:                     %.2f ms\n', metrics.sdnn);
fprintf('SDSD:                     %.2f ms\n', metrics.sdsd);
fprintf('RMSSD:                    %.2f ms\n', metrics.rmssd);
fprintf('pNN50:                    %.2f %%\n', metrics.pNN50);
