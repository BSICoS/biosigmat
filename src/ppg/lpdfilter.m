function [filteredSignal, filterCoeff] = lpdfilter(signal, fs, varargin)
% LPDFILTER Low-pass derivative filter for biomedical signals.
%   Applies a low-pass derivative (LPD) filter, which is useful for
%   enhancing features in biomedical signals like PPG or blood pressure,
%   often as a pre-processing step for pulse detection.
%
%   This implementation is based on the original work by Jesús Lázaro and
%   Pablo Armañac.
%
%   [filteredSignal, filterCoeff] = lpdfilter(signal, fs) applies the LPD
%   filter to the input signal with default parameters.
%
%   [filteredSignal, filterCoeff] = lpdfilter(signal, fs, Name, Value)
%   allows specifying additional options using name-value pairs.
%
% Inputs:
%   signal    - Input signal (numeric vector). Must be non-empty.
%   fs        - Sampling frequency in Hz (positive numeric scalar).
%
% Name-Value Pair Arguments:
%   'Order'        - Filter order (positive even integer).
%                    Default: round(fs/2), ensures a reasonable filter length.
%   'PassFreq'     - Pass-band frequency in Hz (positive scalar).
%                    Default: 7.8 Hz.
%   'StopFreq'     - Stop-band frequency in Hz (positive scalar).
%                    Default: 8.0 Hz.
%   'Coefficients' - Pre-computed filter coefficients (numeric vector).
%                    If provided, all other design parameters are ignored.
%                    Default: [] .
%
% Outputs:
%   filteredSignal - The LPD-filtered signal (column vector).
%   filterCoeff    - The filter coefficients used for filtering.

% Check number of input and output arguments
narginchk(2, 10);
nargoutchk(0, 2);

% Parse and validate inputs
p = inputParser;
p.FunctionName = 'lpdfilter';
addRequired(p, 'signal', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(p, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'Order', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x > 0 && mod(x,2)==0));
addParameter(p, 'PassFreq', 7.8, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'StopFreq', 8.0, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'Coefficients', [], @(x) isempty(x) || (isnumeric(x) && isvector(x)));
parse(p, signal, fs, varargin{:});

% Assign parsed inputs
signal = p.Results.signal(:); 
fs = p.Results.fs;
order = p.Results.Order;
passFreq = p.Results.PassFreq;
stopFreq = p.Results.StopFreq;
filterCoeff = p.Results.Coefficients;

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
    
    if isempty(order)
        order = round(fs/2);
        % Ensure order is even
        if mod(order, 2) ~= 0
            order = order + 1;
        end
    end

    if passFreq >= stopFreq
        error('lpdfilter:invalidFrequencies', 'PassFreq must be less than StopFreq.');
    end
    if stopFreq >= fs/2
        error('lpdfilter:invalidStopFreq', 'StopFreq must be less than the Nyquist frequency (fs/2).');
    end

    wPass = passFreq / (fs/2);
    wStop = stopFreq / (fs/2);

    % Design the filter using a least-squares method
    filterSpecs = fdesign.differentiator('n,fp,fst', order, wPass, wStop);
    filterObj = design(filterSpecs, 'firls');

    % Apply scaling factor to coefficients
    filterCoeff = filterObj.Numerator * fs/(2*pi);
end

% The filtfilt function requires the signal to be at least 3x the filter order.
% For short signals, fall back to `filter` and compensate for the delay manually.
filterOrder = length(filterCoeff) - 1;
if length(signal) > 3 * filterOrder
    filteredSignal = filtfilt(filterCoeff, 1, signal);
else
    delay = round(filterOrder/2);
    tempSignal = filter(filterCoeff, 1, [signal; zeros(delay, 1)]);
    filteredSignal = tempSignal(delay+1:end);
end

if any(nanIdx)
    filteredSignal(nanIdx) = NaN;
end

filteredSignal = filteredSignal(:);

end
