classdef refinePeakPositionsTest < matlab.unittest.TestCase
    % Tests covering:
    %   - Basic functionality with maximum search
    %   - Minimum search capability
    %   - Empty input handling
    %   - Edge cases with interpolation parameters

    methods (TestClassSetup)
        function addToPath(~)
            addpath(fullfile('..', '..', 'src', 'tools'));
        end
    end

    methods (Test)
        function testBasicMaximumRefinement(tc)
            % Test basic functionality with synthetic signal
            fs = 1000;
            t = (0:1/fs:1-1/fs)';

            % Create synthetic signal with known peaks
            signal = sin(2*pi*5*t) + 0.1*sin(2*pi*50*t);

            % Coarse peak detection
            [~, peaks] = findpeaks(signal, 'MinPeakHeight', 0.5);
            candidatePositions = (peaks - 1) / fs;

            % Refine positions
            refinedPositions = refinePeakPositions(signal, fs, candidatePositions);

            % Verify basic properties
            tc.verifyClass(refinedPositions, 'double', 'Refined positions should be double');
            tc.verifySize(refinedPositions, size(candidatePositions), 'Size should match input');
            tc.verifyTrue(all(~isnan(refinedPositions)), 'No NaN values expected for valid input');
        end

        function testMinimumSearch(tc)
            % Test minimum search functionality
            fs = 1000;
            t = (0:1/fs:0.5-1/fs)';

            % Create inverted signal for minimum testing
            signal = -sin(2*pi*5*t);

            % Find coarse minima (peaks in inverted signal)
            [~, peaks] = findpeaks(-signal, 'MinPeakHeight', 0.5);
            candidatePositions = (peaks - 1) / fs;

            % Refine using minimum search
            refinedPositions = refinePeakPositions(signal, fs, candidatePositions, ...
                'SearchType', 'min');

            % Verify results
            tc.verifyClass(refinedPositions, 'double', 'Refined positions should be double');
            tc.verifySize(refinedPositions, size(candidatePositions), 'Size should match input');
            tc.verifyTrue(all(~isnan(refinedPositions)), 'No NaN values expected for valid input');
        end

        function testEmptyInput(tc)
            % Test handling of empty input
            fs = 1000;
            signal = sin(2*pi*5*(0:1/fs:1-1/fs))';

            % Test empty candidate positions
            refinedPositions = refinePeakPositions(signal, fs, []);
            tc.verifyEmpty(refinedPositions, 'Empty input should return empty output');
        end

        function testNaNInput(tc)
            % Test handling of NaN values in input
            fs = 1000;
            signal = sin(2*pi*5*(0:1/fs:1-1/fs))';
            candidatePositions = [0.1; NaN; 0.3; NaN; 0.5];

            % Refine positions (should ignore NaN values)
            refinedPositions = refinePeakPositions(signal, fs, candidatePositions);

            % Should return empty since only valid positions are processed
            tc.verifyTrue(length(refinedPositions) <= length(candidatePositions), ...
                'Output should not be longer than input');
        end

        function testCustomParameters(tc)
            % Test custom interpolation parameters
            fs = 1000;
            signal = sin(2*pi*5*(0:1/fs:1-1/fs))';
            candidatePositions = [0.2; 0.4; 0.6];

            % Test with custom interpolation factor and window width
            refinedPositions = refinePeakPositions(signal, fs, candidatePositions, ...
                'InterpFactor', 4, 'WindowWidth', 0.050);

            % Verify basic properties
            tc.verifyClass(refinedPositions, 'double', 'Refined positions should be double');
            tc.verifySize(refinedPositions, size(candidatePositions), 'Size should match input');
        end
    end
end
