function [quotent, dividend, divisor] = ser_div_sub(dividend, divisor, quotent, div_step)

  if (divisor <= dividend)
##    dividend = dividend - mod(divisor, 2^(DD+FR));
    dividend = dividend - divisor;
    quotent = quotent + 2^div_step; % can be XORed
  end

  divisor = floor(divisor/2);
