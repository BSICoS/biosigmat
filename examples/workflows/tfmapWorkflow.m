% TFMAPWORKFLOW Workflow demonstrating time-frequency analysis of synthetic signals.
%
% This workflow demonstrates how to create comprehensive time-frequency maps of
% synthetic signals using advanced signal processing techniques. The process begins
% by generating a synthetic chirp signal with time-varying dominant frequency to
% simulate real-world signal characteristics. The signal is then systematically
% sliced into overlapping 20-second segments with 50% overlap to ensure adequate
% temporal resolution. Power spectral density is computed for each segment using
% the nanpwelch function, creating a matrix of frequency content over time. Finally,
% the results are visualized as a time-frequency plot that reveals how the signal's
% spectral characteristics evolve over time, providing valuable insights for
% understanding non-stationary signal behavior.


% Add required paths for source code
addpath(fullfile('..', '..', 'src', 'tools'));

fs = 256;
signalDuration = 120;
t = (0:1/fs:signalDuration)';

% Generate synthetic chirp signal with variable dominant frequency
% Chirp from 5 Hz to 30 Hz over the signal duration
f0 = 5;
f1 = 30;
signal = chirp(t, f0, signalDuration, f1) + 0.1 * randn(size(t));
signal = signal(:);

% Slice signal into 20-second segments with 50% overlap
segmentDuration = 20;
segmentSamples = round(segmentDuration * fs);
overlapPercent = 0.5;
overlapSamples = round(segmentSamples * overlapPercent);

[slicedSignal, tcenter] = slicesignal(signal, segmentSamples, overlapSamples, fs);

% Compute power spectral density matrix using pwelch
windowLength = 512;
noverlap = round(windowLength * 0.5);
nfft = 1024;

[pxx, f] = nanpwelch(slicedSignal, windowLength, noverlap, nfft, fs, []);

% Create time-frequency plot
figure;
imagesc(tcenter, f, 10*log10(pxx));
axis xy;
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('Time-Frequency Map of Chirp Signal');
colorbar;
ylabel(colorbar, 'Power (dB)');
ylim([0 50]);
grid on;
