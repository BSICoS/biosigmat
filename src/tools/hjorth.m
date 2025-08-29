function [h0, h1, h2] = hjorth(x, fs)
% HJORTH Computes Hjorth parameters (activity, mobility, and complexity) from a signal.
%
%   [H0, H1, H2] = HJORTH(X, FS) computes the three Hjorth parameters from the
%   input signal X sampled at frequency FS. X is the input signal (numeric vector)
%   and FS is the sampling frequency in Hz (positive scalar). The function returns
%   H0 (activity), H1 (mobility), and H2 (complexity) computed using spectral
%   moments of order 0, 2, and 4. The first and second derivatives of the signal
%   are computed automatically using numerical differentiation.
%
%   Example:
%     % Compute Hjorth parameters for a synthetic signal
%     fs = 1000;  % Sampling frequency
%     t = 0:1/fs:2;  % Time vector
%     x = sin(2*pi*10*t) + 0.5*sin(2*pi*50*t) + randn(size(t))*0.1;
%
%     % Calculate Hjorth parameters
%     [h0, h1, h2] = hjorth(x, fs);
%
%     % Display results
%     fprintf('Activity (H0): %.4f\n', h0);
%     fprintf('Mobility (H1): %.4f Hz\n', h1);
%     fprintf('Complexity (H2): %.4f\n', h2);
%
%   See also VAR, DIFF

% Check number of input and output arguments
narginchk(2, 2);
nargoutchk(0, 3);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'hjorth';
addRequired(parser, 'x', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);

parse(parser, x, fs);

x = parser.Results.x;
fs = parser.Results.fs;

% Ensure x is a column vector
x = x(:);

% Compute first and second derivatives
dx = [NaN; diff(x)];
ddx = [NaN; diff(dx)];

% Compute spectral moments
w0 = (2*pi/length(x)) * sum(x.^2);
w2 = (2*pi/length(x)) * sum(dx(~isnan(dx)).^2);
w4 = (2*pi/length(x)) * sum(ddx(~isnan(ddx)).^2);

% Compute Hjorth parameters
h0 = var(x); % Activity
h1 = abs(sqrt(w2/w0)) * fs / (2*pi); % Mobility
h2 = abs(sqrt((w4/w2) - (w2/w0))) * fs / (2*pi); % Complexity

end