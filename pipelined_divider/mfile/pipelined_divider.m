function [quotent, remainder] = pipelined_divider(dividend, divisor, DD, DR, FR)

quotent_temp   = 0;
divisor_temp   = divisor * 2^(DD+FR-1);
dividend_temp  = dividend * 2^FR;

for div_step = DD+FR-1:-1:0
  [quotent_temp, dividend_temp, divisor_temp] = ser_div_sub(dividend_temp, divisor_temp, quotent_temp, div_step);
end

quotent   = quotent_temp;
remainder = mod(dividend, 2^(DR+FR));
