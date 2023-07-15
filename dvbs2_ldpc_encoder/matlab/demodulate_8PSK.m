%10-06-2009
function llr_out = demodulate_8PSK(data)


constellation = [ pi/4 
                  0 
                  pi 
                  pi+pi/4 
                  pi/2
                  7*pi/4
                  3*pi/4
                  3*pi/2
                  ];

constellation=exp(i*constellation);

llr_out = zeros(1,length(data)*3);              
for k=1:length(data)              
llr_bit0 = -min([abs(data(k) - constellation(1)) , abs(data(k) - constellation(5)),...
            abs(data(k) - constellation(7)) , abs(data(k) - constellation(3))]) + ...
            min([abs(data(k) - constellation(2)) , abs(data(k) - constellation(4)),...
            abs(data(k) - constellation(6)) , abs(data(k) - constellation(8))]);

llr_bit1 = -min([abs(data(k) - constellation(1)) , abs(data(k) - constellation(2)),...
            abs(data(k) - constellation(5)) , abs(data(k) - constellation(6))]) + ...
            min([abs(data(k) - constellation(3)) , abs(data(k) - constellation(4)),...
            abs(data(k) - constellation(7)) , abs(data(k) - constellation(8))]);

llr_bit2 = -min([abs(data(k) - constellation(1)) , abs(data(k) - constellation(2)),...
            abs(data(k) - constellation(3)) , abs(data(k) - constellation(4))]) + ...
            min([abs(data(k) - constellation(5)) , abs(data(k) - constellation(6)),...
            abs(data(k) - constellation(7)) , abs(data(k) - constellation(8))]) ;    
        
llr_out(3*(k-1)+1:3*k) = [llr_bit0 llr_bit1 llr_bit2 ];
end
llr_out';    

        

              