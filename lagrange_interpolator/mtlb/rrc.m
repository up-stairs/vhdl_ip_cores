clear all; clc;

##Ts = 8.1380e-06;           %sampling rate
##Nos = 24;                  %upsampling factor
##alpha = 0.25;               %Rollback
##
##t1 = [-6*Ts:Ts/Nos:-Ts/Nos];
##t2 = [Ts/Nos:Ts/Nos:6*Ts];
##
##
##r1 = (4*alpha/(pi*sqrt(Ts)))*(cos((1+alpha)*pi*t1/Ts)+(Ts./(4*alpha*t1)).*sin((1-alpha)*pi*t1/Ts))./(1-(4*alpha*t1/Ts).^2);
##r2 = (4*alpha/(pi*sqrt(Ts)))*(cos((1+alpha)*pi*t2/Ts)+(Ts./(4*alpha*t2)).*sin((1-alpha)*pi*t2/Ts))./(1-(4*alpha*t2/Ts).^2);
##
##r = [r1 (4*alpha/(pi*sqrt(Ts))+(1-alpha)/sqrt(Ts)) r2];

Fs = 20000;  % sample rate
Rs = 10000;   % symbol rate
sps = Fs/Rs; % samples per symbol

%
% Root raised cosine pulse filter
% https://www.michael-joost.de/rrcfilter.pdf
%
r = 0.25; % bandwidth factor

ntaps = 16 * sps + 1;  % filter is 8 symbols in length
st = [-floor(ntaps/2):floor(ntaps/2)] / sps;  % symbol time
hpulse = 1/sqrt(sps) * (sin ((1-r)*pi*st) + 4*r*st.*cos((1+r)*pi*st)) ./ (pi*st.*(1-(4*r*st).^2));

% fix the removable singularities
hpulse(ceil(ntaps/2)) = 1/sqrt(sps) * (1 - r + 4*r/pi); % t = 0 singulatiry
sing_idx = find(abs(1-(4*r*st).^2) < 0.000001);
for k = [1:length(sing_idx)]
    hpulse(sing_idx) = 1/sqrt(sps) * r/sqrt(2) * ((1+2/pi)*sin(pi/(4*r))+(1-2/pi)*cos(pi/(4*r)));
    printf('Fixed the other removable singularities\n');
end

% normalize to 0 dB gain
hpulse = round(hpulse / sum(hpulse) * 30000)

for k = 1:length(hpulse)
  fprintf('%6d, ', hpulse(k))
  if mod(k, 4) == 0
    fprintf('\n')
  endif
endfor


figure(1);
plot(st, hpulse, 'x-');
xlabel("Time (symbols)");
ylabel("Amplitude");
title("RRC Filter Taps");
grid on;

figure(2)
freqz(hpulse)
