clear;
close all;
clc

DD = 15;
DR = 9;
FR = 0;

max_ref = 0;

for i = 1:10000
  dividend = randi([1 2^DD-1]);
  divisor = randi([1 2^DR-1]);

  # display([dividend divisor])
  ref_quotient  = floor (dividend/divisor*2^FR);
  ref_remainder = mod (dividend*2^FR, divisor);

  [quotent, remainder] = pipelined_divider(dividend, divisor, DD, DR, FR);

  if (ref_quotient ~= quotent) || (ref_remainder ~= remainder)
    display([ref_quotient quotent ref_remainder remainder])
    break;
  end
end
