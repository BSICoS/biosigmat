classdef nanfiltfiltTest < matlab.unittest.TestCase

  methods (TestClassSetup)
    function addCodeToPath(~)
      addpath('../../src/tools');
    end
  end

  methods (Test)
    function testDependencies(tc)
      tc.verifyTrue(exist('findsequences','file')==2, 'Dependency findsequences missing');
    end

    function testNoisySinusoidWithNans(tc)
      n = 100;
      t = linspace(0,2*pi,n).';
      original = sin(t);
      rng(0);
      noisy = original + 0.2*randn(n,1);
      nanIdx = randperm(n,round(n*0.1));
      signalWithNans = noisy;
      signalWithNans(nanIdx) = NaN;
      [b,a] = butter(2,0.1);
      maxgap = length(signalWithNans);
      filtered = nanfiltfilt(b,a,signalWithNans,maxgap);
      tc.verifyFalse(any(isnan(filtered)), 'Noisy sinusoid with NaNs: NaN values were not interpolated when maxgap=length');
    end

    function testNoisySinusoidWithBursts(tc)
      n = 100;
      t = linspace(0,2*pi,n).';
      original = sin(t);
      rng(0);
      noisy = original + 0.2*randn(n,1);
      signalBurst = noisy;
      signalBurst(15:17) = NaN;
      signalBurst(70:80) = NaN;
      [b,a] = butter(2,0.1);
      maxgap = 3;
      filteredBurst = nanfiltfilt(b,a,signalBurst,maxgap);
      tc.verifyFalse(any(isnan(filteredBurst(15:17))), 'NaN burst (15:17) was not interpolated as expected');
      tc.verifyTrue(all(isnan(filteredBurst(70:80))), 'NaN burst (70:80) should have been preserved');
    end

    function testAllNaNSignal(tc)
      n = 100;
      allNaN = NaN(n,1);
      [b,a] = butter(2,0.1);
      maxgap = n;
      filteredAll = nanfiltfilt(b,a,allNaN,maxgap);
      tc.verifyTrue(all(isnan(filteredAll)), 'All-NaN input did not produce all-NaN output');
    end

    function testNoNaNSignal(tc)
      n = 100;
      t = linspace(0,2*pi,n).';
      original = sin(t);
      rng(0);
      noisy = original + 0.2*randn(n,1);
      [b,a] = butter(2,0.1);
      maxgap = n;
      filtered = nanfiltfilt(b,a,noisy,maxgap);
      standardFilt = filtfilt(b,a,noisy);
      tc.verifyLessThan(max(abs(filtered-standardFilt)), 1e-10, 'No-NaN input: filtered output does not match standard filtfilt');
    end

    function testMissingMaxgap(tc)
      n = 100;
      t = linspace(0,2*pi,n).';
      original = sin(t);
      rng(0);
      noisy = original + 0.2*randn(n,1);
      signalBurst = noisy;
      signalBurst(15:17) = NaN;
      signalBurst(70:80) = NaN;
      [b,a] = butter(2,0.1);
      warning("on", "all"); % Ensure warnings are enabled
      tc.verifyWarning(@() nanfiltfilt(b,a,signalBurst), 'nanfiltfilt:maxgapNotSpecified', 'Missing maxgap: warning not issued');
      warning("off", "all"); % Disable warnings for the next test
      filteredNoMax = nanfiltfilt(b,a,signalBurst);
      warning("on", "all"); % Re-enable warnings
      tc.verifyEqual(isnan(filteredNoMax), isnan(signalBurst), 'Missing maxgap: NaNs were replaced unexpectedly');
    end

    function testInsufficientInputs(tc)
      [b,a] = butter(2,0.1);
      f = @() nanfiltfilt(b,a);
      tc.verifyError(f, 'nanfiltfilt:notEnoughInputs', 'Insufficient inputs: error not thrown');
    end

    function testMultiColumnNoisyWithNans(tc)
      n = 100;
      t = linspace(0,2*pi,n).';
      originalSignal = sin(t);
      rng(0);
      numCols = 3;
      noiseMat = 0.2 * randn(n, numCols);
      signalMat = repmat(originalSignal, 1, numCols) + noiseMat;
      signalWithNansMat = signalMat;
      for c = 1:numCols
        idx = randperm(n, round(n*0.1));
        signalWithNansMat(idx, c) = NaN;
      end
      [b,a] = butter(2,0.1);
      filteredMat = nanfiltfilt(b, a, signalWithNansMat, n);
      tc.verifyFalse(any(isnan(filteredMat), 'all'), 'Multi-column noisy with NaNs: NaNs were not all interpolated when maxgap=length');
    end

    function testMultiColumnWithBursts(tc)
      n = 100;
      t = linspace(0,2*pi,n).';
      originalSignal = sin(t);
      rng(0);
      numCols = 3;
      noiseMat = 0.2 * randn(n, numCols);
      signalMat = repmat(originalSignal, 1, numCols) + noiseMat;
      signalBurstsMat = signalMat;
      signalBurstsMat(15:17, :) = NaN;
      signalBurstsMat(70:80, :) = NaN;
      [b,a] = butter(2,0.1);
      filteredBurstsMat = nanfiltfilt(b, a, signalBurstsMat, 3);
      tc.verifyTrue(all(isnan(filteredBurstsMat(70:80,:)), 'all'), 'Multi-column bursts: large NaN bursts not preserved');
      tc.verifyFalse(any(isnan(filteredBurstsMat(15:17,:)), 'all'), 'Multi-column bursts: small NaN bursts not interpolated');
    end

    function testMultiColumnAllNaNSignal(tc)
      n = 100;
      rng(0);
      numCols = 3;
      allNanMat = NaN(n, numCols);
      [b,a] = butter(2,0.1);
      filteredAllNanMat = nanfiltfilt(b, a, allNanMat, 3);
      tc.verifyTrue(all(isnan(filteredAllNanMat), 'all'), 'Multi-column all-NaN input did not produce all-NaN output');
    end

    function testMultiColumnNoNaNSignal(tc)
      n = 100;
      t = linspace(0,2*pi,n).';
      originalSignal = sin(t);
      rng(0);
      numCols = 3;
      noiseMat = 0.2 * randn(n, numCols);
      signalMat = repmat(originalSignal, 1, numCols) + noiseMat;
      [b,a] = butter(2,0.1);
      filteredNoNanMat = nanfiltfilt(b, a, signalMat, 3);
      standardMat = filtfilt(b, a, signalMat);
      tc.verifyLessThan(max(abs(filteredNoNanMat - standardMat), [], 'all'), 1e-10, 'Multi-column no-NaN input does not match standard filtfilt');
    end

    function testMultiColumnMissingMaxgap(tc)
      n = 100;
      t = linspace(0,2*pi,n).';
      originalSignal = sin(t);
      rng(0);
      numCols = 3;
      noiseMat = 0.2 * randn(n, numCols);
      signalMat = repmat(originalSignal, 1, numCols) + noiseMat;
      signalBurstsMat = signalMat;
      signalBurstsMat(15:17, :) = NaN;
      signalBurstsMat(70:80, :) = NaN;
      [b,a] = butter(2,0.1);
      warning("on", "all"); % Ensure warnings are enabled
      tc.verifyWarning(@() nanfiltfilt(b,a,signalBurstsMat), 'nanfiltfilt:maxgapNotSpecified', 'Multi-column missing maxgap: warning not issued');
      warning("off", "all"); % Disable warnings for the next test
      filteredNoMaxgapMat = nanfiltfilt(b, a, signalBurstsMat);
      warning("on", "all"); % Re-enable warnings
      tc.verifyTrue(all(isnan(filteredNoMaxgapMat) == isnan(signalBurstsMat), 'all'), 'Multi-column missing maxgap: NaNs were replaced unexpectedly');
    end
  end

end
