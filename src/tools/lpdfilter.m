function [b, delay] = lpdfilter(fs, stopFreq, varargin)
% LPDFILTER Low-pass derivative filter.
%
%   B = LPDFILTER(FS, STOPFREQ) designs a low-pass derivative (LPD)
%   linear-phase FIR filter with a specified sampling frequency FS
%   and stop-band frequency STOPFREQ. using least-squares estimation.
%
%   B = LPDFILTER(..., Name, Value) allows specifying additional options
%   using name-value pairs.
%     'PassFreq' - Pass-band frequency in Hz (positive scalar).
%                  Must be less than STOPFREQ. If not specified, defaults
%                  to (STOPFREQ - 0.2) Hz.
%     'Order'    - Filter order (positive even integer). If not specified,
%                  automatically calculated based on transition band requirements.
%
%   [B, DELAY] = LPDFILTER(...) also returns the filter delay, which is half the filter order.
%
%   Example:
%     % Design filter and visualize the frequency response
%     fs = 100;
%     [b, delay] = lpdfilter(fs, 10);
%
%     [h, w] = freqz(b, 1, 2^16);
%     figure;
%     plot(w*fs/(2*pi), abs(h)/max(abs(h)));
%     title('Normalized Frequency Response');
%     xlabel('Frequency (Hz)');
%     ylabel('Magnitude');
%     grid on;
%
%     % Apply filter to a signal and compensate delay
%     signalFiltered = filter(b, 1, signal);
%     signalFiltered = [signalFiltered(delay+1:end); zeros(delay, 1)];
%
%   See also FIRPMORD, FIRLS, FDESIGN.DIFFERENTIATOR


% Argument validation
narginchk(2, 6);
nargoutchk(0, 2);

% Input validation
parser = inputParser;
parser.FunctionName = 'lpdfilter';
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);
addRequired(parser, 'stopFreq', @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'PassFreq', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x > 0));
addParameter(parser, 'Order', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x > 0));
parse(parser, fs, stopFreq, varargin{:});

% Assign parsed inputs
fs = parser.Results.fs;
stopFreq = parser.Results.stopFreq;
passFreq = parser.Results.PassFreq;
order = parser.Results.Order;

% Calculate default passFreq if not provided
if isempty(passFreq)
    passFreq = stopFreq - 0.2; % Set passband 0.25 Hz below stopband
end

% Validate frequencies
if passFreq >= stopFreq
    error('lpdfilter:invalidFrequencies', 'PassFreq must be less than StopFreq.');
end
if stopFreq >= fs/2
    error('lpdfilter:invalidStopFreq', 'StopFreq must be less than the Nyquist frequency (fs/2).');
end

% Calculate normalized frequencies
wPass = passFreq / (fs/2);
wStop = stopFreq / (fs/2);

% Determine filter order if not provided.
if isempty(order)
    order = firpmord([wPass, wStop], [1, 0], [0.01, 0.1]);
end

% Ensure order is even for a Type-III differentiator
order = order + mod(order, 2);

% Design the filter using a least-squares method
filterSpecs = fdesign.differentiator('n,fp,fst', order, wPass, wStop);
filterObj = design(filterSpecs, 'firls');
b = filterObj.Numerator * fs/(2*pi);
delay = order / 2;

end
