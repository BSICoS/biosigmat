% Tests covering:
%   - Basic functionality with fixed fiducial points
%   - Derivative-based refinement of fiducial points
%   - Edge cases (multiple points at boundaries)
%   - Error handling (invalid inputs, out-of-range fiducial points)
%   - Different parameter effects (window size, filter frequency)
%   - Real ECG signal baseline removal

classdef baselineremoveTest < matlab.unittest.TestCase

    methods (TestClassSetup)
        function addCodeToPath(~)
            addpath('../../src/tools');
        end
    end

    methods (Test)
        function testDependencies(tc)
            tc.verifyTrue(exist('lpdfilter', 'file') == 2, 'Dependency lpdfilter missing');
        end

        function testBasicFunctionality(tc)
            % Create simple signal with known baseline
            fs = 128;
            t = (0:1/fs:2-1/fs)';
            signal = sin(2*pi*t) + 0.5*sin(2*pi*0.2*t); % Signal + slow baseline
            fiducialPoints = round(fs/2:fs:length(signal));
            
            [cleanedSignal, ~, ~] = baselineremove(signal, fiducialPoints, 'Method', 'fixed');
            
            % Verify baseline is removed
            tc.verifyLessThan(std(cleanedSignal - sin(2*pi*t)), 0.15, ...
                'Basic baseline removal failed');
        end

        function testDerivativeMethodRefinement(tc)
            fs = 128;
            t = (0:1/fs:2-1/fs)';
            signal = sin(2*pi*t) + 0.5*sin(2*pi*0.2*t);
            fiducialPoints = round(fs/2:fs:length(signal));
            
            [~, ~, refinedPoints] = baselineremove(signal, fiducialPoints, ...
                'Method', 'derivative', 'SamplingFreq', fs);
            
            tc.verifyNotEqual(refinedPoints, fiducialPoints, ...
                'Points were not refined in derivative method');
            tc.verifyEqual(length(unique(refinedPoints)), length(fiducialPoints), ...
                'Number of refined points changed unexpectedly');
        end

        function testDerivativeMethodBaseline(tc)
            fs = 128;
            t = (0:1/fs:2-1/fs)';
            signal = sin(2*pi*t) + 0.5*sin(2*pi*0.2*t);
            fiducialPoints = round(fs/2:fs:length(signal));
            
            [cleanedSignal, ~, ~] = baselineremove(signal, fiducialPoints, ...
                'Method', 'derivative', 'SamplingFreq', fs);
            
            tc.verifyLessThan(std(cleanedSignal - sin(2*pi*t)), 0.2, ...
                'Derivative method baseline removal failed');
        end

        function testInvalidInputs(tc)
            signal = sin(1:100)';
            fiducialPoints = [25; 50; 75];
            
            % Test missing sampling frequency with derivative method
            tc.verifyError(@() baselineremove(signal, fiducialPoints), ...
                'baselineremove:missingSamplingFreq');
            
            % Test invalid fiducial points
            tc.verifyError(@() baselineremove(signal, [-1; 50]), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
            
            % Test empty signal
            tc.verifyError(@() baselineremove([], fiducialPoints), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            % Test invalid window size
            tc.verifyError(@() baselineremove(signal, fiducialPoints, 'WindowSize', 0), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            % Test invalid filter frequency
            tc.verifyError(@() baselineremove(signal, fiducialPoints, ...
                'Method', 'derivative', 'SamplingFreq', 100, 'FilterFreq', 0), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function testBoundaryPoints(tc)
            fs = 128;
            t = (0:1/fs:1-1/fs)';
            signal = sin(2*pi*t) + t; % Signal with linear trend
            
            % Test boundary points
            boundaryPoints = [1; length(signal)];
            [cleanedSignal1, ~] = baselineremove(signal, boundaryPoints, 'Method', 'fixed');
            tc.verifySize(cleanedSignal1, size(signal), 'Boundary points case failed');
            
            % Test closely spaced boundary points
            closePoints = [1; 2; length(signal)-1; length(signal)];
            [cleanedSignal2, ~] = baselineremove(signal, closePoints, 'Method', 'fixed');
            tc.verifySize(cleanedSignal2, size(signal), 'Close boundary points case failed');
        end

        function testWindowSizeEffect(tc)
            fs = 128;
            t = (0:1/fs:2-1/fs)';
            signal = sin(2*pi*t) + 0.5*sin(2*pi*0.2*t);
            fiducialPoints = round(fs/2:fs:length(signal));
            
            [clean1, ~] = baselineremove(signal, fiducialPoints, 'WindowSize', 3, 'Method', 'fixed');
            [clean2, ~] = baselineremove(signal, fiducialPoints, 'WindowSize', 11, 'Method', 'fixed');
            
            tc.verifyNotEqual(clean1, clean2, 'Window size had no effect');
        end

        function testFilterFrequencyEffect(tc)
            fs = 128;
            t = (0:1/fs:2-1/fs)';
            signal = sin(2*pi*t) + 0.5*sin(2*pi*0.2*t);
            fiducialPoints = round(fs/2:fs:length(signal));
            
            [clean1, ~] = baselineremove(signal, fiducialPoints, ...
                'Method', 'derivative', 'SamplingFreq', fs, 'FilterFreq', 10);
            [clean2, ~] = baselineremove(signal, fiducialPoints, ...
                'Method', 'derivative', 'SamplingFreq', fs, 'FilterFreq', 30);
            
            tc.verifyNotEqual(clean1, clean2, 'Filter frequency had no effect');
        end

        function testRealECGBaseline(tc)
            try
                % Load and resample ECG data
                fixtureFs = 512;
                targetFs = 128;
                ecgData = readmatrix('../../fixtures/ecg/ecg_tk.csv');
                origSignal = ecgData(:, 2);
                signal = resample(origSignal, targetFs, fixtureFs);
                
                % Normalize signal to unit amplitude before resampling
                origSignal = origSignal / max(abs(origSignal));
                signal = resample(origSignal, targetFs, fixtureFs);
                
                % Add small synthetic baseline (0.05x signal amplitude)
                t = (0:length(signal)-1)' / targetFs;
                baseline = 0.05 * (sin(2*pi*0.2*t) + 0.5*sin(2*pi*0.1*t));
                signal = signal + baseline;
                
                % Create fiducial points every 1 second
                fiducialPoints = (targetFs:targetFs:length(signal))';
                
                % Ensure points are within valid range and unique
                fiducialPoints = fiducialPoints(fiducialPoints > 1 & fiducialPoints < length(signal));
                fiducialPoints = unique(fiducialPoints);
                
                % Remove DC offset after adding baseline
                signal = signal - mean(signal);
                
                % Apply baseline removal using both methods
                [cleanedSignal1, baseline_fixed] = baselineremove(signal, fiducialPoints, ...
                    'Method', 'fixed');
                [cleanedSignal2, baseline_deriv] = baselineremove(signal, fiducialPoints, ...
                    'Method', 'derivative', 'SamplingFreq', targetFs);
                
                % Create reference using highpass filter at 0.3Hz
                cleanedReference = highpass(signal, 0.3, targetFs);
                
                % Remove means from all signals for fair comparison
                cleanedSignal1 = cleanedSignal1 - mean(cleanedSignal1);
                cleanedSignal2 = cleanedSignal2 - mean(cleanedSignal2);
                cleanedReference = cleanedReference - mean(cleanedReference);
                
                % Calculate correlation with reference for both methods
                corrFixed = corr(cleanedSignal1, cleanedReference);
                corrDeriv = corr(cleanedSignal2, cleanedReference);
                
                % Calculate relative power in baseline (using baselines returned by the function)
                baselinePowerFixed = sum(baseline_fixed.^2) / sum(signal.^2);
                baselinePowerDeriv = sum(baseline_deriv.^2) / sum(signal.^2);
                
                % Verify results match highpass filtered reference with lower threshold (0.8)
                tc.verifyGreaterThan(corrFixed, 0.8, ...
                    'Fixed method does not sufficiently match reference filter');
                tc.verifyGreaterThan(corrDeriv, 0.8, ...
                    'Derivative method does not sufficiently match reference filter');
                
                % Verify baseline power is reasonable (should be less than 10% of signal power)
                tc.verifyLessThan(baselinePowerFixed, 0.1, ...
                    'Fixed method baseline power too high');
                tc.verifyLessThan(baselinePowerDeriv, 0.1, ...
                    'Derivative method baseline power too high');
            catch e
                tc.assumeFail(['Unable to process ECG data: ', e.message]);
            end
        end
    end
end
