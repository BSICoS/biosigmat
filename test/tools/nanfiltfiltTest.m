% nanfiltfiltTest.m - Test for the nanfiltfilt function
%
% This script tests the nanfiltfilt function with different test cases:
% 1. Dependencies check (checks if required functions are available)
% 2. Noisy sinusoidal with some NaN values and maxgap = length(signal)
% 3. Noisy sinusoidal with bursts of NaN values (small bursts interpolated, large bursts preserved)
% 4. Signal with all NaN values
% 5. Signal with no NaN values
% 6. Missing maxgap parameter (issues warning and preserves all NaNs)
% 7. Insufficient inputs (throws an error)
% 8. Multi-column noisy sinusoidal with some NaNs and maxgap = length(signal)
% 9. Multi-column noisy sinusoidal with bursts of NaNs (small bursts interpolated, large bursts preserved)
% 10. Multi-column all-NaN signal
% 11. Multi-column no-NaN signal matches standard filtfilt
% 12. Multi-column missing maxgap parameter (issues warning and preserves all NaNs)

%% Add source path if needed
addpath('../../src/tools');

%% Print header
fprintf('\n=========================================================\n');
fprintf('          RUNNING NANFILTFILT TEST CASES\n');
fprintf('=========================================================\n\n');

%% Test 1: Dependencies check

% Test if all required dependencies are available
dependenciesOk = true;
missingDependencies = {};

% Check for findsequences function
if ~exist('findsequences', 'file')
  dependenciesOk = false;
  missingDependencies{end+1} = 'findsequences';
end

% Print test results
if dependenciesOk
  fprintf('Test 1: All dependencies available: passed\n');
else
  fprintf('Test 1: All dependencies available: failed\n');
  fprintf(' - Missing dependencies: ');
  for i = 1:length(missingDependencies)
    if i > 1
      fprintf(', ');
    end
    fprintf('%s', missingDependencies{i});
  end
  fprintf('\n');
end

%% Test 2: Noisy sinusoidal with some NaN values and maxgap = length(signal)

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
maxgap = length(signalWithNans); % Maximum size of NaN segments to interpolate
filteredSignal = nanfiltfilt(b, a, signalWithNans, maxgap);

% Test 2 validation - check if NaN positions are filled
nanFilled = ~any(isnan(filteredSignal));
if nanFilled
  fprintf('Test 2: Noisy sinusoidal with some NaN values and maxgap = length(signal): passed\n');
else
  fprintf('Test 2: Noisy sinusoidal with some NaN values and maxgap = length(signal): failed\n');
end

%% Test 3: Noisy sinusoidal with bursts of NaN values

% Generate sinusoidal signal with noise
noisySignal = originalSignal + noise;

% Add bursts of NaN values
signalWithBursts = noisySignal;
% Small burst (will be interpolated)
signalWithBursts(15:17) = NaN;
% Large burst (will not be interpolated)
signalWithBursts(70:80) = NaN;

% Process with nanfiltfilt
maxgap = 3;
filteredSignalBursts = nanfiltfilt(b, a, signalWithBursts, maxgap);

% Test 3 validation - check if larger NaN bursts are preserved
largeBurstPreserved = all(isnan(signalWithBursts(70:80)) == isnan(filteredSignalBursts(70:80)));
smallBurstInterpolated = ~any(isnan(filteredSignalBursts(15:17)));

if largeBurstPreserved && smallBurstInterpolated
  fprintf('Test 3: Noisy sinusoidal with bursts of NaN values: passed\n');
else
  fprintf('Test 3: Noisy sinusoidal with bursts of NaN values: failed\n');
end

if largeBurstPreserved
  fprintf(' - Test 3a: Large NaN burst preserved: passed\n');
else
  fprintf(' - Test 3a: Large NaN burst preserved: failed\n');
end

% Check if small bursts (below maxgap threshold) are interpolated
if smallBurstInterpolated
  fprintf(' - Test 3b: Small NaN burst interpolated: passed\n');
else
  fprintf(' - Test 3b: Small NaN burst interpolated: failed\n');
end

%% Test 4: Signal with all NaN values

% Create all NaN signal
allNanSignal = NaN(n, 1);

% Process with nanfiltfilt
filteredAllNan = nanfiltfilt(b, a, allNanSignal, maxgap);

% Test 4 validation - check if all NaN input produces all NaN output
allNanOutput = all(isnan(filteredAllNan));
if allNanOutput
  fprintf('Test 4: All NaN input produces all NaN output: passed\n');
else
  fprintf('Test 4: All NaN input produces all NaN output: failed\n');
end

%% Test 5: Signal with no NaN values

% Create signal with no NaNs
noNanSignal = noisySignal;

% Process with nanfiltfilt
filteredNoNan = nanfiltfilt(b, a, noNanSignal, maxgap);

% Standard filtfilt for comparison
standardFiltered = filtfilt(b, a, noNanSignal);

% Test 5 validation - check if no NaN input matches standard filtfilt
noNanMatch = max(abs(filteredNoNan - standardFiltered)) < 1e-10;
if noNanMatch
  fprintf('Test 5: No NaN input matches standard filtfilt: passed\n');
else
  fprintf('Test 5: No NaN input matches standard filtfilt: failed\n');
end

%% Test 6: Missing maxgap parameter

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

  lastwarn('');

  filteredNoMaxgap = nanfiltfilt(b, a, testSignal);

  warnMsg = lastwarn();
  warningOccurred = ~isempty(warnMsg);

  % Restore original warning state
  warning(oldWarningState);
catch ME
  warning(originalWarningState);
  fprintf('Unexpected error in Test 5: %s\n', ME.message);
end

allNansPreserved = all(isnan(testSignal) == isnan(filteredNoMaxgap));

% Overall test result
if warningOccurred && allNansPreserved
  fprintf('Test 6: Missing maxgap parameter: passed\n');
else
  fprintf('Test 6: Missing maxgap parameter: failed\n');
end

% Check if warning occurred
if warningOccurred
  fprintf(' - Test 6a: Warning occurred for missing maxgap (%s): passed\n', warnMsg);
else
  fprintf(' - Test 6a: Warning occurred for missing maxgap: failed\n');
end

% Check if all NaNs are preserved (regardless of size)
if allNansPreserved
  fprintf(' - Test 6b: All NaNs preserved when maxgap not specified: passed\n');
else
  fprintf(' - Test 6b: All NaNs preserved when maxgap not specified: failed\n');
end

%% Test 7: insufficient inputs

% Test with only 2 inputs
errorMessage = '';
errorOccurred = false;

try
  % This should throw an error
  filteredInsufficientInputs = nanfiltfilt(b, a);
  fprintf('Test 7: Error occurred with insufficient inputs: failed\n');
catch ME
  errorOccurred = true;
  errorMessage = ME.message;  fprintf('Test 7: Error occurred with insufficient inputs (error: %s): passed\n', errorMessage);
end

%% Test 8: Multi-column noisy sinusoidal with some NaNs and maxgap = length(signal)

numCols = 3;
noiseMat = 0.2 * randn(n, numCols);
signalMat = repmat(originalSignal, 1, numCols) + noiseMat;
signalWithNansMat = signalMat;
for c = 1:numCols
  idx = randperm(n, round(n*0.1));
  signalWithNansMat(idx, c) = NaN;
end
filteredMat = nanfiltfilt(b, a, signalWithNansMat, n);
multiNanFilled = ~any(isnan(filteredMat), 'all');
if multiNanFilled
  fprintf('Test 8: Multi-column noisy with NaNs & maxgap = length: passed\n');
else
  fprintf('Test 8: Multi-column noisy with NaNs & maxgap = length: failed\n');
end

%% Test 9: Multi-column noisy sinusoidal with bursts of NaNs

signalBurstsMat = signalMat;
signalBurstsMat(15:17, :) = NaN;   % small bursts
signalBurstsMat(70:80, :) = NaN;   % large bursts
filteredBurstsMat = nanfiltfilt(b, a, signalBurstsMat, 3);
largeBurstPreservedMat = all(isnan(filteredBurstsMat(70:80, :)), 'all');
smallBurstInterpolatedMat = ~any(isnan(filteredBurstsMat(15:17, :)), 'all');
multiBurstOk = largeBurstPreservedMat && smallBurstInterpolatedMat;
if multiBurstOk
  fprintf('Test 9: Multi-column bursts of NaNs: passed\n');
else
  fprintf('Test 9: Multi-column bursts of NaNs: failed\n');
end
if largeBurstPreservedMat
  fprintf(' - Test 9a: Large burst preserved: passed\n');
else
  fprintf(' - Test 9a: Large burst preserved: failed\n');
end
if smallBurstInterpolatedMat
  fprintf(' - Test 9b: Small burst interpolated: passed\n');
else
  fprintf(' - Test 9b: Small burst interpolated: failed\n');
end

%% Test 10: Multi-column all-NaN signal

allNanMat = NaN(n, numCols);
filteredAllNanMat = nanfiltfilt(b, a, allNanMat, 3);
multiAllNanOutput = all(isnan(filteredAllNanMat), 'all');
if multiAllNanOutput
  fprintf('Test 10: Multi-column all-NaN in → all-NaN out: passed\n');
else
  fprintf('Test 10: Multi-column all-NaN in → all-NaN out: failed\n');
end

%% Test 11: Multi-column no-NaN signal matches standard filtfilt

noNanMat = signalMat;
filteredNoNanMat = nanfiltfilt(b, a, noNanMat, 3);
standardMat = filtfilt(b, a, noNanMat);
multiNoNanMatch = max(abs(filteredNoNanMat - standardMat), [], 'all') < 1e-10;
if multiNoNanMatch
  fprintf('Test 11: Multi-column no-NaN matches filtfilt: passed\n');
else
  fprintf('Test 11: Multi-column no-NaN matches filtfilt: failed\n');
end

%% Test 12: Multi-column missing maxgap parameter

testMat = signalBurstsMat;
lastwarn(''); warning('off', 'all');
filteredNoMaxgapMat = nanfiltfilt(b, a, testMat);
[warnMsg, warnId] = lastwarn;
multiWarnOccurred = ~isempty(warnMsg);
multiPreserveMat = all(isnan(testMat) == isnan(filteredNoMaxgapMat), 'all');
multiMissingOk = multiWarnOccurred && multiPreserveMat;
if multiMissingOk
  fprintf('Test 12: Multi-column missing maxgap: passed\n');
else
  fprintf('Test 12: Multi-column missing maxgap: failed\n');
end
if multiWarnOccurred
  fprintf(' - Test 12a: Warning occurred: passed\n');
else
  fprintf(' - Test 12a: Warning occurred: failed\n');
end
if multiPreserveMat
  fprintf(' - Test 12b: All NaNs preserved: passed\n');
else
  fprintf(' - Test 12b: All NaNs preserved: failed\n');
end

%% Summarize all results

fprintf('\n---------------------------------------------------------\n');
fprintf('  SUMMARY: %i of %i tests passed\n', ...
  sum([dependenciesOk, nanFilled, largeBurstPreserved, allNanOutput, noNanMatch, ...
  allNansPreserved, errorOccurred, multiNanFilled, multiBurstOk, multiAllNanOutput, ...
  multiNoNanMatch, multiMissingOk]), 12);
fprintf('---------------------------------------------------------\n\n');
