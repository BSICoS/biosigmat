% Tests covering:
%   - Basic functionality with real ECG from fixtures
%   - Edge cases (few peaks, boundary peaks)
%   - Parameter validation

classdef sloperangeTest < matlab.unittest.TestCase
    properties
        fixturesDir = fullfile('..', '..', 'fixtures', 'ecg');
        fs = 256; % Sampling frequency for CSV data
    end    methods (TestClassSetup)
        function addCodeToPath(tc)
            % Add source path for the function under test
            addpath(fullfile('..', '..', 'src', 'ecg'));
            % Add path for the slider function
            addpath(fullfile('..', '..', 'src', 'tools'));
            % Add fixtures path - ensure we use the fully qualified path
            addpath(fullfile(pwd, '..', '..', 'fixtures', 'ecg'));

            % Verify functions are available
            tc.verifyTrue(~isempty(which('sloperange')), 'sloperange function not found in path');
            tc.verifyTrue(~isempty(which('slider')), 'slider function not found in path');

            % Check fixture files exist
            fixturesPath = fullfile(pwd, '..', '..', 'fixtures', 'ecg');
            tc.verifyTrue(exist(fullfile(fixturesPath, 'edr_signals.csv'), 'file') > 0, ...
                'edr_signals.csv not found in fixtures path');
            tc.verifyTrue(exist(fullfile(fixturesPath, 'edr_tk.csv'), 'file') > 0, ...
                'edr_tk.csv not found in fixtures path');
        end
    end
    methods (Access = private)
        function fixturesPath = getFixturesPath(~)
            % Get the full path to the fixtures directory
            fixturesPath = fullfile(pwd, '..', '..', 'fixtures', 'ecg');
        end

        function [decg, tk, resp] = loadFixtureData(tc)
            % Load ECG signals and R-peaks from CSV files
            fixturesPath = tc.getFixturesPath();

            % Load the signals and R-peaks from CSV files
            signalsData = readtable(fullfile(fixturesPath, 'edr_signals.csv'));
            peaksData = readtable(fullfile(fixturesPath, 'edr_tk.csv'));

            % Extract signals
            ecg = signalsData.ecg(:); % Ensure column vector
            tk = peaksData.tk; % Pre-calculated R-peaks in seconds
            resp = signalsData.resp; % Respiration signal

            % Compute derivative of ECG (sloperange expects decg, not ecg)
            decg = diff(ecg);
            decg = [decg(1); decg]; % Maintain same length as original ECG
        end
    end
    methods (Test)
        function testBasicFunctionality(tc)
            % Load real ECG data from CSV files using correct filenames
            try
                % Load data using helper method
                [decg, tk, ~] = tc.loadFixtureData();

                % Execute function under test
                edr = sloperange(decg, tk, tc.fs);

                % Verify results
                tc.verifySize(edr, [length(tk), 1], 'EDR should have same length as number of peaks');
                tc.verifyGreaterThan(edr, 0, 'EDR values should be positive');
                tc.verifyEqual(length(unique(edr)) > 1, true, 'EDR values should not all be identical');

                % Check for expected respiration pattern
                if length(edr) > 20
                    % Use frequency-domain analysis instead of peak detection
                    % This is more robust for respiratory rate estimation

                    % Interpolate EDR to a regular time grid for frequency analysis
                    fs_interp = 4; % Hz, 4 Hz is sufficient for respiration
                    t_edr = tk; % Time points of the EDR samples
                    t_regular = (t_edr(1):1/fs_interp:t_edr(end))'; % Regular time grid

                    % Interpolate to regular grid
                    edr_regular = interp1(t_edr, edr, t_regular, 'pchip');

                    % Remove linear trend
                    edr_detrended = detrend(edr_regular);

                    % Get power spectral density
                    windowLength = min(round(fs_interp * 30), length(edr_detrended)); % 30-second window or shorter
                    noverlap = round(windowLength * 0.5); % 50% overlap
                    nfft = 2^nextpow2(windowLength * 2); % For better frequency resolution

                    [pxx, f] = pwelch(edr_detrended, windowLength, noverlap, nfft, fs_interp);

                    % Find dominant frequency in respiratory band (0.1-0.5 Hz)
                    respBand = (f >= 0.1) & (f <= 0.5);
                    if any(respBand)
                        [~, maxIdx] = max(pxx(respBand));
                        respIndices = find(respBand);
                        dominantFreq = f(respIndices(maxIdx));

                        % Convert to breaths per minute
                        breathsPerMinute = dominantFreq * 60;

                        % Verify physiological plausibility
                        tc.verifyTrue(breathsPerMinute >= 3 && breathsPerMinute <= 30, ...
                            ['Derived breath rate (' num2str(breathsPerMinute) ' bpm) should be physiologically plausible']);
                    end
                end
            catch e
                tc.verifyTrue(false, ['Error loading or processing real data: ' e.message]);
            end
        end
        function testFewPeaks(tc)
            % Test with just two R peaks from real data
            try
                % Load data using helper method
                [decg, allTk, ~] = tc.loadFixtureData();

                % Take just the first two R peaks for this test
                tk = allTk(1:min(2, length(allTk)));

                % Execute function with just two peaks
                edr = sloperange(decg, tk, tc.fs);

                % Verify results
                tc.verifySize(edr, [length(tk), 1], 'EDR should have same number of values as peaks');
                tc.verifyGreaterThan(edr, 0, 'EDR values should be positive');
            catch e
                tc.verifyTrue(false, ['Error in few peaks test: ' e.message]);
            end
        end
        function testBoundaryPeaks(tc)
            % Test with R peaks near the boundaries using real data
            try
                % Load data using helper method
                [decg, allPeaks, ~] = tc.loadFixtureData();

                % Select first and last peaks only
                tk = [allPeaks(1); allPeaks(end)];

                % Execute function with boundary peaks
                edr = sloperange(decg, tk, tc.fs);

                % Verify results
                tc.verifySize(edr, [2, 1], 'EDR should have 2 values');
                tc.verifyGreaterThan(edr, 0, 'EDR values should be positive');
            catch e
                tc.verifyTrue(false, ['Error in boundary peaks test: ' e.message]);
            end
        end
        function testInputValidation(tc)
            % Setup using real data
            try
                % Load data using helper method
                [decg, allTk, ~] = tc.loadFixtureData();

                % Just use first few peaks for this test
                tk = allTk(1:3);

                % Test column vector conversion
                decgRow = decg';
                edr1 = sloperange(decg, tk, tc.fs);
                edr2 = sloperange(decgRow, tk, tc.fs);
                tc.verifyEqual(edr1, edr2, 'Function should handle row vectors correctly');

                % Test with multiple outputs
                [edr3, upslopes, downslopes, upmaxpos, downminpos] = sloperange(decg, tk, tc.fs);
                tc.verifyEqual(size(edr3), [length(tk), 1], 'Function should work with multiple outputs');
                tc.verifySize(upslopes, size(decg), 'Upslopes should have same size as input signal');
                tc.verifySize(downslopes, size(decg), 'Downslopes should have same size as input signal');
                tc.verifySize(upmaxpos, [1, length(tk)], 'Upmaxpos should have same length as peaks');
                tc.verifySize(downminpos, [1, length(tk)], 'Downminpos should have same length as peaks');
            catch e
                tc.verifyTrue(false, ['Error in input validation test: ' e.message]);
            end
        end
        function testComparisonWithRespSignal(tc)
            % Test comparing EDR with actual respiration signal
            try
                % Load data using helper method
                [decg, tk, resp] = tc.loadFixtureData();

                % Create time vector based on sampling rate (note: decg is one sample shorter)
                t = (0:length(decg)-1)' / tc.fs;

                % Calculate EDR using sloperange with the provided R-peaks
                edr = sloperange(decg, tk, tc.fs);

                % Target sampling frequency: 4Hz for comparison
                fsTarget = 4;

                % Create new time vector at target frequency
                tNew = (0:1/fsTarget:t(end))';

                % Create time vector only within the range of tk values
                validIdx = (tNew >= tk(1)) & (tNew <= tk(end));
                tValid = tNew(validIdx);

                % Resample both signals to same timebase
                % Note: resp signal is one sample longer than decg, so we trim it
                respTrimmed = resp(1:length(decg));
                respResampled = interp1(t, respTrimmed, tValid, 'pchip');
                edrResampled = interp1(tk, edr, tValid, 'pchip');

                % Detrend both signals to remove slow drifts
                respDetrended = detrend(respResampled);
                edrDetrended = detrend(edrResampled);

                % Normalize both signals for fair comparison
                respNorm = (respDetrended - mean(respDetrended)) / std(respDetrended);
                edrNorm = (edrDetrended - mean(edrDetrended)) / std(edrDetrended);

                % Compute correlation coefficient
                [r, ~] = corrcoef(respNorm, edrNorm);
                correlation = r(1,2);

                % Verify correlation is significant
                tc.verifyGreaterThan(abs(correlation), 0.3, 'EDR should correlate with respiration signal');

                % Compute Power Spectral Density (PSD) of both signals
                windowLength = round(fsTarget * 30); % 30-second windows
                if length(respNorm) < windowLength
                    windowLength = length(respNorm); % Adjust window if signal is shorter
                end
                noverlap = round(windowLength * 0.5); % 50% overlap
                nfft = 2^nextpow2(windowLength * 2); % For better frequency resolution

                [pxxResp, fResp] = pwelch(respNorm, windowLength, noverlap, nfft, fsTarget);
                [pxxEdr, fEdr] = pwelch(edrNorm, windowLength, noverlap, nfft, fsTarget);

                % Find dominant frequencies in respiratory range (0.1-0.5 Hz)
                respRange = (fResp >= 0.1) & (fResp <= 0.5);
                if sum(respRange) > 0
                    [~, respMaxIdx] = max(pxxResp(respRange));
                    [~, edrMaxIdx] = max(pxxEdr(respRange));

                    respIndices = find(respRange);
                    respPeakFreq = fResp(respIndices(respMaxIdx));
                    edrPeakFreq = fEdr(respIndices(edrMaxIdx));

                    % Calculate relative error in frequency
                    freqError = abs(respPeakFreq - edrPeakFreq) / respPeakFreq * 100;

                    % Verify the error is below 10%
                    tc.verifyLessThan(freqError, 10, 'Respiratory frequency error should be less than 10%');
                end

                % Calculate RMSE between normalized signals
                rmseValue = sqrt(mean((respNorm - edrNorm).^2));
                tc.verifyLessThan(rmseValue, 1.0, 'RMSE between normalized signals should be reasonable');
            catch e
                tc.verifyTrue(false, ['Error in respiration comparison test: ' e.message]);
            end
        end
    end
end