function [Signal] = genC37Signal( ...
    t, ...
    FSamp, ...
    signalparams, ...
    EndTime ...
    )

% This is the .m file for the C37.118.1 power system signal for the
% PMUImpairment module.  SigalParams description can be found in Event Parameters.docx.

% For this signal, there may be multiple phases that can each be independent of the
% others (giving the ability to create unbalanced signals).  In the
% signalparms array, there is one column of parameters for each of
% the phases.

% Signal params.  Note that the labeling convention comes mostly from the
% standard
    Xm = signalparams(1,:)*sqrt(2);     % phase amplitude (given by the user in RMS
    Fin = signalparams(2,:);    % frequency (must be the same for all 6 channels or an error will be thrown
    Ps = signalparams(3,:);     % phase 
    Fh = signalparams(4,:);     % Frequency of the interfering signal
    Ph = signalparams(5,:);     % Phase of the interfering signal
    Kh = signalparams(6,:);     % index of the interfering signal    
    Fa = signalparams(7,:);     % phase (angle) moduation frequency
    Ka = signalparams(8,:);     % phase (angle) moduation index
    Fx = signalparams(9,:);     % amplitude moduation frequency
    Kx = signalparams(10,:);     % amplitude moduation index
    Rf = signalparams(11,:);     % ROCOF
    KaS = signalparams(12,:);   % phase (angle) step index
    KxS = signalparams(13,:);   % magnitude step index
    
                                    
% Phase in radians
Ph = Ps*pi/180;
    
% calculate the angular frequencies
Wf = 2*pi*Fin;  % fundamental frequency
Wa = 2*pi*Fa;   % phase (angle) modulation frequency
Wx = 2*pi*Fx;   % amplitude modulation frequency
Wh = 2*pi*Fh;

% Amplitude, AM and magnitude step
Ain = zeros(length(Xm),length(t));
for i = 1:length(Xm)
    Ain(i,:) = Xm(i) *(1+Kx(i)*cos((Wx(i)*t)));
    % Amplitude Step: applied after time passes 0
    Ain(i,t >= 0) = Ain(i,t >= 0) * (1 + KxS(i));
end

% Phase
Theta = zeros(length(Ps),length(t));
for i = 1:length(Ps)
    Theta(i,:) = (Wf(i)*t) ...                         % Fundamental
                 + Ph(i) ...               % phase shift
                 - ( ...                 
                    (Ka(i)*cos((Wa(i)*t)-pi)) ...     % Phase modulation
                  );
end

% Phase Step
for i = 1:length(KaS)
    Theta(i,t >= 0) = Theta(i,t >= 0) + (KaS(i) * pi/180);
end

% frequency ramp
for i = 1:length(Rf)
    Theta(i,t>=0 & t<EndTime) = Theta(i,t>=0 & t<EndTime) + (Rf(i) * 2 *pi * t(t>=0 & t<EndTime).^2);
end

% last frequency
for i = 1:length(Rf)
    Theta(i,t>=EndTime) = Theta(i,t>=EndTime) + (2*pi*Rf(i)*EndTime*t(t>=EndTime));
end

% Complex signals
cSignal = (Ain.*exp(-1i.*Theta));

% Add a single harmonic
if (Fh > FSamp/2)
    error('Interfering signal frequency is above PMU Nyquist frequency.  Can not generate');
end % if

for i = 1:length(Wh)
    ThetaH(i,:) = (Wh(i)*t) + Ph(i)*(pi/180);
    cSignal(i,:) = cSignal(i,:) + ((Kh(i) * (sqrt(2)*Xm(i))) * (cos(ThetaH(i,:)) + 1i*sin(ThetaH(i,:))));
end

Signal = real(cSignal);

end  %function

