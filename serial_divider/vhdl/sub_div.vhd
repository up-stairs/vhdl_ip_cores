library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sub_div is
  generic (
    UW        : natural := 5; -- user width
    DD        : natural := 7;  -- Replace with the actual dividend bit width
    DR        : natural := 7;  -- Replace with the actual dividend bit width
    FR        : natural := 0;  -- Replace with the actual fractional part length
    DIV_STEP  : natural := 0  --
  );
  port (
    clock         : in std_logic;                 -- Clock input
    reset         : in std_logic;                -- Reset input
    clken         : in std_logic;                -- Reset input

    valid_in      : in std_logic;
    user_in       : in std_logic_vector(UW-1 downto 0);   --
    dividend_in   : in std_logic_vector(DD+FR-1 downto 0);   -- Input dividend
    divisor_in    : in std_logic_vector(DR+DD+FR-1 downto 0);    -- Input divisor
    quotent_in    : in std_logic_vector(DD+FR-1 downto 0);    -- Input quotient

    valid_out     : out std_logic;
    user_out      : out std_logic_vector(UW-1 downto 0);   --
    dividend_out  : out std_logic_vector(DD+FR-1 downto 0);   -- Output dividend
    divisor_out   : out std_logic_vector(DR+DD+FR-1 downto 0);  -- Output divisor
    quotent_out   : out std_logic_vector(DD+FR-1 downto 0)  -- Output quotient
  );
end entity sub_div;

architecture rtl of sub_div is

  signal temp_valid     : std_logic;
  signal temp_dividend  : unsigned(dividend_in'range);
  signal temp_divisor   : unsigned(divisor_in'range);
  signal temp_quotent   : std_logic_vector(quotent_in'range);
  signal temp_user      : std_logic_vector(user_in'range);

begin

  process (clock, reset)
  begin
    if (reset = '1') then
      -- Reset signals to initial values
      temp_dividend <= (others => '0');
      temp_divisor  <= (others => '0');
      temp_quotent  <= (others => '0');
      temp_user     <= (others => '0');
      temp_valid    <= '0';
    elsif (rising_edge(clock)) then
      if (clken = '1') then

        temp_valid      <= valid_in;

        if (valid_in = '1') then
          if (unsigned(divisor_in) <= unsigned(dividend_in)) then
            -- Perform division operation
            temp_dividend       <= unsigned(dividend_in) - unsigned(divisor_in(dividend_in'range));
            temp_quotent        <= quotent_in;
            temp_quotent(DIV_STEP)  <= '1';
          else
            temp_dividend       <= unsigned(dividend_in);
            temp_quotent        <= quotent_in;
          end if;

          temp_user       <= user_in;
          temp_divisor    <= shift_left(shift_right(unsigned(divisor_in), 1), 1);
        end if;
      end if;
    end if;
  end process;

  -- Assign output ports
  dividend_out  <= std_logic_vector(temp_dividend);
  divisor_out   <= std_logic_vector(temp_divisor);
  quotent_out   <= std_logic_vector(temp_quotent);
  user_out      <= temp_user;
  valid_out     <= temp_valid;

end architecture rtl;