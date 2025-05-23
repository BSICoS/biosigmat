% findsequencesTest.m - Test for the findsequences function
%
% This script tests the findsequences function with different test cases:
% 1. Basic sequence detection in a vector
% 2. Sequence detection in a matrix (first dimension)
% 3. Sequence detection in a matrix (second dimension)
% 4. Detection of sequences with special values (NaN, 0, Inf, -Inf)
% 5. 3D array sequence detection
% 6. Empty and scalar inputs
% 7. Logical input
% 8. Error handling for invalid inputs

%% Add source path if needed
addpath('../../src/tools');

%% Initialize figure for visualizing test cases
figure('Name', 'findsequences Test Cases', 'Position', [100, 100, 1200, 800]);
fprintf('\n=========================================================\n');
fprintf('          RUNNING FINDSEQUENCES TEST CASES\n');
fprintf('=========================================================\n\n');

%% Test 1: Basic sequence detection in a vector

% Create a test vector with sequences
testVector = [1, 1, 1, 2, 3, 3, 4, 5, 5, 5, 5, 6, 7, 7, 8];

% Expected results (value, startIndices, endIndices, seqLengths)
expectedOutput = [
    1, 1, 3, 3;
    3, 5, 6, 2;
    5, 8, 11, 4;
    7, 13, 14, 2];

% Run findsequences
sequences = findsequences(testVector);

% Test 1 validation
correctOutput = isequal(sequences, expectedOutput);
if correctOutput
  fprintf('Test 1: Basic sequence detection in vector: passed\n');
else
  fprintf('Test 1: Basic sequence detection in vector: failed\n');
  fprintf('  Expected output:\n');
  disp(expectedOutput);
  fprintf('  Actual output:\n');
  disp(sequences);
end

%% Test 2: Sequence detection in a matrix (first dimension)

% Create a test matrix with sequences in first dimension
testMatrix = [
    1, 2, 3, 4;
    1, 5, 6, 7;
    1, 8, 9, 10;
    2, 11, 12, 13;
    2, 14, 15, 16;
    3, 17, 18, 19];

% Expected results (value, startIndices, endIndices, seqLengths)
expectedOutput = [
    1, 1, 3, 3;
    2, 4, 5, 2];

% Run findsequences with dim=1
sequences = findsequences(testMatrix, 1);

% Test 2 validation
correctOutput = isequal(sequences, expectedOutput);
if correctOutput
  fprintf('Test 2: Sequence detection in matrix (1st dimension): passed\n');
else
  fprintf('Test 2: Sequence detection in matrix (1st dimension): failed\n');
  fprintf('  Expected output:\n');
  disp(expectedOutput);
  fprintf('  Actual output:\n');
  disp(sequences);
end

%% Test 3: Sequence detection in a matrix (second dimension)

% Create a test matrix with sequences in second dimension
testMatrix = [
    1, 1, 1, 2, 3;
    4, 5, 5, 6, 6;
    7, 8, 8, 8, 9];

% Expected results when dim=2 (value, startIndices, endIndices, seqLengths)
expectedOutput = [
    1, 1, 3, 3;
    5, 7, 8, 2;
    8, 12, 14, 3;
    6, 9, 10, 2];

% Run findsequences with dim=2
sequences = findsequences(testMatrix, 2);

% Test 3 validation
correctOutput = isequal(sequences, expectedOutput);
if correctOutput
  fprintf('Test 3: Sequence detection in matrix (2nd dimension): passed\n');
else
  fprintf('Test 3: Sequence detection in matrix (2nd dimension): failed\n');
  fprintf('  Expected output:\n');
  disp(expectedOutput);
  fprintf('  Actual output:\n');
  disp(sequences);
end

%% Test 4: Detection of sequences with special values (NaN, 0, Inf, -Inf)

% Create a test vector with special values
testSpecial = [1, NaN, NaN, NaN, 0, 0, 5, Inf, Inf, -Inf, -Inf, -Inf, 10];
expectedOutput = [
    NaN, 2, 4, 3;
    0, 5, 6, 2; 
    Inf, 8, 9, 2; 
    -Inf, 10, 12, 3];

% Run findsequences
sequences = findsequences(testSpecial);

% Test 4 validation
% We need to handle NaN comparison specially
correctOutput = size(sequences, 1) == size(expectedOutput, 1);
if correctOutput
  for i = 1:size(sequences, 1)
    row = sequences(i, :);
    expRow = expectedOutput(i, :);

    % For NaN rows, check if both are NaN
    if isnan(row(1)) && isnan(expRow(1))
      rowMatch = all(row(2:end) == expRow(2:end));
    else
      rowMatch = all(row == expRow);
    end

    if ~rowMatch
      correctOutput = false;
      break;
    end
  end
end

if correctOutput
  fprintf('Test 4: Detection of sequences with special values: passed\n');
else
  fprintf('Test 4: Detection of sequences with special values: failed\n');
  fprintf('  Expected output:\n');
  disp(expectedOutput);
  fprintf('  Actual output:\n');
  disp(sequences);
end

%% Test 5: 3D array sequence detection

% Create a 3D array with sequences along the 3rd dimension
test3D = zeros(2, 2, 5);
% Add sequences along dimension 3
test3D(1, 1, :) = [1, 1, 1, 2, 2];
test3D(1, 2, :) = [3, 3, 4, 4, 4];
test3D(2, 1, :) = [5, 6, 6, 6, 7];
test3D(2, 2, :) = [8, 8, 8, 8, 8];

% Expected output for dimension 3
expectedOutput = [1, 1, 3, 3; 2, 4, 5, 2; 3, 6, 7, 2; 4, 8, 10, 3; 6, 12, 14, 3; 8, 16, 20, 5];

% Run findsequences with dim=3
sequences = findsequences(test3D, 3);

% Visualize the 3D array as a set of 2D slices
subplot(4, 2, 5);
for i = 1:5
  subplot(4, 2, 5 + floor((i-1)/3));
  imagesc(test3D(:,:,i));
  colormap('jet');
  colorbar;
  title(sprintf('3D Array - Slice %d', i));
  xlabel('Column'); ylabel('Row');
  if i == 1
    % Add a text explanation
    text(0.5, -0.5, 'Test 5: Sequences in 3D Array (3rd Dimension)', ...
      'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
  end
end

% Test 5 validation
correctOutput = isequal(sequences, expectedOutput);
if correctOutput
  fprintf('Test 5: 3D array sequence detection: passed\n');
else
  fprintf('Test 5: 3D array sequence detection: failed\n');
  fprintf('  Expected output:\n');
  disp(expectedOutput);
  fprintf('  Actual output:\n');
  disp(sequences);
end

%% Test 6: Empty and scalar inputs

% Test with empty array
emptyArray = [];
emptyResult = findsequences(emptyArray);
emptyCorrect = isempty(emptyResult);

% Test with scalar
scalarValue = 42;
scalarResult = findsequences(scalarValue);
scalarCorrect = isempty(scalarResult);

% Plot placeholder
subplot(4, 2, 7);
text(0.5, 0.5, 'Test 6: Empty and Scalar Inputs', ...
  'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
axis off;

% Test 6 validation
if emptyCorrect && scalarCorrect
  fprintf('Test 6: Empty and scalar inputs: passed\n');
  fprintf(' - Test 6a: Empty array returns empty result: passed\n');
  fprintf(' - Test 6b: Scalar value returns empty result: passed\n');
else
  fprintf('Test 6: Empty and scalar inputs: failed\n');

  if ~emptyCorrect
    fprintf(' - Test 6a: Empty array returns empty result: failed\n');
    fprintf('   Result: '); disp(emptyResult);
  else
    fprintf(' - Test 6a: Empty array returns empty result: passed\n');
  end

  if ~scalarCorrect
    fprintf(' - Test 6b: Scalar value returns empty result: failed\n');
    fprintf('   Result: '); disp(scalarResult);
  else
    fprintf(' - Test 6b: Scalar value returns empty result: passed\n');
  end
end

%% Test 7: Logical input

% Create logical array
logicalArray = logical([0 0 1 1 1 0 1 0 0 0]);
expectedOutput = [1, 3, 5, 3; 1, 7, 7, 1; 0, 1, 2, 2; 0, 8, 10, 3];

% Run findsequences
sequences = findsequences(logicalArray);

% Plot results
subplot(4, 2, 8);
stem(double(logicalArray), 'b-o', 'LineWidth', 1.5, 'MarkerSize', 6);
hold on;
% Highlight the sequences
for i = 1:size(sequences, 1)
  startIdx = sequences(i, 2);
  endIdx = sequences(i, 3);
  value = sequences(i, 1);
  stem(startIdx:endIdx, repmat(value, 1, endIdx-startIdx+1), ...
    'r-x', 'LineWidth', 2, 'MarkerSize', 8);
end
title('Test 7: Logical Input');
xlabel('Position'); ylabel('Value');
ylim([-0.2, 1.2]);
yticks([0, 1]);
yticklabels({'false', 'true'});
grid on;

% Test 7 validation
correctOutput = isequal(sequences, expectedOutput);
if correctOutput
  fprintf('Test 7: Logical input: passed\n');
else
  fprintf('Test 7: Logical input: failed\n');
  fprintf('  Expected output:\n');
  disp(expectedOutput);
  fprintf('  Actual output:\n');
  disp(sequences);
end

%% Test 8: Error handling for invalid inputs

% Test with non-numeric input
errorOccurred = false;
try
  result = findsequences('string');
  errorOccurred = false;
catch ME
  errorOccurred = true;
  errorMessage = ME.message;
end

% Test with invalid dimension
dimErrorOccurred = false;
try
  result = findsequences([1 2 3], 'a');
  dimErrorOccurred = false;
catch ME
  dimErrorOccurred = true;
  dimErrorMessage = ME.message;
end

% Test with out-of-range dimension
outOfRangeDimErrorOccurred = false;
try
  result = findsequences([1 2 3], 5); % 5 > ndims([1 2 3])
  outOfRangeDimErrorOccurred = false;
catch ME
  outOfRangeDimErrorOccurred = true;
  outOfRangeDimErrorMessage = ME.message;
end

% Test 8 validation
if errorOccurred && dimErrorOccurred && outOfRangeDimErrorOccurred
  fprintf('Test 8: Error handling for invalid inputs: passed\n');
  fprintf(' - Test 8a: Non-numeric input error: passed (%s)\n', errorMessage);
  fprintf(' - Test 8b: Invalid dimension error: passed (%s)\n', dimErrorMessage);
  fprintf(' - Test 8c: Out-of-range dimension error: passed (%s)\n', outOfRangeDimErrorMessage);
else
  fprintf('Test 8: Error handling for invalid inputs: failed\n');

  if ~errorOccurred
    fprintf(' - Test 8a: Non-numeric input error: failed\n');
  else
    fprintf(' - Test 8a: Non-numeric input error: passed (%s)\n', errorMessage);
  end

  if ~dimErrorOccurred
    fprintf(' - Test 8b: Invalid dimension error: failed\n');
  else
    fprintf(' - Test 8b: Invalid dimension error: passed (%s)\n', dimErrorMessage);
  end

  if ~outOfRangeDimErrorOccurred
    fprintf(' - Test 8c: Out-of-range dimension error: failed\n');
  else
    fprintf(' - Test 8c: Out-of-range dimension error: passed (%s)\n', outOfRangeDimErrorMessage);
  end
end

%% Test 9: Multiple output arguments

% Create test vector
testVector = [1, 1, 1, 2, 3, 3, 4, 5, 5, 5, 5, 6, 7, 7, 8];

% Get multiple outputs
[values, startPos, endPos, lengths] = findsequences(testVector);

% Expected outputs
expectedValues = [1; 3; 5; 7];
expectedStartPos = [1; 5; 8; 13];
expectedEndPos = [3; 6; 11; 14];
expectedLengths = [3; 2; 4; 2];

% Test 9 validation
valuesCorrect = isequal(values, expectedValues);
startPosCorrect = isequal(startPos, expectedStartPos);
endPosCorrect = isequal(endPos, expectedEndPos);
lengthsCorrect = isequal(lengths, expectedLengths);

if valuesCorrect && startPosCorrect && endPosCorrect && lengthsCorrect
  fprintf('Test 9: Multiple output arguments: passed\n');
else
  fprintf('Test 9: Multiple output arguments: failed\n');

  if ~valuesCorrect
    fprintf(' - Test 9a: Values output: failed\n');
    fprintf('   Expected: '); disp(expectedValues');
    fprintf('   Actual: '); disp(values');
  else
    fprintf(' - Test 9a: Values output: passed\n');
  end

  if ~startPosCorrect
    fprintf(' - Test 9b: Start positions output: failed\n');
    fprintf('   Expected: '); disp(expectedStartPos');
    fprintf('   Actual: '); disp(startPos');
  else
    fprintf(' - Test 9b: Start positions output: passed\n');
  end

  if ~endPosCorrect
    fprintf(' - Test 9c: End positions output: failed\n');
    fprintf('   Expected: '); disp(expectedEndPos');
    fprintf('   Actual: '); disp(endPos');
  else
    fprintf(' - Test 9c: End positions output: passed\n');
  end

  if ~lengthsCorrect
    fprintf(' - Test 9d: Lengths output: failed\n');
    fprintf('   Expected: '); disp(expectedLengths');
    fprintf('   Actual: '); disp(lengths');
  else
    fprintf(' - Test 9d: Lengths output: passed\n');
  end
end

%% Summarize all results
fprintf('\n---------------------------------------------------------\n');
fprintf('  SUMMARY: %i of %i tests passed\n', ...
  sum([correctOutput, correctOutput, correctOutput, correctOutput, ...
  correctOutput, emptyCorrect && scalarCorrect, correctOutput, ...
  errorOccurred && dimErrorOccurred && outOfRangeDimErrorOccurred, ...
  valuesCorrect && startPosCorrect && endPosCorrect && lengthsCorrect]), 9);
fprintf('---------------------------------------------------------\n\n');
