% Tests covering:
%   - Basic vector sequence detection
%   - Matrix sequence detection
%   - Special values handling (NaN, Inf, -Inf)
%   - Empty and scalar input behavior
%   - Invalid input error handling
%   - Logical input sequence detection
%   - Multiple outputs formatting

classdef findsequencesTest < matlab.unittest.TestCase

  methods (TestClassSetup)
    function addCodeToPath(~)
      addpath('../../src/tools');
    end
  end

  methods (Test)
    function testBasicVectorSequence(tc)
      testVector = [1,1,1,2,3,3,4,5,5,5,5,6,7,7,8];
      expected = [
        1,1,3,3;
        3,5,6,2;
        5,8,11,4;
        7,13,14,2];
      actual = findsequences(testVector);
      tc.verifyEqual(actual, expected, 'Basic vector sequence detection failed');
    end

    function testMatrixSequence(tc)
      testMatrix = [
        1,2,3,4;
        1,5,6,7;
        1,8,9,10;
        2,11,12,13;
        2,14,15,16;
        3,17,18,19];
      expected = [
        1,1,3,3;
        2,4,5,2];
      actual = findsequences(testMatrix);
      tc.verifyEqual(actual, expected, 'Matrix sequence detection failed');
    end

    function testSpecialValues(tc)
      testSpecial = [1,NaN,NaN,NaN,0,0,5,Inf,Inf,-Inf,-Inf,-Inf,10];
      expected = [
        0,5,6,2;
        NaN,2,4,3;
        Inf,8,9,2;
        -Inf,10,12,3];
      actual = findsequences(testSpecial);
      tc.verifyEqual(size(actual,1), size(expected,1), 'Incorrect number of sequences for special values');
      for i = 1:size(actual,1)
        expRow = expected(i,:);
        actRow = actual(i,:);
        if isnan(expRow(1))
          tc.verifyTrue(isnan(actRow(1)), sprintf('NaN value detection failed at sequence %d', i));
          tc.verifyEqual(actRow(2:end), expRow(2:end), sprintf('Sequence indices mismatch for NaN sequence %d', i));
        else
          tc.verifyEqual(actRow, expRow, sprintf('Special value sequence mismatch at sequence %d', i));
        end
      end
    end

    function testEmptyInput(tc)
      tc.verifyEmpty(findsequences([]), 'Empty input should return empty result');
    end

    function testScalarInput(tc)
      tc.verifyEmpty(findsequences(1), 'Scalar input should return empty result');
    end

    function testInvalidInput(tc)
      tc.verifyError(@() findsequences('string'), '', 'Non-numeric input should throw an error');
    end

    function testLogicalInput(tc)
      logicalArray = logical([0 0 1 1 1 0 1 0 0 0]);
      expected = [
        1,3,5,3;
        0,1,2,2;
        0,8,10,3];
      actual = findsequences(logicalArray);
      tc.verifyEqual(actual, expected, 'Logical input sequence detection failed');
    end

    function testMultipleOutputs(tc)
      testVector = [1,1,1,2,3,3,4,5,5,5,5,6,7,7,8];
      [values, startPos, endPos, lengths] = findsequences(testVector);
      tc.verifyEqual(values, [1;3;5;7], 'Values output incorrect');
      tc.verifyEqual(startPos, [1;5;8;13], 'Start positions output incorrect');
      tc.verifyEqual(endPos, [3;6;11;14], 'End positions output incorrect');
      tc.verifyEqual(lengths, [3;2;4;2], 'Sequence lengths output incorrect');
    end
  end

end
