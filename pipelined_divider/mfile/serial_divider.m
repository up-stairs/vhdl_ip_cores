function [quotent, remainder] = serial_divider(dividend, divisor, DD, DR, FR)

quotent = 0;
quotent_incr = 2^(DD+FR-1);

divisor = divisor * quotent_incr;

dividend = dividend * 2^FR;

while (quotent_incr >= 1)
  if (divisor <= dividend)
##    dividend = dividend - mod(divisor, 2^(DD+FR));
    dividend = dividend - divisor;
    quotent = quotent + quotent_incr; % can be XORed
  end

  divisor = floor(divisor/2);
  quotent_incr = floor(quotent_incr/2);
end

remainder = mod(dividend, 2^(DR+FR));
