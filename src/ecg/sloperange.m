function [edr] = sloperange(ecg, tk, fs, plotFlag )
    % EDR using the slope range
    
    % INPUTS
    % ecg : single-lead ecg signal
    % tk: the beat occurence time series for R-wave (in samples)
    % fs : sampling frequency
    % plotFlag : 1 enables the plots inside the function
    % 
    % OUTPUTS
    % EDR
    %%-----------------------------------------------------------------------%%

    
    if nargin < 4
        plotFlag = 0;
    end
    
    ecg = ecg(:);

    % Maximum and minimum values in 1st derivative
    %[b, a] = butter(4, [0.05, 45]*2/fs, 'bandpass');
    %ecg = filtfilt(b, a, ecg);
    
    % Get the position in seconds of all good R-peaks
    nk = round(tk*fs)+1;     
    
    % Number of good beats
    I = length(nk);
    
    % The duration of the intervals around R-wave (for defining slopes)
    W1 = round(fs*0.015); 
    W2 = round(fs*0.05); 
    
    % Fixed intervals for upslope and downslope   
    iUp   = -W2+1:W1; 
    iDown = -W1:W2-1;
    L = length(iUp);
    
    % Define the indices of the intervals for upslope and downslope relative to R-wave   
    qrsup   = repmat(nk(:).',[L,1])+repmat(iUp(:),[1,I]);
    qrsdown = repmat(nk(:).',[L,1])+repmat(iDown(:),[1,I]);
    
    % Calculate the first derivative of the ECG signal
    decg = diff(ecg); 
    decg = [decg(1); decg];
    
    % Get the values around the maximum and minimum slope
    [smax,i_smax]  = max(decg(qrsup));   
    [smin,i_smin]  = min(decg(qrsdown)); 
    
    % Compute the EDR, for every tk
    edr = smax(:) - smin(:);

    if plotFlag

        %make a continuous signal for improved plotting
        decgup   = nan(size(ecg));
        decgdown = nan(size(ecg));
        decgup(qrsup)     = decg(qrsup);
        decgdown(qrsdown) = decg(qrsdown);

        figure;
        t = (0:length(ecg)-1)/fs;
        ax(1) = subplot(311);    
        plot(t,ecg); hold on;
        plot(t(nk),ecg(nk),'o'); 
        axis tight; ylabel('ECG') 
        title('Beat detection')
        ax(2) = subplot(312);
        plot(t, decg); hold on;
        plot(t, decgup,':','linewidth',1.5)
        plot(t, decgdown,'--','linewidth',1.5);
        %plot(t(i_smax+nk),decgup(i_smax+nk),'v');
        %plot(t(i_smin+nk),decgdown(i_smin+nk),'^');
        axis tight; ylabel('1st der ECG')
        title({'Intervals for upslope (black) and downslope (magenta)'})
        ax(3) = subplot(313);
        plot(tk, edr ); axis tight; title('Slope range')
        xlabel('time (s)')
        linkaxes(ax,'x');
        slider;

    end
    
    end