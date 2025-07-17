% tdmetricsExample.m - Example usage of tdmetrics function
%
% This example demonstrates how to use the tdmetrics function to compute
% time domain heart rate variability metrics from ECG R-peak timings.


% Load ECG timing data from CSV file
data = readtable('../../fixtures/ecg/ecg_tk.csv');
tk = data.tk;

% Compute interval series (dtk = diff(tk))
dtk = diff(tk);

% Calculate time domain metrics
metrics = tdmetrics(dtk);

% Display results
fprintf('Time Domain HRV Metrics:\n');
fprintf('========================\n');
fprintf('Mean Heart Rate (mhr):    %.2f beats/min\n', metrics.mhr);
fprintf('SDNN:                     %.2f ms\n', metrics.sdnn);
fprintf('SDSD:                     %.2f ms\n', metrics.sdsd);
fprintf('RMSSD:                    %.2f ms\n', metrics.rmssd);
fprintf('pNN50:                    %.2f %%\n', metrics.pNN50);
