% PCAVERAGEWORKFLOW Workflow demonstrating peak-conditioned average processing.
%
% This workflow demonstrates the peak-conditioned average processing technique
% applied to respiratory signal analysis. The process begins by loading respiratory
% signal data from CSV fixture files and applying detrending to remove linear
% trends that could affect the analysis. The signal is then systematically sliced
% into segments for processing. Power spectral density is computed for each segment
% using the nanpwelch function, enabling frequency-domain analysis of the respiratory
% patterns. This workflow is particularly useful for analyzing periodic respiratory
% signals and extracting spectral characteristics that can provide insights into
% breathing patterns and respiratory system behavior.


% Add required paths for source code
addpath(fullfile('..', '..', 'src', 'tools'));

% Load the respiratory signal from edr_signals.csv
dataFile = fullfile('..', '..', 'fixtures', 'ecg', 'edr_signals.csv');
data = readtable(dataFile);

% Extract respiratory signal and time vector
respSignal = data.resp;
timeVector = data.t;

% Calculate sampling frequency from time vector
fs = 1 / (timeVector(2) - timeVector(1));

% Apply detrend to remove linear trends
respSignal = detrend(respSignal);

% Slice signal
segmentDuration = 30;
segmentSamples = round(segmentDuration * fs);
overlapDuration = 15;
overlapSamples = round(overlapDuration * fs);

[slicedSignal, tcenter] = slicesignal(respSignal, segmentSamples, overlapSamples, fs);

% Compute power spectral density segments using nanpwelch
window = hamming(segmentSamples/3);
noverlap = segmentSamples/6;
nfft = 2^nextpow2(segmentSamples);

[pxx, f, pxxSegments] = nanpwelch(slicedSignal, window, noverlap, nfft, fs);

% Compute peakedness for each pxxSegments cell
% Each cell contains multiple spectra (columns), get peakedness for each
pcpxx = zeros(size(pxx));
for i = 1:length(pxxSegments)
    if ~isempty(pxxSegments{i})
        [pklValues, aklValues] = peakedness(pxxSegments{i}, f);
        peakySegments = ispeaky(pklValues, aklValues, 25, 25);
        pcpxx(:, i) = mean(pxxSegments{i}(:, peakySegments), 2);
    else
        pcpxx(:, i) = [];
    end
end

% Plot the results
figure;
subplot(2, 1, 1);
imagesc(tcenter, f, 10*log10(pxx));
xlabel('Frequency (Hz)');
ylabel('Power/Frequency (dB/Hz)');
title('Average Power Spectral Density');
ylim([0 5])
grid on;

subplot(2, 1, 2);
imagesc(tcenter, f, 10*log10(pcpxx));
xlabel('Frequency (Hz)');
ylabel('Power/Frequency (dB/Hz)');
title('Peak-Conditioned Average Power Spectral Density');
ylim([0 5])
grid on;