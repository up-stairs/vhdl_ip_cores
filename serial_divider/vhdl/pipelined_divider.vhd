
--------------------------------------------------------------------
--========== https://github.com/up-stairs/vhdl_ip_cores ==========--
--------------------------------------------------------------------

-- Description:
--
-- Operation:
--
-- VHDL Implementation:

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity pipelined_divider is
  generic (
    UW          : natural := 5; -- user width
    DD          : natural := 17;  -- Replace with the actual dividend bit width
    DR          : natural := 17;  -- Replace with the actual dividend bit width
    FR          : natural := 4  -- Replace with the actual fractional part length
  );
  port (
    clock         : in std_logic;                 -- Clock input
    reset         : in std_logic;                -- Reset input
    clken         : in std_logic;                -- Reset input

    valid_in      : in std_logic;
    user_in       : in std_logic_vector(UW-1 downto 0);   --
    dividend_in   : in std_logic_vector(DD-1 downto 0);   -- Input dividend
    divisor_in    : in std_logic_vector(DR-1 downto 0);    -- Input divisor

    valid_out     : out std_logic;
    user_out      : out std_logic_vector(UW-1 downto 0);   --
    quotent_out   : out std_logic_vector(DD+FR-1 downto 0);  -- Output quotient
    remainder_out : out std_logic_vector(DR+FR-1 downto 0)  -- Output remainder
  );
end pipelined_divider;

architecture rtl of pipelined_divider is

  type t_USER_TYPE is array (integer range <>) of std_logic_vector(user_in'range);
  type t_DIVIDEND_TYPE is array (integer range <>) of std_logic_vector(DD+FR-1 downto 0);
  type t_DIVISOR_TYPE is array (integer range <>) of std_logic_vector(DR+DD+FR-1 downto 0);

  signal temp_valid     : std_logic_vector(DD+FR downto 0);
  signal temp_dividend  : t_DIVIDEND_TYPE(DD+FR downto 0);
  signal temp_divisor   : t_DIVISOR_TYPE(DD+FR downto 0);
  signal temp_quotent   : t_DIVIDEND_TYPE(DD+FR downto 0);
  signal temp_user      : t_USER_TYPE(DD+FR downto 0);

begin

  temp_valid(DD+FR)     <= valid_in;
  temp_user(DD+FR)      <= user_in;
  temp_dividend(DD+FR)  <= std_logic_vector(shift_left(resize(unsigned(dividend_in), DD+FR), FR));
  temp_divisor(DD+FR)   <= std_logic_vector(shift_left(resize(unsigned(divisor_in), DR+DD+FR), DD+FR-1));
  temp_quotent(DD+FR)   <= (others => '0');

  -- 
  g_sub_blocks : for DIV_STEP in DD+FR-1 downto 0 generate
  begin
    comp_sub_division : entity work.sub_div
    generic map(
      DIV_STEP  => DIV_STEP,
      UW        => UW,
      DD        => DD,
      DR        => DR,
      FR        => FR
    )
    port map(
      clock         => clock,
      reset         => reset,
      clken         => clken,

      valid_in      => temp_valid(DIV_STEP+1),
      user_in       => temp_user(DIV_STEP+1),
      dividend_in   => temp_dividend(DIV_STEP+1),
      divisor_in    => temp_divisor(DIV_STEP+1),
      quotent_in    => temp_quotent(DIV_STEP+1),
      
      valid_out     => temp_valid(DIV_STEP),
      user_out      => temp_user(DIV_STEP),
      dividend_out  => temp_dividend(DIV_STEP),
      divisor_out   => temp_divisor(DIV_STEP),
      quotent_out   => temp_quotent(DIV_STEP)
    );
  end generate;

  valid_out       <= temp_valid(0);
  user_out        <= temp_user(0);
  remainder_out   <= temp_dividend(0)(remainder_out'range);
  quotent_out     <= temp_quotent(0);

end rtl;
