function [b, delay] = lpdfilter(fs, stopFreq, varargin)
% LPDFILTER Low-pass derivative filter.
%   Designs a low-pass derivative (LPD) linear-phase FIR filter using
%   least-squares estimation. The estimator filter minimizes the weighted
%   integrated squared error between an ideal piecewise linear function
%   and the magnitude response of the filter.
%
%   filterCoeff = lpdfilter(fs, stopFreq) designs an LPD filter with
%   automatically determined passband frequency and filter order.
%
%   filterCoeff = lpdfilter(fs, stopFreq, Name, Value) allows specifying
%   additional options using name-value pairs.
%
% Inputs:
%   fs        - Sampling frequency in Hz (positive numeric scalar).
%               Must be greater than 2 * stopFreq to satisfy Nyquist criterion.
%   stopFreq  - Stop-band frequency in Hz (positive scalar).
%               Frequencies above this will be attenuated.
%
% Name-Value Pair Arguments:
%   'PassFreq'     - Pass-band frequency in Hz (positive scalar).
%                    Must be less than stopFreq. If not specified, defaults
%                    to stopFreq - 0.2 Hz for optimal transition band.
%   'Order'        - Filter order (positive even integer).
%                    Higher orders provide sharper transitions but increased
%                    computational cost. If not specified, automatically
%                    calculated based on transition band requirements.
%
% Outputs:
%   b    - Filter impulsional response (1 x (Order+1) numeric array).
%          Ready for use with filter() or conv(). Coefficients are scaled by
%          fs/(2*pi) to approximate continuous-time derivative (from per-sample
%          to per-second)
%   delay - Delay introduced by the filter (scalar).
%
% Example:
%   % Design filter and visualize the frequency response
%   fs = 100;
%   [b, delay] = lpdfilter(fs, 10);
%
%   [h, w] = freqz(b, 1, 2^16);
%   figure;
%   plot(w*fs/(2*pi), abs(h)/max(abs(h)));
%   title('Normalized Frequency Response');
%   xlabel('Frequency (Hz)');
%   ylabel('Magnitude');
%   grid on;
%
%   % Apply filter to a signal and compensate delay
%   signalFiltered = filter(b, 1, signal);
%   signalFiltered = [signalFiltered(delay+1:end); zeros(delay, 1)];

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
