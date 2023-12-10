
--------------------------------------------------------------------
--========== https://github.com/up-stairs/vhdl_ip_cores ==========--
--------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

library work;
use work.test_pkg.all;

entity tb_pipelined_divider is
end tb_pipelined_divider;

architecture testbench of tb_pipelined_divider is
  constant CPERIOD            : time := 10 ns;

  constant DD                 : natural := 17;  -- Replace with the actual dividend bit width
  constant DR                 : natural := 17;  -- Replace with the actual dividend bit width
  constant FR                 : natural := 4;  -- Replace with the actual fractional part length
  constant UW                 : natural := DD+FR+DR+FR; -- user width

  signal clock                : std_logic;
  signal reset                : std_logic;
  signal clken                : std_logic := '1';
  signal valid_in             : std_logic;
  signal user_in              : std_logic_vector(UW-1 downto 0);   --
  signal dividend_in          : std_logic_vector(DD-1 downto 0);   -- Input dividend
  signal divisor_in           : std_logic_vector(DR-1 downto 0);    -- Input divisor

  signal valid_out            : std_logic;
  signal user_out             : std_logic_vector(UW-1 downto 0);   --
  signal quotent_out          : std_logic_vector(DD+FR-1 downto 0);  -- Output quotient
  signal remainder_out        : std_logic_vector(DR+FR-1 downto 0);  -- Output remainder

  signal tb_quotent           : std_logic_vector(DD+FR-1 downto 0);  -- Output quotient
  signal tb_remainder         : std_logic_vector(DR+FR-1 downto 0);  -- Output remainder
begin

  process
  begin
    wait for CPERIOD/2;
    clock   <= '1';
    wait for CPERIOD/2;
    clock   <= '0';
  end process;

  process
  begin
    reset   <= '1';
    wait for CPERIOD*100;
    reset   <= '0';
    wait;
  end process;


  process
    variable dividend_v   : integer;
    variable divisor_v    : integer;
    variable quotent_v    : integer;
    variable remainder_v  : integer;
  begin
    valid_in    <= '0';
    wait until falling_edge(reset);

    while (true) loop

      wait until falling_edge(clock);

      dividend_v    := randi(0, 2**dividend_in'length-1);
      divisor_v     := randi(1, 2**dividend_in'length-1);

      quotent_v     := (dividend_v*2**FR)/divisor_v;
      remainder_v   := dividend_v*2**FR - quotent_v*divisor_v;

      dividend_in   <= std_logic_vector(to_unsigned(dividend_v, dividend_in'length));
      divisor_in    <= std_logic_vector(to_unsigned(divisor_v, divisor_in'length));
      user_in       <= std_logic_vector(to_unsigned(quotent_v, DD+FR) & to_unsigned(remainder_v, DR+FR));


      valid_in    <= '1';
      wait for CPERIOD;
      valid_in    <= '0';

      wait for CPERIOD*randi(0, 100);
    end loop;

    wait;
  end process;


  uut : entity work.pipelined_divider
  generic map(
    UW            => UW,
    DD            => DD,
    DR            => DR,
    FR            => FR
  )
  port map(
    clock         => clock,
    reset         => reset,
    clken         => clken,

    valid_in      => valid_in,
    user_in       => user_in,
    dividend_in   => dividend_in,
    divisor_in    => divisor_in,

    valid_out     => valid_out,
    user_out      => user_out,
    remainder_out => remainder_out,
    quotent_out   => quotent_out
  );

  tb_quotent    <= user_out(user_in'left downto tb_remainder'left+1);
  tb_remainder  <= user_out(tb_remainder'range);

end testbench;