% findsequencesTest.m - Test for the findsequences function
%
% This script tests the findsequences function with different test cases:
% 1. Basic sequence detection in a vector
% 2. Sequence detection in a matrix (first dimension)
% 3. Detection of sequences with special values (NaN, 0, Inf, -Inf)
% 4. Empty and scalar inputs
% 5. Logical input
% 6. Error handling for invalid inputs

%% Add source path if needed
addpath('../../src/tools');

%% Print header
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
test1Passed = isequal(sequences, expectedOutput);
if test1Passed
  fprintf('Test 1: Basic sequence detection in vector: passed\n');
else
  fprintf('Test 1: Basic sequence detection in vector: failed\n');
  fprintf('  Expected output:\n');
  disp(expectedOutput);
  fprintf('  Actual output:\n');
  disp(sequences);
end

%% Test 2: Sequence detection in a matrix (column-wise)

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
sequences = findsequences(testMatrix);

% Test 2 validation
test2Passed = isequal(sequences, expectedOutput);
if test2Passed
  fprintf('Test 2: Sequence detection in matrix (column-wise): passed\n');
else
  fprintf('Test 2: Sequence detection in matrix (column-wise): failed\n');
  fprintf('  Expected output:\n');
  disp(expectedOutput);
  fprintf('  Actual output:\n');
  disp(sequences);
end

%% Test 3: Detection of sequences with special values (NaN, 0, Inf, -Inf)

% Create a test vector with special values
testSpecial = [1, NaN, NaN, NaN, 0, 0, 5, Inf, Inf, -Inf, -Inf, -Inf, 10];
expectedOutput = [
  0, 5, 6, 2;
  NaN, 2, 4, 3;
  Inf, 8, 9, 2;
  -Inf, 10, 12, 3];

% Run findsequences
sequences = findsequences(testSpecial);

% Test 3 validation
% We need to handle NaN comparison specially
test3Passed = size(sequences, 1) == size(expectedOutput, 1);
if test3Passed
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
      test3Passed = false;
      break;
    end
  end
end

if test3Passed
  fprintf('Test 3: Detection of sequences with special values: passed\n');
else
  fprintf('Test 3: Detection of sequences with special values: failed\n');
  fprintf('  Expected output:\n');
  disp(expectedOutput);
  fprintf('  Actual output:\n');
  disp(sequences);
end

%% Test 4: Handling for invalid and edge-case inputs

% Test 4a: Empty array
try
  emptyOut = findsequences([]);
  test4aPassed = isempty(emptyOut);
catch ME
  test4aPassed = false;
end

% Test 4b: Scalar value
try
  scalarOut = findsequences(1);
  test4bPassed = isempty(scalarOut);
catch ME
  test4bPassed = false;
end

% Test 4c: Non-numeric input (should throw error)
try
  findsequences('string');
  test4cPassed = false;
catch ME
  test4cPassed = true;
end

% Test 4 validation
test4Passed = test4aPassed && test4bPassed && test4cPassed;
if test4Passed
  fprintf('Test 4: Handling for invalid and edge-case inputs: passed\n');
  fprintf(' - Test 4a: Empty array returns empty result: passed\n');
  fprintf(' - Test 4b: Scalar value returns empty result: passed\n');
  fprintf(' - Test 4c: Non-numeric input error: passed\n');
else
  fprintf('Test 4: Handling for invalid and edge-case inputs: failed\n');

  if ~test4aPassed
    fprintf(' - Test 4a: Empty array returns empty result: failed\n');
  else
    fprintf(' - Test 4a: Empty array returns empty result: passed\n');
  end

  if ~test4bPassed
    fprintf(' - Test 4b: Scalar value returns empty result: failed\n');
  else
    fprintf(' - Test 4b: Scalar value returns empty result: passed\n');
  end

  if ~test4cPassed
    fprintf(' - Test 4c: Non-numeric input error: failed\n');
  else
    fprintf(' - Test 4c: Non-numeric input error: passed\n');
  end
end

%% Test 5: Logical input

% Create logical array
logicalArray = logical([0 0 1 1 1 0 1 0 0 0]);
expectedOutput = [
    1, 3, 5, 3;
    
    0, 1, 2, 2;
    0, 8, 10, 3];

% Run findsequences
sequences = findsequences(logicalArray);

% Test 5 validation
test5Passed = isequal(sequences, expectedOutput);
if test5Passed
  fprintf('Test 5: Logical input: passed\n');
else
  fprintf('Test 5: Logical input: failed\n');
  fprintf('  Expected output:\n');
  disp(expectedOutput);
  fprintf('  Actual output:\n');
  disp(sequences);
end

%% Test 6: Multiple output arguments

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

% Test 6 validation
test7Passed = valuesCorrect && startPosCorrect && endPosCorrect && lengthsCorrect;
if test7Passed
  fprintf('Test 6: Multiple output arguments: passed\n');
else
  fprintf('Test 6: Multiple output arguments: failed\n');

  if ~valuesCorrect
    fprintf(' - Test 6a: Values output: failed\n');
    fprintf('   Expected: '); disp(expectedValues');
    fprintf('   Actual: '); disp(values');
  else
    fprintf(' - Test 6a: Values output: passed\n');
  end

  if ~startPosCorrect
    fprintf(' - Test 6b: Start positions output: failed\n');
    fprintf('   Expected: '); disp(expectedStartPos');
    fprintf('   Actual: '); disp(startPos');
  else
    fprintf(' - Test 6b: Start positions output: passed\n');
  end

  if ~endPosCorrect
    fprintf(' - Test 6c: End positions output: failed\n');
    fprintf('   Expected: '); disp(expectedEndPos');
    fprintf('   Actual: '); disp(endPos');
  else
    fprintf(' - Test 6c: End positions output: passed\n');
  end

  if ~lengthsCorrect
    fprintf(' - Test 6d: Lengths output: failed\n');
    fprintf('   Expected: '); disp(expectedLengths');
    fprintf('   Actual: '); disp(lengths');
  else
    fprintf(' - Test 6d: Lengths output: passed\n');
  end
end

%% Summarize all results
fprintf('\n---------------------------------------------------------\n');
fprintf('  SUMMARY: %i of %i tests passed\n', ...
  sum([test1Passed, test2Passed, test3Passed, test4Passed, test5Passed, test7Passed]), 6);
fprintf('---------------------------------------------------------\n\n');
