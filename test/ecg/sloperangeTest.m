% Tests covering:
%   - Basic functionality with real ECG from fixtures
%   - Edge cases (few peaks, boundary peaks)
%   - Parameter validation

classdef sloperangeTest < matlab.unittest.TestCase
    properties
        fixturesDir = fullfile('..', '..', 'fixtures', 'ecg');
        fs = 256;
    end

    methods (TestClassSetup)
        function addCodeToPath(tc)
            addpath(fullfile('..', '..', 'src', 'ecg'));
            addpath(fullfile('..', '..', 'src', 'tools'));
            addpath(fullfile(pwd, '..', '..', 'fixtures', 'ecg'));

            % Verify functions are available
            tc.verifyTrue(~isempty(which('sloperange')), 'sloperange function not found in path');

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
            fixturesPath = fullfile(pwd, '..', '..', 'fixtures', 'ecg');
        end

        function [decg, tk, resp] = loadFixtureData(tc)
            fixturesPath = tc.getFixturesPath();

            % Load the signals and R-peaks from CSV files
            signalsData = readtable(fullfile(fixturesPath, 'edr_signals.csv'));
            peaksData = readtable(fullfile(fixturesPath, 'edr_tk.csv'));

            % Extract signals
            ecg = signalsData.ecg(:);
            tk = peaksData.tk;
            resp = signalsData.resp;

            % Compute derivative of ECG (sloperange expects decg, not ecg)
            decg = diff(ecg);
            decg = [decg(1); decg]; % Maintain same length as original ECG
        end
    end

    methods (Test)
        function testBasicFunctionality(tc)
            try
                [decg, tk, ~] = tc.loadFixtureData();

                edr = sloperange(decg, tk, tc.fs);

                % Verify results
                tc.verifySize(edr, [length(tk), 1], 'EDR should have same length as number of peaks');
                tc.verifyGreaterThan(edr, 0, 'EDR values should be positive');
                tc.verifyEqual(length(unique(edr)) > 1, true, 'EDR values should not all be identical');

                % Check for expected respiration pattern
                fsInterp = 4;
                tEdr = tk;
                tInterp = (tEdr(1):1/fsInterp:tEdr(end))';

                edrInterp = interp1(tEdr, edr, tInterp, 'pchip');
                edrDetrended = detrend(edrInterp);

                % Get power spectral density
                windowLength = min(round(fsInterp * 30), length(edrDetrended));
                noverlap = round(windowLength * 0.5);
                nfft = 2^nextpow2(windowLength * 2);
                [pxx, f] = pwelch(edrDetrended, windowLength, noverlap, nfft, fsInterp);

                % Find dominant frequency in respiratory band (0.1-0.5 Hz)
                respBand = (f >= 0.1) & (f <= 0.5);
                [~, maxIdx] = max(pxx(respBand));
                respIndices = find(respBand);
                dominantFreq = f(respIndices(maxIdx));

                % Convert to breaths per minute
                breathsPerMinute = dominantFreq * 60;

                % Verify physiological plausibility
                tc.verifyTrue(breathsPerMinute >= 3 && breathsPerMinute <= 30, ...
                    ['Derived breath rate (' num2str(breathsPerMinute) ' bpm) should be physiologically plausible']);
            catch e
                tc.verifyTrue(false, ['Error loading or processing real data: ' e.message]);
            end
        end
        function testFewPeaks(tc)
            try
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
            try
                [decg, allPeaks, ~] = tc.loadFixtureData();

                % Select first and last peaks only
                tk = [allPeaks(1); allPeaks(end)];

                edr = sloperange(decg, tk, tc.fs);

                % Verify results
                tc.verifySize(edr, [2, 1], 'EDR should have 2 values');
                tc.verifyGreaterThan(edr, 0, 'EDR values should be positive');
            catch e
                tc.verifyTrue(false, ['Error in boundary peaks test: ' e.message]);
            end
        end
        function testInputValidation(tc)
            try
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
            try
                [decg, tk, resp] = tc.loadFixtureData();

                t = (0:length(decg)-1)' / tc.fs;
                edr = sloperange(decg, tk, tc.fs);

                fsInterp = 4;
                tInterp = (0:1/fsInterp:t(end))';

                % Create time vector only within the range of tk values
                validIdx = (tInterp >= tk(1)) & (tInterp <= tk(end));
                tValid = tInterp(validIdx);

                % Note: resp signal is one sample longer than decg
                respTrimmed = resp(1:length(decg));
                respResampled = interp1(t, respTrimmed, tValid, 'pchip');
                edrResampled = interp1(tk, edr, tValid, 'pchip');

                % Detrend both signals to remove slow drifts
                respDetrended = detrend(respResampled);
                edrDetrended = detrend(edrResampled);

                % Compute Power Spectral Density (PSD) of both signals
                windowLength = min(round(fsInterp * 30), length(respDetrended));
                noverlap = round(windowLength * 0.5);
                nfft = 2^nextpow2(windowLength * 2);
                [pxxResp, fResp] = pwelch(respDetrended, windowLength, noverlap, nfft, fsInterp);
                [pxxEdr, fEdr] = pwelch(edrDetrended, windowLength, noverlap, nfft, fsInterp);

                % Find dominant frequencies in respiratory range (0.1-0.5 Hz)
                respRange = (fResp >= 0.1) & (fResp <= 0.5);

                [~, respMaxIdx] = max(pxxResp(respRange));
                [~, edrMaxIdx] = max(pxxEdr(respRange));

                respIndices = find(respRange);
                respPeakFreq = fResp(respIndices(respMaxIdx));
                edrPeakFreq = fEdr(respIndices(edrMaxIdx));

                % Verify the error is below 10%
                freqError = abs(respPeakFreq - edrPeakFreq) / respPeakFreq * 100;
                tc.verifyLessThan(freqError, 10, 'Respiratory frequency error should be less than 10%');
            catch e
                tc.verifyTrue(false, ['Error in respiration comparison test: ' e.message]);
            end
        end
    end
end