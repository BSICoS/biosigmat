% Tests covering:
%   - Basic functionality with real ECG from fixtures
%   - Edge cases (few peaks, boundary peaks)
%   - Parameter validation
%   - Invalid input error handling (empty, scalar, non-numeric inputs)
%   - Special input types (logical arrays)
%   - Boundary conditions and edge cases

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
            tc.verifyTrue(exist(fullfile(fixturesPath, 'ecg_tk.csv'), 'file') > 0, ...
                'ecg_tk.csv not found in fixtures path');
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
            peaksData = readtable(fullfile(fixturesPath, 'ecg_tk.csv'));

            % Extract signals
            ecg = signalsData.ecg(:);
            resp = signalsData.resp(:);
            tk = peaksData.tk(:);

            % Compute derivative of ECG (sloperange expects decg, not ecg)
            b = lpdfilter(tc.fs, 50, 'Order', 4);
            decg = nanfilter(b, 1, ecg, 0);
        end
    end

    methods (Test)
        function testBasicFunctionality(tc)
            try
                [decg, tk, ~] = tc.loadFixtureData();

                edr = sloperange(decg, tk, tc.fs);

                % Verify results
                tc.verifySize(edr, [length(tk), 1], 'EDR should have same length as number of peaks');
                tc.verifyGreaterThan(edr(~isnan(edr)), 0, 'EDR values should be positive');
                tc.verifyEqual(length(unique(edr)) > 1, true, 'EDR values should not all be identical');

                % Check for expected respiration pattern
                fsInterp = 4;
                tEdr = tk;
                tInterp = (tEdr(1):1/fsInterp:tEdr(end))';

                edrInterp = interp1(tEdr(~isnan(edr)), edr(~isnan(edr)), tInterp, 'pchip');
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

        function testIOValidation(tc)
            try
                [decg, tk, ~] = tc.loadFixtureData();

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
                tc.verifySize(upmaxpos, [length(tk), 1], 'Upmaxpos should have same length as peaks');
                tc.verifySize(downminpos, [length(tk), 1], 'Downminpos should have same length as peaks');
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

                respResampled = interp1(t, resp, tValid, 'pchip');
                edrResampled = interp1(tk(~isnan(edr)), edr(~isnan(edr)), tValid, 'pchip');

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

        function testIncompleteWindowsAtBoundaries(tc)
            try
                [decg, tk, ~] = tc.loadFixtureData();

                longWindow = round(tc.fs * 0.05);  % 50 ms window (same as in sloperange)
                nk = round(tk * tc.fs) + 1;

                % Truncate the signal so that first and last peaks have incomplete windows
                startSample = nk(1) - longWindow + 5; % Leave only 5 samples before upslope window
                endSample = nk(end) + longWindow - 5; % Leave only 5 samples after downslope window

                truncatedDecg = decg(max(1,startSample):min(length(decg),endSample));
                adjustedTk = tk - (startSample - 1) / tc.fs;

                edr = sloperange(truncatedDecg, adjustedTk, tc.fs);

                % Verify EDR has same length as tk
                tc.verifySize(edr, [length(adjustedTk), 1], ...
                    'EDR should have same length as tk even with boundary incomplete windows');

                % Verify first and last values are NaN
                tc.verifyTrue(isnan(edr(1)), ...
                    'First EDR value should be NaN when first beat has incomplete window');
                tc.verifyTrue(isnan(edr(end)), ...
                    'Last EDR value should be NaN when last beat has incomplete window');

                % Verify middle values are not NaN
                middleValues = edr(2:end-1);
                tc.verifyTrue(~any(isnan(middleValues)), ...
                    'Middle EDR values should not be NaN when beats have complete windows');
                tc.verifyTrue(all(middleValues > 0), ...
                    'Valid EDR values should be positive');
            catch e
                tc.verifyTrue(false, ['Error in incomplete windows test: ' e.message]);
            end
        end

        function testEmptyInput(tc)
            [decg, tk, ~] = tc.loadFixtureData();
            tc.verifyError(@() sloperange([], tk, tc.fs), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Empty DECG input should throw inputParser validation error');
            tc.verifyError(@() sloperange(decg, [], tc.fs), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Empty TK input should throw inputParser validation error');
        end

        function testInvalidInputTypes(tc)
            [decg, tk, ~] = tc.loadFixtureData();
            tc.verifyError(@() sloperange('string', tk, tc.fs), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Non-numeric DECG input should throw inputParser validation error');
            tc.verifyError(@() sloperange(['a', 'b', 'c'], tk, tc.fs), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Character array DECG input should throw inputParser validation error');
            tc.verifyError(@() sloperange(decg > 0, tk, tc.fs), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Logical DECG input should throw inputParser validation error');
            tc.verifyError(@() sloperange(1, tk, tc.fs), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Scalar DECG input should throw inputParser validation error');
        end

        function testInvalidSamplingFrequency(tc)
            try
                [decg, tk, ~] = tc.loadFixtureData();
                tc.verifyError(@() sloperange(decg, tk, 0), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                    'Zero sampling frequency must throw inputParser validation error');

                tc.verifyError(@() sloperange(decg, tk, -100), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                    'Negative sampling frequency must throw inputParser validation error');
            catch e
                tc.verifyTrue(false, ['Error in invalid sampling frequency test: ' e.message]);
            end
        end

        function testMismatchedInputSizes(tc)
            try
                [decg, ~, ~] = tc.loadFixtureData();
                shortDecg = decg(1:1000); % Short signal (about 4 seconds at 256 Hz)

                % TK values that exceed signal duration
                invalidTk = [1.0, 2.0, 10.0]; % 10 seconds exceeds signal length

                tc.verifyError(@() sloperange(shortDecg, invalidTk, tc.fs), '', ...
                    'R-wave indices must be within the bounds of the ECG signal');
            catch e
                tc.verifyTrue(false, ['Error in mismatched input sizes test: ' e.message]);
            end
        end
    end
end