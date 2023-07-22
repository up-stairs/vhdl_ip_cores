%10-06-2009
function modulated = modulate_8PSK(data)
%frame length
N =length(data);
%number of 8PSK symbols
M= N/3;

c = [4 2 1];
m = conv(data,c);
m = m(3:3:end)+1;

constellation = [ pi/4        % 000 
                  0           % 001 
                  pi          % 010  
                  pi+pi/4     % 011  
                  pi/2        % 100
                  7*pi/4      % 101
                  3*pi/4      % 110
                  3*pi/2      % 111
                  ];
              
modulated=exp(i*constellation(m));
              


