
% --------------------------------------------------------------------
% --========== https://github.com/up-stairs/vhdl_ip_cores ==========--
% --------------------------------------------------------------------

clear all; clc;

hpulse = [30, 0, -115, 0, 309, 0, -693, 0, 1426, 0, -3038, 0, 10268, 16369, 10268, 0, -3038, 0, 1426, 0, -693, 0, 309, 0, -115, 0, 30];

for k = 1:length(hpulse)
  fprintf('%6d, ', hpulse(k))
  if mod(k, 4) == 0
    fprintf('\n')
  endif
endfor

sps = 2;
ntaps = length(hpulse);
st = [-floor(ntaps/2):floor(ntaps/2)] / sps;  % symbol time


figure(1);
plot(st, hpulse, 'x-');
xlabel("Time (symbols)");
ylabel("Amplitude");
title("RRC Filter Taps");
grid on;

figure(2)
freqz(hpulse)
