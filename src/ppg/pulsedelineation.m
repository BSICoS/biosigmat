function [ nD , nA , nB , nM , threshold ] = pulsedelineation ( signal , fs , Setup )
% PULSEDELINEATION Plethysmography signals delineation using adaptive thresholding.
% [ nD , nA , nB , nM , threshold ] = pulsedelineation ( signal , fs , Setup )
%
% This function performs pulse delineation in PPG signals, detecting pulse
% features (nA, nB, nM) based on pulse detection points (nD). If nD points
% are not provided, they are computed using the pulsedetection function.
%
%   In:
%         signal        = Filtered LPD-filtered PPG signal
%         fs            = sampling rate (Hz)
%         Setup         = Structure with optional parameters:
%           .nD         = Pre-computed pulse detection points [Default: []]
%           .alfa       = Multiplies previous amplitude of detected maximum in
%                         filtered signal for updating the threshold [Default: 0.2]
%           .refractPeriod = Refractory period for threshold (s) [Default: 150e-3]
%           .tauRR      = Fraction of estimated RR where threshold reaches its
%                         minimum value (alfa*amplitude of previous SSF peak)
%                         [Default: 1]. If tauRR increases, steeper slope
%           .thrIncidences = Threshold for incidences [Default: 1.5]
%           .wdw_nA     = Window width for searching pulse onset [Default: 250e-3]
%           .wdw_nB     = Window width for searching pulse offset [Default: 150e-3]
%           .fsi        = Sampling frequency for interpolation [Default: 2*fs]
%           .computePeakDelineation = Enable peak delineation [Default: true]
%
%   Out:
%         nD            = Location of peaks detected in filtered signal (seconds)
%         nA            = Location of pulse onsets (seconds)
%         nB            = Location of pulse offsets (seconds)
%         nM            = Location of pulse midpoints (seconds)
%         threshold     = Computed time varying threshold
%
% EXAMPLE:
%   % LPD-filter PPG signal
%   [b, delay] = lpdfilter(fs, fcLPD, 'PassFreq', fpLPD, 'Order', orderLPD);
%   signalFiltered = filter(b, 1, signal);
%   signalFiltered = [signalFiltered(delay+1:end); zeros(delay, 1)];
%
%   % Set up pulse delineation parameters
%   Setup = struct();
%   Setup.alfa = 0.2;                   % Threshold adaptation factor
%   Setup.refractPeriod = 150e-3;       % Refractory period (s)
%   Setup.thrIncidences = 1.5;          % Threshold for incidences
%   Setup.wdw_nA = 250e-3;              % Window for onset detection (s)
%   Setup.wdw_nB = 150e-3;              % Window for offset detection (s)
%
%   % Run pulse delineation on filtered signal
%   [nD, nA, nB, nM, threshold] = pulsedelineation(signalFiltered, fs, Setup);
%
% STATUS: Beta


% Check Inputs
if nargin <= 2,   Setup = struct();                       end
if nargin <  2,   error('Not enough input arguments.');   end

% Default Values
if ~isfield(Setup,'nD'),                        Setup.nD =	[];                                 end

if ~isfield(Setup,'Lenvelope'),                 Setup.Lenvelope = 300;                end

if ~isfield(Setup,'alfa'),                      Setup.alfa = 0.2;                               end
if ~isfield(Setup,'tauRR'),                     Setup.tauRR = 1;                                end
if ~isfield(Setup,'refractPeriod'),             Setup.refractPeriod = 150e-03;                  end
if ~isfield(Setup,'thrIncidences'),             Setup.thrIncidences = 1.5;                      end

if ~isfield(Setup,'wdw_nA'),                    Setup.wdw_nA = 250e-3;                          end
if ~isfield(Setup,'wdw_nB'),                    Setup.wdw_nB = 150e-3;                          end
if ~isfield(Setup,'fsi'),                       Setup.fsi = 2*fs;                                 end

if ~isfield(Setup,'computeAdaptiveThreshold'),  Setup.computeAdaptiveThreshold = true;          end
if ~isfield(Setup,'computeEnvelopesThreshold'), Setup.computeEnvelopesThreshold = false;       end
if ~isfield(Setup,'computePeakDelineation'),	Setup.computePeakDelineation	=	true;       end


% Get, assign and store the variable names
data_names = fieldnames(Setup);
for ii = 1:length(data_names), eval([ data_names{ii} ' = Setup.' data_names{ii} ';']); end
clear Setup data_names ii


signal = signal(:);


%% Compute threshold and nD detection
threshold = NaN(length(signal),1);
if isempty (nD) %#ok
    detectionSetup.alfa            = alfa;
    detectionSetup.tauRR           = tauRR;
    detectionSetup.refractPeriod   = refractPeriod;
    detectionSetup.thrIncidences   = thrIncidences;

    [ nD , threshold ] = pulsedetection ( signal, fs, detectionSetup );
end


%% Compute delineation
nA = []; nB = []; nM = [];
if computePeakDelineation
    peakSetup.wdw_nB        =   wdw_nB;
    peakSetup.wdw_nA        =   wdw_nA;
    peakSetup.fsi           =   fsi;
    peakSetup.diffSignal    =   signal;

    [ nA , nB , nM ] = fastPeakDelineation ( signal , fs , nD , peakSetup ) ;
end


end

function varargout = fastPeakDelineation ( signal , fs , nD , Setup )
%
% Peak delineation for plethysmography signals, given nD_in (=nD) as anchor point
%
% Inputs
%         signal           signal
%         fs            sampling frequency [Hertz]
%         nD	detections in the maximum of the first derivative of the PPG [seconds] (detected at fs)
%         wdw_nB        window width for searching the minimum before nD [seconds] (default = 150e-03)
%         wdw_nA        window width for searching the maximum after  nD [seconds] (default = 200e-03)
%         fsi           sampling frequency for interpolation. Fine search of the peaks [Hertz]
%         diffPPG     derivative of the PPG signal for searching nD
%
%
% Outputs all (detected at fsi) [seconds]
%         nA            Maximum of the PPG pulse
%         nB            Minimum of the PPG pulse
%         nM            Medium  of the PPG pulse
%         nD            Maximum of the first derivative of the PPG
%
%
% Created               by Jes�s L�zaro  <jlazarop@unizar.es> in 2014
% Fixed and Optimized   by Pablo Arma�ac <parmanac@unizar.es> in 2019
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
if ~isfield(Setup,'diffSignal'),Setup.diffSignal = diff(fillmissing(signal(:),'linear'));	end

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

t           =	0:1/fs:  (length(signal)-1)/fs;
t_i         =	0:1/fsi:((length(signal)*(fsi/fs)-1)/fsi);
signal_i	=   interp1( t , signal , t_i , 'spline' );


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