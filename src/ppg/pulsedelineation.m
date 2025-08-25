function [nA, nB, nM] = pulsedelineation(dppg, fs, nD, varargin)
% PULSEDELINEATION Performs pulse delineation in PPG signals using adaptive thresholding.
%
%   [NA, NB, NM] = PULSEDELINEATION(DPPG, FS, ND) performs pulse delineation
%   in photoplethysmographic (PPG) signals, detecting pulse features (nA, nB, nM)
%   based on pulse detection points (nD). DPPG is the filtered LPD-filtered PPG
%   signal (numeric vector), FS is the sampling rate in Hz (positive scalar), and
%   ND contains pre-computed pulse detection points in seconds (numeric vector).
%   NA returns pulse onset locations in seconds, NB returns pulse offset locations
%   in seconds, and NM returns pulse midpoint locations in seconds.
%
%   [NA, NB, NM] = PULSEDELINEATION(..., 'Name', Value) specifies additional
%   parameters using name-value pairs:
%     'WindowA'  - Window width for searching pulse onset in seconds
%                  (default: 250e-3)
%     'WindowB'  - Window width for searching pulse offset in seconds
%                  (default: 150e-3)
%     'InterpFS' - Sampling frequency for interpolation in Hz
%                  (default: 2*FS)
%
%   Example:
%     % Load PPG signal and apply LPD filtering
%     ppgData = readtable('ppg_signals.csv');
%     signal = ppgData.sig(1:30000);
%     fs = 1000;
%
%     % Apply LPD filter
%     [b, delay] = lpdfilter(fs, 8, 'PassFreq', 7.8, 'Order', 100);
%     signalFiltered = filter(b, 1, signal);
%     signalFiltered = [signalFiltered(delay+1:end); zeros(delay, 1)];
%
%     % Compute pulse detection points
%     nD = pulsedetection(signalFiltered, fs);
%
%     % Perform pulse delineation
%     [nA, nB, nM] = pulsedelineation(signalFiltered, fs, nD);
%
%     % Plot results
%     t = (0:length(signal)-1)/fs;
%     figure;
%     plot(t, signal, 'k');
%     hold on;
%     plot(nA, signal(1+round(nA*fs)), 'ro', 'MarkerFaceColor', 'r');
%     plot(nB, signal(1+round(nB*fs)), 'go', 'MarkerFaceColor', 'g');
%     plot(nM, signal(1+round(nM*fs)), 'bo', 'MarkerFaceColor', 'b');
%     legend('PPG Signal', 'Onset (nA)', 'Offset (nB)', 'Midpoint (nM)');
%     xlabel('Time (s)');
%     ylabel('Amplitude');
%     title('PPG Pulse Delineation');
%
%   See also PULSEDETECTION, LPDFILTER
%
%   Status: Alpha

% Check number of input and output arguments
narginchk(3, 9);
nargoutchk(0, 3);

% Parse and validate inputs
parser = inputParser;
parser.FunctionName = 'pulsedelineation';
addRequired(parser, 'signal', @(x) isnumeric(x) && isvector(x) && ~isempty(x));
addRequired(parser, 'fs', @(x) isnumeric(x) && isscalar(x) && x > 0);
addRequired(parser, 'nD', @(x) isnumeric(x) && (isvector(x) || isempty(x)));
addParameter(parser, 'WindowA', 250e-3, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'WindowB', 150e-3, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(parser, 'InterpFS', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x > 0));

parse(parser, dppg, fs, nD, varargin{:});

dppg = parser.Results.signal;
fs = parser.Results.fs;
nD = parser.Results.nD;
wdw_nA = parser.Results.WindowA;
wdw_nB = parser.Results.WindowB;
fsi = parser.Results.InterpFS;

% Set default interpolation frequency if not provided
if isempty(fsi)
    fsi = 2 * fs;
end


% Ensure signal is a column vector
dppg = dppg(:);

% Compute delineation
peakSetup.wdw_nB = wdw_nB;
peakSetup.wdw_nA = wdw_nA;
peakSetup.fsi = fsi;

[nA, nB, nM] = delineationAlgorithm(dppg, fs, nD, peakSetup);

end

function varargout = delineationAlgorithm ( dppg , fs , nD , Setup )
%
% Delineation for plethysmography signals, given nD_in (=nD) as anchor point
%
% Inputs
%         dppg           signal
%         fs            sampling frequency [Hertz]
%         nD	detections in the maximum of the first derivative of the PPG [seconds] (detected at fs)
%         wdw_nB        window width for searching the minimum before nD [seconds] (default = 150e-03)
%         wdw_nA        window width for searching the maximum after  nD [seconds] (default = 200e-03)
%         fsi           sampling frequency for interpolation. Fine search of the peaks [Hertz]
%
%
% Outputs all (detected at fsi) [seconds]
%         nA            Maximum of the PPG pulse
%         nB            Minimum of the PPG pulse
%         nM            Medium  of the PPG pulse
%
%
% Esto se tiene que optimizar.
%       1) findpeaks.
%       2) interp1 lo hace or vectores, pues se hace directamente en vez de en el for
%
%

%% Check Inputs
if nargin <= 3,   Setup = struct();                       end
if nargin <  3,   error('Not enough input arguments.');   end

% Default Values
if ~isfield(Setup,'wdw_nA'),	Setup.wdw_nA    = 250e-3;	end
if ~isfield(Setup,'wdw_nB'),	Setup.wdw_nB    = 150e-3;	end
if ~isfield(Setup,'fsi'),       Setup.fsi       = fs;       end

% Get, assign and store the variable names
data_names = fieldnames(Setup);
for ii = 1:length(data_names), eval([ data_names{ii} ' = Setup.' data_names{ii} ';']); end
clear Setup data_names ii bb aa

% Check inputs
if isempty(nD)
    varargout{1} = NaN;
    varargout{2} = NaN;
    varargout{3} = NaN;
    varargout{4} = NaN;
    return;
end

% Delineation
warning off

nD = nD( ~isnan(nD(:)) );
nD = 1 + round ( nD*fsi );

t           =	0:1/fs:  (length(dppg)-1)/fs;
t_i         =	0:1/fsi:((length(dppg)*(fsi/fs)-1)/fsi);
signal_i	=   interp1( t , dppg , t_i , 'spline' );


if nargout>=1

    % nA
    mtx_nA = repmat( 0:round(wdw_nA*fsi) ,	length(nD) , 1 ) + nD;
    mtx_nA(mtx_nA<1)=1; mtx_nA(mtx_nA>length(signal_i))=length(signal_i);
    [~,i_nA] = max ( signal_i(mtx_nA),[],2 ); i_nA = i_nA + nD;
    i_nA(i_nA<1 | i_nA>length(signal_i)) = NaN;

    nA = NaN(length(i_nA),1);
    nA(~isnan(i_nA)) = t_i(i_nA(~isnan(i_nA)));

    varargout{1} = nA;

end


if nargout>=2

    % nB
    mtx_nB = repmat( -round(wdw_nB*fsi):0 ,	length(nD) , 1 ) + nD;
    mtx_nB(mtx_nB<1)=1; mtx_nB(mtx_nB>length(signal_i))=length(signal_i);
    [~,i_nB] = min ( signal_i(mtx_nB),[],2 ); i_nB = i_nB +(nD-round(wdw_nB*fsi));
    i_nB(i_nB<1 | i_nB>length(signal_i)) = NaN;

    nB = NaN(length(i_nB),1);
    nB(~isnan(i_nB)) = t_i(i_nB(~isnan(i_nB)));

    varargout{2} = nB;

end


if nargout>=3
    % nM

    nM = NaN(length(nD),1);
    for ii = 1:length(nD)

        if (isnan(i_nB(ii)) || isnan(i_nA(ii))), continue; end
        pulseAmplitude = (signal_i(i_nB(ii))+signal_i(i_nA(ii)))/2;
        mtx_nM = i_nB(ii):i_nA(ii); mtx_nM(mtx_nM<1)=1; mtx_nM(mtx_nM>length(signal_i))=length(signal_i);
        [~,i_nM] = max ( - abs( signal_i(mtx_nM) - pulseAmplitude' ) ,[],2 ); i_nM = i_nM + i_nB(ii) ;
        i_nM(i_nM<1 | i_nM>length(signal_i)) = NaN;
        if ~isnan(i_nM) || ~isempty(i_nM), nM(ii) = t_i(i_nM); end

    end

    varargout{3} = nM;
end


if nargout>=4

    fc = 25;
    nD = NaN(length(nD),1);

    if fc<fs/2

        % nD
        [bb,aa] = butter(5,fc*2/fs,'low');
        diffSignal = nanfiltfilt(bb,aa,diffSignal); %#ok

        wdw_nD	=   round(0.030*fsi);
        mtx_nD = repmat( -wdw_nD:wdw_nD , length(nD) , 1 ) + nD;
        mtx_nD(mtx_nD<1)=1; mtx_nD(mtx_nD>length(signal_i))=length(signal_i);

        diffSignal_i	=   interp1( t , diffSignal , t_i , 'spline' );
        [~,i_nDi] = max ( diffSignal_i(mtx_nD),[],2 ); i_nDi = i_nDi + (nD-wdw_nD);
        i_nDi(i_nDi<1 | i_nDi>length(signal_i)) = NaN;

        nD = NaN(length(i_nDi),1);
        nD(~isnan(i_nDi)) = t_i(i_nDi(~isnan(i_nDi)));


    end

    varargout{4} = nD;
end


warning on

end