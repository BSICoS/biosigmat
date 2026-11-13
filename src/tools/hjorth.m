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
%     fprintf('Complexity (H2): %.4f Hz\n', h2);
%
%   See also MEAN, DIFF

% Check number of input and output arguments
narginchk(2, 2);
nargoutchk(0, 3);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'hjorth';
addRequired(parser, 'x', @(x) isnumeric(x) && isreal(x) && isvector(x) && ...
    ~isempty(x) && ~any(isinf(x(:))));
addRequired(parser, 'fs', @(x) isnumeric(x) && isreal(x) && isscalar(x) && isfinite(x) && x > 0);

parse(parser, x, fs);

x = parser.Results.x;
fs = double(parser.Results.fs);

% Ensure x is a floating-point column vector
x = double(x(:));

% Compute first and second differences
dx = diff(x);
ddx = diff(dx);

% Compute signal and difference energies
e0 = sum(x.^2);
e1 = sum(dx.^2);
e2 = sum(ddx.^2);

% Compute Hjorth parameters
h0 = e0 / length(x); % Activity (mean-square power)
h1 = NaN;
h2 = NaN;
if length(x) >= 2 && e0 > 0
    h1 = sqrt(e1/e0) * fs / (2*pi); % Mobility
end
if length(x) >= 3 && e0 > 0 && e1 > 0
    h2 = sqrt(abs(e2/e1 - e1/e0)) * fs / (2*pi); % Complexity
end

end
