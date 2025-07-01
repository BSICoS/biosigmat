function [filteredSignal, filterCoeff] = lpdfilter(signal, fs, stopFreq, varargin)
% LPDFILTER Low-pass derivative filter for biomedical signals.
%   Applies a low-pass derivative (LPD) filter, which is useful for
%   enhancing features in biomedical signals like PPG or blood pressure,
%   often as a pre-processing step for pulse detection.
%
%   This implementation is based on the original work by Jesús Lázaro and
%   Pablo Armañac.
%
%   [filteredSignal, filterCoeff] = lpdfilter(signal, fs, stopFreq) applies
%   the LPD filter to the input signal with a specified stop frequency.
%
%   [filteredSignal, filterCoeff] = lpdfilter(signal, fs, stopFreq, Name, Value)
%   allows specifying additional options using name-value pairs.
%
% Inputs:
%   signal    - Input signal (numeric vector). Must be non-empty.
%   fs        - Sampling frequency in Hz (positive numeric scalar).
%   stopFreq  - Stop-band frequency in Hz (positive scalar).
%
% Name-Value Pair Arguments:
%   'PassFreq'     - Pass-band frequency in Hz (positive scalar).
%                    Default: stopFreq - 0.25 Hz.
%   'Order'        - Filter order (positive even integer).
%                    Default: Calculated automatically based on filter requirements.
%   'Coefficients' - Pre-computed filter coefficients (numeric vector).
%                    If provided, all other design parameters are ignored.
%                    Default: [] .
%
% Outputs:
%   filteredSignal - The LPD-filtered signal (column vector).
%   filterCoeff    - The filter coefficients used for filtering.

% Check number of input and output arguments
narginchk(3, 9);
nargoutchk(0, 2);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'lpdfilter';
addRequired(parser, 'signal', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);
addRequired(parser, 'stopFreq', @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'PassFreq', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x > 0));
addParameter(parser, 'Order', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x > 0 && mod(x,2)==0));
addParameter(parser, 'Coefficients', [], @(x) isempty(x) || (isnumeric(x) && isvector(x)));
parse(parser, signal, fs, stopFreq, varargin{:});

% Assign parsed inputs
signal = parser.Results.signal(:); 
fs = parser.Results.fs;
stopFreq = parser.Results.stopFreq;
passFreq = parser.Results.PassFreq;
filterOrder = parser.Results.Order;
filterCoeff = parser.Results.Coefficients;

% Ensure signal is a column vector for processing
signal = signal(:);

% Handle NaN values by using fillmissing
nanIdx = isnan(signal);
if any(nanIdx)
    if all(nanIdx)
        filteredSignal = signal;
        return;
    end
    % Fill NaN values using linear interpolation
    signal = fillmissing(signal, 'linear');
end

if isempty(filterCoeff)
    % Calculate default passFreq if not provided
    if isempty(passFreq)
        passFreq = stopFreq - 0.25; % Set passband 0.25 Hz below stopband
    end
    
    % Validate frequencies
    if passFreq <= 0
        error('lpdfilter:invalidFrequencies', 'PassFreq must be greater than 0.');
    end
    if passFreq >= stopFreq
        error('lpdfilter:invalidFrequencies', 'PassFreq must be less than StopFreq.');
    end
    if stopFreq >= fs/2
        error('lpdfilter:invalidStopFreq', 'StopFreq must be less than the Nyquist frequency (fs/2).');
    end

    % Calculate normalized frequencies
    wPass = passFreq / (fs/2);
    wStop = stopFreq / (fs/2);

    % Determine filter order if not provided
    if isempty(filterOrder)
        % Estimate minimum filter order using firpmord
        [estimatedOrder, ~, ~, ~] = firpmord([wPass, wStop], [1, 0], [0.01, 0.1]);
        
        % Ensure order is even for a Type-III differentiator
        filterOrder = estimatedOrder + mod(estimatedOrder, 2);
    end

    % Design the filter using a least-squares method
    filterSpecs = fdesign.differentiator('n,fp,fst', filterOrder, wPass, wStop);
    filterObj = design(filterSpecs, 'firls');

    % Apply scaling factor to coefficients
    filterCoeff = filterObj.Numerator * fs/(2*pi);
end

% The filtfilt function requires the signal to be at least 3x the filter order.
% For short signals, fall back to `filter` and compensate for the delay manually.
coeffLength = length(filterCoeff) - 1;
if length(signal) > 3 * coeffLength
    filteredSignal = filtfilt(filterCoeff, 1, signal);
else
    delay = round(coeffLength/2);
    tempSignal = filter(filterCoeff, 1, [signal; zeros(delay, 1)]);
    filteredSignal = tempSignal(delay+1:end);
end

if any(nanIdx)
    filteredSignal(nanIdx) = NaN;
end

filteredSignal = filteredSignal(:);

end
