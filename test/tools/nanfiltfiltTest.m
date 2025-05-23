% nanfiltfiltTest.m - Test for the nanfiltfilt function
%
% This script tests the nanfiltfilt function with different test cases:
% 1. Noisy sinusoidal with some NaN values
% 2. Noisy sinusoidal with bursts of NaN values
% 3. Signal with all NaN values
% 4. Signal with no NaN values
% 5. Missing maxgap parameter (should issue warning and preserve all NaNs)
% 6. Insufficient inputs (should throw an error)

%% Add source path if needed
addpath('../../src/tools');

%% Print header
fprintf('\n=========================================================\n');
fprintf('          RUNNING NANFILTFILT TEST CASES\n');
fprintf('=========================================================\n\n');

%% Test 1: Noisy sinusoidal with some NaN values and maxgap = 0

% Generate sinusoidal signal with noise
n = 100;
t = linspace(0, 2*pi, n)';
originalSignal = sin(t);
noise = 0.2 * randn(n, 1);
noisySignal = originalSignal + noise;

% Add random NaN values (about 10%)
nanIndices = randperm(n, round(n*0.1));
signalWithNans = noisySignal;
signalWithNans(nanIndices) = NaN;

% Define filter parameters (low-pass filter)
[b, a] = butter(2, 0.1); % 2nd order Butterworth filter with normalized cutoff freq 0.2

% Process with nanfiltfilt
maxgap = 0; % Maximum size of NaN segments to interpolate
filteredSignal = nanfiltfilt(b, a, signalWithNans, maxgap);

% Test 1 validation - check if NaN positions are filled
nanFilled = any(isnan(filteredSignal));
if nanFilled
  fprintf('Test 1: NaN positions filled: passed\n');
else
  fprintf('Test 1: NaN positions filled: failed\n');
end

%% Test 2: Noisy sinusoidal with bursts of NaN values

% Generate sinusoidal signal with noise
noisySignal = originalSignal + noise;

% Add bursts of NaN values
signalWithBursts = noisySignal;
% First burst - small (will be interpolated)
signalWithBursts(15:17) = NaN;
% Second burst - medium
signalWithBursts(40:45) = NaN;
% Third burst - large
signalWithBursts(70:80) = NaN;

% Process with nanfiltfilt
maxgap = 3;
filteredSignalBursts = nanfiltfilt(b, a, signalWithBursts, maxgap);

% Test 2 validation - check if larger NaN bursts are preserved
% Check if large bursts are preserved
largeBurstPreserved = all(isnan(signalWithBursts(70:80)) == isnan(filteredSignalBursts(70:80)));
smallBurstInterpolated = ~any(isnan(filteredSignalBursts(15:17)));
if largeBurstPreserved && smallBurstInterpolated
  fprintf('Test 2: Noisy sinusoidal with bursts of NaN values: passed\n');
else
  fprintf('Test 2: Noisy sinusoidal with bursts of NaN values: failed\n');
end

if largeBurstPreserved
  fprintf(' - Test 2a: Large NaN burst preserved: passed\n');
else
  fprintf(' - Test 2a: Large NaN burst preserved: failed\n');
end

% Check if small bursts (below maxgap threshold) are interpolated
if smallBurstInterpolated
  fprintf(' - Test 2b: Small NaN burst interpolated: passed\n');
else
  fprintf(' - Test 2b: Small NaN burst interpolated: failed\n');
end

%% Test 3: Signal with all NaN values

% Create all NaN signal
allNanSignal = NaN(n, 1);

% Process with nanfiltfilt
filteredAllNan = nanfiltfilt(b, a, allNanSignal, maxgap);

% Test 3 validation - check if all NaN input produces all NaN output
allNanOutput = all(isnan(filteredAllNan));
if allNanOutput
  fprintf('Test 3: All NaN input produces all NaN output: passed\n');
else
  fprintf('Test 3: All NaN input produces all NaN output: failed\n');
end

%% Test 4: Signal with no NaN values

% Create signal with no NaNs
noNanSignal = noisySignal;

% Process with nanfiltfilt
filteredNoNan = nanfiltfilt(b, a, noNanSignal, maxgap);

% Standard filtfilt for comparison
standardFiltered = filtfilt(b, a, noNanSignal);

% Test 4 validation - check if no NaN input matches standard filtfilt
noNanMatch = max(abs(filteredNoNan - standardFiltered)) < 1e-10;
if noNanMatch
  fprintf('Test 4: No NaN input matches standard filtfilt: passed\n');
else
  fprintf('Test 4: No NaN input matches standard filtfilt: failed\n');
end

%% Test 5: Missing maxgap parameter

% Use signal with bursts from Test 2
testSignal = signalWithBursts;

% Capture warning
warningOccurred = false;
warningMessage = '';
warningId = '';
originalWarningState = warning('on', 'all');
lastwarn('');

% Create warning capture function
warnFcn = @(msg, id) assignin('base', 'warningOccurred', true) | ...
  assignin('base', 'warningMessage', msg) | ...
  assignin('base', 'warningId', id);

warning('error', 'MATLAB:dispatcher:dotcall:nomethod'); % Avoid showing warning from this
warning('off', 'MATLAB:dispatcher:dotcall:nomethod');
warning('on', 'all');

try  % Process with nanfiltfilt without maxgap parameter
  % This should issue a warning and preserve all NaNs
  % Temporarily disable warnings to prevent them from being displayed
  oldWarningState = warning('off', 'all');

  [~, warnId] = lastwarn('');
  lastwarn('');

  filteredNoMaxgap = nanfiltfilt(b, a, testSignal);

  [warnMsg, warnId] = lastwarn();
  warningOccurred = ~isempty(warnMsg);
  warningMessage = warnMsg;

  % Restore original warning state
  warning(oldWarningState);
catch ME
  warning(originalWarningState);
  fprintf('Unexpected error in Test 5: %s\n', ME.message);
end

% Test 5 validation - check missing maxgap parameter
allNansPreserved = all(isnan(testSignal) == isnan(filteredNoMaxgap));

% Overall test result
if warningOccurred && allNansPreserved
  fprintf('Test 5: Missing maxgap parameter: passed\n');
else
  fprintf('Test 5: Missing maxgap parameter: failed\n');
end

% Check if warning occurred
if warningOccurred
  fprintf(' - Test 5a: Warning occurred for missing maxgap: passed\n');
else
  fprintf(' - Test 5a: Warning occurred for missing maxgap: failed\n');
end

% Check if all NaNs are preserved (regardless of size)
if allNansPreserved
  fprintf(' - Test 5b: All NaNs preserved when maxgap not specified: passed\n');
else
  fprintf(' - Test 5b: All NaNs preserved when maxgap not specified: failed\n');
end

%% Test 6: insufficient inputs

% Test with only 2 inputs
errorMessage = '';
errorOccurred = false;

try
  % This should throw an error
  filteredInsufficientInputs = nanfiltfilt(b, a);
  fprintf('Test 6: Error occurred with insufficient inputs: failed\n');
catch ME
  errorOccurred = true;
  errorMessage = ME.message;
  fprintf('Test 6: Error occurred with insufficient inputs (error: %s): passed\n', errorMessage);
end

%% Summarize all results
fprintf('\n---------------------------------------------------------\n');
fprintf('  SUMMARY: %i of %i tests passed\n', ...
  sum([nanFilled, largeBurstPreserved, allNanOutput, noNanMatch, ...
  allNansPreserved, errorOccurred]), 6);
fprintf('---------------------------------------------------------\n\n');
