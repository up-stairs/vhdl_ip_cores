
--------------------------------------------------------------------
--========== https://github.com/up-stairs/vhdl_ip_cores ==========--
--------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity complex_abs_approx_tb is
end entity complex_abs_approx_tb;

architecture tb_arch of complex_abs_approx_tb is
  -- Constants
  constant C_DATA_WIDTH    : natural := 16;
  constant C_USER_WIDTH    : natural := 16;
  
  -- Signals
  signal clock         : std_logic := '0';
  signal reset         : std_logic := '0';
  signal clock_en      : std_logic := '1';  -- Enable clock
  signal in_valid      : std_logic := '0';
  signal in_user       : std_logic_vector(C_USER_WIDTH-1 downto 0);
  signal in_real       : signed(C_DATA_WIDTH-1 downto 0);
  signal in_imag       : signed(C_DATA_WIDTH-1 downto 0);
  signal out_valid     : std_logic;
  signal out_user      : std_logic_vector(C_USER_WIDTH-1 downto 0);
  signal out_abs       : unsigned(C_DATA_WIDTH downto 0);
  
  type t_integer_vector is array (integer range <>) of integer;
  shared variable DEFAULT_SEEDs       : t_integer_vector(0 to 1) := (26513879, 20136548);
  
  ------------------------------------------------------------------------------
  function randi(
    min                                     : integer := 0;
    max                                     : integer := 1) return integer is
  
    variable pow                            : real := real(max - min);
    variable rand_num                       : real := 0.0;
  begin
    UNIFORM(
      DEFAULT_SEEDs(0),
      DEFAULT_SEEDs(1),
      rand_num);
      
    return integer(round((rand_num*pow)+real(min)));
  end function randi;
  ------------------------------------------------------------------------------
  
  -- Clock period constants
  constant clk_period : time := 10 ns;
  
begin
  -- Instantiate the DUT (Device Under Test)
  DUT: entity work.complex_abs_approx
    generic map (
      C_DATA_WIDTH => C_DATA_WIDTH,
      C_USER_WIDTH => C_USER_WIDTH
    )
    port map (
      clock      => clock,
      reset      => reset,
      clock_en   => clock_en,
      in_valid   => in_valid,
      in_user    => in_user,
      in_real    => in_real,
      in_imag    => in_imag,
      out_valid  => out_valid,
      out_user   => out_user,
      out_abs    => out_abs
    );

  -- Clock process
  clk_process : process
  begin
    while now < 1000 ns loop
      clock <= '0';
      wait for clk_period / 2;
      clock <= '1';
      wait for clk_period / 2;
    end loop;
    wait;
  end process clk_process;

  -- Stimulus process
  stim_process : process
  begin
    -- Initialize inputs
    reset <= '1';
    in_valid <= '0';
    in_user <= (others => '0');
    in_real <= to_signed(10, C_DATA_WIDTH);
    in_imag <= to_signed(5, C_DATA_WIDTH);
    
    wait for clk_period;
    reset <= '0';
    
    while(true) loop
      wait for clk_period*5;
      in_valid <= '1';
      in_real <= to_signed(randi(-32000, 32000), C_DATA_WIDTH);
      in_imag <= to_signed(randi(-32000, 32000), C_DATA_WIDTH);
      wait for clk_period;
      in_valid <= '0';
    end loop;
    -- -- Apply input values and check output values
    -- in_valid <= '1';
    -- wait for clk_period;
    -- assert out_valid = '1'
      -- report "Error: Invalid output at t = " & time'image(now);
    -- assert out_user = in_user
      -- report "Error: Invalid out_user at t = " & time'image(now);
    -- assert to_integer(out_abs) = 11
      -- report "Error: Invalid out_abs at t = " & time'image(now);
      
    -- -- Update inputs and check outputs again
    -- in_valid <= '0';
    -- in_real <= to_signed(8, C_DATA_WIDTH);
    -- in_imag <= to_signed(12, C_DATA_WIDTH);
    -- wait for clk_period;
    -- assert out_valid = '1'
      -- report "Error: Invalid output at t = " & time'image(now);
    -- assert out_user = in_user
      -- report "Error: Invalid out_user at t = " & time'image(now);
    -- assert to_integer(out_abs) = 19
      -- report "Error: Invalid out_abs at t = " & time'image(now);

    wait;
  end process;
  
end architecture;