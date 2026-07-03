% Tests covering:
%   - Basic functionality with real ECG from fixtures
%   - Edge cases (few peaks, boundary peaks)
%   - Parameter validation
%   - Invalid input error handling (empty, scalar, non-numeric inputs)
%   - Special input types (logical arrays)
%   - Boundary conditions and edge cases

classdef sloperangeTest < matlab.unittest.TestCase
    properties
        fs = 256;
    end

    properties (TestParameter)
        validConformanceCaseId = {
            'ecg.sloperange.synthetic_positive'
            'ecg.sloperange.synthetic_boundary_nan'
        }
        expectedErrorCaseId = {
            'ecg.sloperange.invalid_r_wave_time_out_of_bounds'
            'ecg.sloperange.invalid_r_wave_times_not_strict'
        }
    end

    methods (TestClassSetup)
        function addCodeToPath(tc)
            addpath(fullfile('..', '..', 'src', 'ecg'));
            addpath(fullfile('..', '..', 'src', 'tools'));
            addpath(fullfile('..', '..', 'test', 'common'));

            % Verify functions are available
            tc.verifyTrue(~isempty(which('sloperange')), 'sloperange function not found in path');

        end
    end

    methods (Access = private)
        function [decg, rWaveTimes, respiration] = loadFixtureData(tc)
            signalsData = loadBiosiglibFixtureTable( ...
                'ecg.medicom_mtd.ecg_respiration', 'signal_table');
            timingData = loadBiosiglibFixtureTable( ...
                'ecg.medicom_mtd.r_wave_timing', 'beat_timing_table', 'r_wave_times');

            ecg = signalsData.ecg(:);
            respiration = signalsData.respiration(:);
            rWaveTimes = timingData.r_wave_times(:);

            % Compute derivative of ECG (sloperange expects decg, not ecg)
            b = lpdfilter(tc.fs, 50, 'Order', 4);
            decg = nanfilter(b, 1, ecg, 0);
        end
    end

    methods (Test)
        function testBiosiglibConformanceCase(tc, validConformanceCaseId)
            caseDefinition = loadBiosiglibConformanceCase(validConformanceCaseId);
            decg = loadBiosiglibConformanceInput(caseDefinition, 'decg');
            rWaveTimes = loadBiosiglibConformanceInput(caseDefinition, 'r_wave_times');
            samplingFrequency = loadBiosiglibConformanceInput( ...
                caseDefinition, 'sampling_frequency');

            edr = sloperange(decg, rWaveTimes, samplingFrequency);

            actualOutputs = struct('edr', edr);
            verifyBiosiglibExpectedOutputs(tc, actualOutputs, caseDefinition);
        end

        function testBiosiglibExpectedError(tc, expectedErrorCaseId)
            caseDefinition = loadBiosiglibConformanceCase(expectedErrorCaseId);
            decg = loadBiosiglibConformanceInput(caseDefinition, 'decg');
            rWaveTimes = loadBiosiglibConformanceInput(caseDefinition, 'r_wave_times');
            samplingFrequency = loadBiosiglibConformanceInput( ...
                caseDefinition, 'sampling_frequency');

            verifyBiosiglibExpectedError(tc, ...
                @() sloperange(decg, rWaveTimes, samplingFrequency), caseDefinition);
        end

        function testBasicFunctionality(tc)
            try
                [decg, rWaveTimes, ~] = tc.loadFixtureData();

                edr = sloperange(decg, rWaveTimes, tc.fs);

                % Verify results
                tc.verifySize(edr, [length(rWaveTimes), 1], 'EDR should have same length as number of R-waves');
                tc.verifyGreaterThan(edr(~isnan(edr)), 0, 'EDR values should be positive');
                tc.verifyEqual(length(unique(edr)) > 1, true, 'EDR values should not all be identical');

                % Check for expected respiration pattern
                fsInterp = 4;
                tEdr = rWaveTimes;
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
                [decg, rWaveTimes, ~] = tc.loadFixtureData();

                % Test column vector conversion
                decgRow = decg';
                edr1 = sloperange(decg, rWaveTimes, tc.fs);
                edr2 = sloperange(decgRow, rWaveTimes, tc.fs);
                tc.verifyEqual(edr1, edr2, 'Function should handle row vectors correctly');

                % Test with multiple outputs
                [edr3, upslopes, downslopes, upmaxpos, downminpos] = sloperange(decg, rWaveTimes, tc.fs);
                tc.verifyEqual(size(edr3), [length(rWaveTimes), 1], 'Function should work with multiple outputs');
                tc.verifySize(upslopes, size(decg), 'Upslopes should have same size as input signal');
                tc.verifySize(downslopes, size(decg), 'Downslopes should have same size as input signal');
                tc.verifySize(upmaxpos, [length(rWaveTimes), 1], 'Upmaxpos should have same length as R-wave times');
                tc.verifySize(downminpos, [length(rWaveTimes), 1], 'Downminpos should have same length as R-wave times');
            catch e
                tc.verifyTrue(false, ['Error in input validation test: ' e.message]);
            end
        end

        function testComparisonWithRespSignal(tc)
            try
                [decg, rWaveTimes, respiration] = tc.loadFixtureData();

                t = (0:length(decg)-1)' / tc.fs;
                edr = sloperange(decg, rWaveTimes, tc.fs);

                fsInterp = 4;
                tInterp = (0:1/fsInterp:t(end))';

                % Create time vector only within the range of rWaveTimes values
                validIdx = (tInterp >= rWaveTimes(1)) & (tInterp <= rWaveTimes(end));
                tValid = tInterp(validIdx);

                respirationResampled = interp1(t, respiration, tValid, 'pchip');
                edrResampled = interp1(rWaveTimes(~isnan(edr)), edr(~isnan(edr)), tValid, 'pchip');

                % Detrend both signals to remove slow drifts
                respirationDetrended = detrend(respirationResampled);
                edrDetrended = detrend(edrResampled);

                % Compute Power Spectral Density (PSD) of both signals
                windowLength = min(round(fsInterp * 30), length(respirationDetrended));
                noverlap = round(windowLength * 0.5);
                nfft = 2^nextpow2(windowLength * 2);
                [pxxResp, fResp] = pwelch(respirationDetrended, windowLength, noverlap, nfft, fsInterp);
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
                [decg, rWaveTimes, ~] = tc.loadFixtureData();

                longWindow = round(tc.fs * 0.05);  % 50 ms window (same as in sloperange)
                nk = round(rWaveTimes * tc.fs) + 1;

                % Truncate the signal so that first and last R-waves have incomplete windows
                startSample = nk(1) - longWindow + 5; % Leave only 5 samples before upslope window
                endSample = nk(end) + longWindow - 5; % Leave only 5 samples after downslope window

                truncatedDecg = decg(max(1,startSample):min(length(decg),endSample));
                adjustedRWaveTimes = rWaveTimes - (startSample - 1) / tc.fs;

                edr = sloperange(truncatedDecg, adjustedRWaveTimes, tc.fs);

                % Verify EDR has same length as rWaveTimes
                tc.verifySize(edr, [length(adjustedRWaveTimes), 1], ...
                    'EDR should have same length as rWaveTimes even with boundary incomplete windows');

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
            [decg, rWaveTimes, ~] = tc.loadFixtureData();
            tc.verifyError(@() sloperange([], rWaveTimes, tc.fs), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Empty DECG input should throw inputParser validation error');
            tc.verifyError(@() sloperange(decg, [], tc.fs), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Empty rWaveTimes input should throw inputParser validation error');
        end

        function testInvalidInputTypes(tc)
            [decg, rWaveTimes, ~] = tc.loadFixtureData();
            tc.verifyError(@() sloperange('string', rWaveTimes, tc.fs), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Non-numeric DECG input should throw inputParser validation error');
            tc.verifyError(@() sloperange(['a', 'b', 'c'], rWaveTimes, tc.fs), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Character array DECG input should throw inputParser validation error');
            tc.verifyError(@() sloperange(decg > 0, rWaveTimes, tc.fs), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Logical DECG input should throw inputParser validation error');
            tc.verifyError(@() sloperange(1, rWaveTimes, tc.fs), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                'Scalar DECG input should throw inputParser validation error');
        end

        function testInvalidSamplingFrequency(tc)
            try
                [decg, rWaveTimes, ~] = tc.loadFixtureData();
                tc.verifyError(@() sloperange(decg, rWaveTimes, 0), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                    'Zero sampling frequency must throw inputParser validation error');

                tc.verifyError(@() sloperange(decg, rWaveTimes, -100), 'MATLAB:InputParser:ArgumentFailedValidation', ...
                    'Negative sampling frequency must throw inputParser validation error');
            catch e
                tc.verifyTrue(false, ['Error in invalid sampling frequency test: ' e.message]);
            end
        end

        function testMismatchedInputSizes(tc)
            try
                [decg, ~, ~] = tc.loadFixtureData();
                shortDecg = decg(1:1000); % Short signal (about 4 seconds at 256 Hz)

                % R-wave time values that exceed signal duration
                invalidRWaveTimes = [1.0, 2.0, 10.0]; % 10 seconds exceeds signal length

                tc.verifyError(@() sloperange(shortDecg, invalidRWaveTimes, tc.fs), '', ...
                    'R-wave indices must be within the bounds of the ECG signal');
            catch e
                tc.verifyTrue(false, ['Error in mismatched input sizes test: ' e.message]);
            end
        end
    end
end
