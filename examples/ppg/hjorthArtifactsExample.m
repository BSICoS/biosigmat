% HJORTHARTIFACTSEXAMPLE Example demonstrating artifact detection using Hjorth parameters.
%
% This example demonstrates how to detect artifacts in photoplethysmography (PPG)
% signals using Hjorth parameters analysis. The process involves loading PPG signal
% data from a CSV file and applying the hjorthArtifacts function to identify
% signal segments that contain artifacts based on activity, mobility, and complexity
% parameters. The example shows how to configure detection margins for different
% Hjorth parameters and visualizes both the artifact detection vector and the
% parameter matrix, providing insights into signal quality assessment for PPG
% analysis applications.

% Add source paths
addpath('../../src/ppg');
addpath('../../src/tools');

% Load PPG signal from fixtures
ppgData = readtable('../../fixtures/ppg/ppg_signals.csv');
ppg = ppgData.sig;
t = ppgData.t;
fs = 1000;

% Normalize -> This helps to establish margins
ppg = normalize(ppg);

% Define parameters
seg = 4;
step = 3;
marginH0 = [5, 1];
marginH1 = [0.5 0.5];
marginH2 = [1, 2];
margins = [marginH0; marginH1; marginH2];

% Get both artifact vector and matrix
[artifactVector, artifactMatrix] = hjorthArtifacts(ppg, fs, seg, step, margins, 'plotflag', true);