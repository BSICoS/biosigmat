% Tests covering:
%   - Basic functionality with real ECG from fixtures
%   - Edge cases (few peaks, boundary peaks)
%   - Parameter validation
%   - Plotting functionality

classdef sloperangeTest < matlab.unittest.TestCase
    
    properties
        fixturesDir = fullfile('..', '..', 'test', 'fixtures', 'ecg');
    end
    
    methods (TestClassSetup)
        function addCodeToPath(tc)
            % Add source path for the function under test
            addpath(fullfile('..', '..', 'src', 'ecg'));
            % Add path for the slider function
            addpath(fullfile('..', '..', 'src', 'tools'));
            % Add fixtures path - ensure we use the fully qualified path
            addpath(fullfile(pwd, '..', 'fixtures', 'ecg'));
            
            % Verify functions are available
            tc.verifyTrue(~isempty(which('sloperange')), 'sloperange function not found in path');
            tc.verifyTrue(~isempty(which('slider')), 'slider function not found in path');
            
            % Check fixture files exist
            fixturesPath = fullfile(pwd, '..', 'fixtures', 'ecg');
            tc.verifyTrue(exist(fullfile(fixturesPath, 'edr_signals.csv'), 'file') > 0, ...
                'edr_signals.csv not found in fixtures path');
            tc.verifyTrue(exist(fullfile(fixturesPath, 'edr_tk.csv'), 'file') > 0, ...
                'edr_tk.csv not found in fixtures path');
        end
    end
    
    methods (Test)
        function testBasicFunctionality(tc)
            % Load real ECG data from CSV files using correct filenames
            fixturesPath = fullfile(pwd, '..', 'fixtures', 'ecg');
            
            try
                % Load the signals and R-peaks from CSV files
                signalsData = readtable(fullfile(fixturesPath, 'edr_signals.csv'));
                peaksData = readtable(fullfile(fixturesPath, 'edr_tk.csv'));
                
                % Extract signals
                ecg = signalsData.ecg;
                tk = peaksData.tk; % Pre-calculated R-peaks in seconds
                
                % Sampling frequency for the CSV data
                fs = 256; % As specified
                
                % Ensure ecg is a column vector
                ecg = ecg(:);
                
                % Execute function under test
                edr = sloperange(ecg, tk, fs, 0);
                
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
            fixturesPath = fullfile(pwd, '..', 'fixtures', 'ecg');
            
            try
                % Load the signals and R-peaks from CSV files
                signalsData = readtable(fullfile(fixturesPath, 'edr_signals.csv'));
                peaksData = readtable(fullfile(fixturesPath, 'edr_tk.csv'));
                
                % Extract signals
                ecg = signalsData.ecg;
                tk = peaksData.tk; % Pre-calculated R-peaks in seconds
                
                % Take just the first two R peaks for this test
                tk = tk(1:min(2, length(tk)));
                
                fs = 256; % As specified
                
                % Execute function with just two peaks
                edr = sloperange(ecg, tk, fs, 0);
                
                % Verify results
                tc.verifySize(edr, [length(tk), 1], 'EDR should have same number of values as peaks');
                tc.verifyGreaterThan(edr, 0, 'EDR values should be positive');
            catch e
                tc.verifyTrue(false, ['Error in few peaks test: ' e.message]);
            end
        end
        
        function testBoundaryPeaks(tc)
            % Test with R peaks near the boundaries using real data
            fixturesPath = fullfile(pwd, '..', 'fixtures', 'ecg');
            
            try
                % Load the signals and R-peaks from CSV files
                signalsData = readtable(fullfile(fixturesPath, 'edr_signals.csv'));
                peaksData = readtable(fullfile(fixturesPath, 'edr_tk.csv'));
                
                % Extract signals
                ecg = signalsData.ecg;
                allPeaks = peaksData.tk; % Pre-calculated R-peaks in seconds
                
                % Select first and last peaks only
                tk = [allPeaks(1); allPeaks(end)];
                fs = 256; % As specified
                
                % Execute function with boundary peaks
                edr = sloperange(ecg, tk, fs, 0);
                
                % Verify results
                tc.verifySize(edr, [2, 1], 'EDR should have 2 values');
                tc.verifyGreaterThan(edr, 0, 'EDR values should be positive');
            catch e
                tc.verifyTrue(false, ['Error in boundary peaks test: ' e.message]);
            end
        end
        
        function testInputValidation(tc)
            % Setup using real data
            fixturesPath = fullfile(pwd, '..', 'fixtures', 'ecg');
            
            try
                % Load the signals and R-peaks from CSV files
                signalsData = readtable(fullfile(fixturesPath, 'edr_signals.csv'));
                peaksData = readtable(fullfile(fixturesPath, 'edr_tk.csv'));
                
                % Extract signals
                ecg = signalsData.ecg;
                tk = peaksData.tk(1:3); % Just use first few peaks for this test
                fs = 256; % As specified
                
                % Test column vector conversion
                ecgRow = ecg';
                edr1 = sloperange(ecg, tk, fs, 0);
                edr2 = sloperange(ecgRow, tk, fs, 0);
                tc.verifyEqual(edr1, edr2, 'Function should handle row vectors correctly');
                
                % Test default plotFlag
                edr3 = sloperange(ecg, tk, fs);
                tc.verifyEqual(size(edr3), [length(tk), 1], 'Default plotFlag should work correctly');
            catch e
                tc.verifyTrue(false, ['Error in input validation test: ' e.message]);
            end
        end
        
        function testPlottingFlag(tc)
            % Test plotting with real data
            fixturesPath = fullfile(pwd, '..', 'fixtures', 'ecg');
            
            try
                % Load the signals and R-peaks from CSV files
                signalsData = readtable(fullfile(fixturesPath, 'edr_signals.csv'));
                peaksData = readtable(fullfile(fixturesPath, 'edr_tk.csv'));
                
                % Define sampling frequency first (was missing before the error)
                fs = 256;
                
                % Extract signals - use a small portion for plotting test
                sampleLimit = 5000;
                ecg = signalsData.ecg(1:sampleLimit);
                
                % Make sure R-peaks are within the truncated signal
                maxTime = (sampleLimit-1) / fs;  % Maximum time in seconds
                tk = peaksData.tk(peaksData.tk < maxTime);
                
                % Create figure but make it invisible for testing
                fig = figure('Visible', 'off');
                edr = sloperange(ecg, tk, fs, 1);
                close(fig);
                
                tc.verifyTrue(true, 'Plotting functionality works without errors');
            catch e
                tc.verifyTrue(false, ['Plotting should not throw error: ' e.message]);
            end
        end
        
        function testComparisonWithRespSignal(tc)
            % Test comparing EDR with actual respiration signal
            fixturesPath = fullfile(pwd, '..', 'fixtures', 'ecg');
            
            try
                % Load the signals and R-peaks from CSV files
                signalsData = readtable(fullfile(fixturesPath, 'edr_signals.csv'));
                peaksData = readtable(fullfile(fixturesPath, 'edr_tk.csv'));
                
                % Extract signals
                ecg = signalsData.ecg;
                resp = signalsData.resp;
                tk = peaksData.tk; % Pre-calculated R-peaks in seconds
                
                % CSV signals are sampled at 256Hz
                fsOrig = 256;
                
                % Create time vector based on sampling rate
                t = (0:length(ecg)-1)' / fsOrig;
                
                % Calculate EDR using sloperange with the provided R-peaks
                edr = sloperange(ecg, tk, fsOrig, 0);
                
                % Target sampling frequency: 4Hz for comparison
                fsTarget = 4;
                
                % Create new time vector at target frequency
                tNew = (0:1/fsTarget:t(end))';
                
                % Create time vector only within the range of tk values
                validIdx = (tNew >= tk(1)) & (tNew <= tk(end));
                tValid = tNew(validIdx);
                
                % Resample both signals to same timebase
                respResampled = interp1(t, resp, tValid, 'pchip');
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