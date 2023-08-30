clear;
close all;
clc;

L = 100;
M = 4;
r = 0.55;

x = qammod(randi([0 3],1, L), M);

x = randi([0 10], 1, L);
x = sin(2*pi*(1:L)/L);
x = 0;
for j = 1:L/119:L/4
##  x = x + randi([-10 10])/10*sin(j*2*pi*(1:L)/L);
  x = x + 1*sin(j*2*pi*(1:L)/L);
endfor

x = sin(5*2*pi*(1:L)/L);

##x = 1:L;

y1 = spline(1:L, x, 2:r:L);
y2 = lagrange_newton_v2(x, r);
y3 = lagrange_newton_v3(x, r, 5);

figure
plot(2:r:L, y1, 'b');
hold
##plot(0:r:L-2, y2,'r');
plot(0:r:L-2, y3,'g');

##figure
##[Pxx,f] = pwelch(x);
##plot(f*r, 20*log10(Pxx), 'c')
##hold
##
##[Pxx,f] = pwelch(y1);
##plot(f, 20*log10(Pxx), 'b')
##
##[Pxx,f] = pwelch(y2);
##plot(f, 20*log10(Pxx), 'r')
##
##[Pxx,f] = pwelch(y3);
##plot(f, 20*log10(Pxx), 'g')
