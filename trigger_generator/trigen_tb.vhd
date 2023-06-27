library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity trigen_tb is
end trigen_tb;

architecture tb_arch of trigen_tb is

  constant C_TIMER_W   : natural := 8;  -- Width of the timer period

  signal clock         : std_logic := '0';
  signal reset         : std_logic := '1';
  signal clock_en      : std_logic := '1';
  signal trig_in       : std_logic := '0';
  signal trig_period   : std_logic_vector(C_TIMER_W-1 downto 0) := "01010101";
  signal trig_ack      : std_logic := '1';
  signal trig_out      : std_logic;

begin

  -- Instantiate the trigen module
  dut : entity work.trigen
    generic map (
      C_TIMER_W => C_TIMER_W
    )
    port map (
      clock       => clock,
      reset       => reset,
      clock_en    => clock_en,
      trig_in     => trig_in,
      trig_period => trig_period,
      trig_ack    => trig_ack,
      trig_out    => trig_out
    );

  -- Clock generation process
  clk_process : process
  begin
    while now < 100000 ns loop
      clock <= '0';
      wait for 5 ns;
      clock <= '1';
      clock_en <= not clock_en;
      wait for 5 ns;
    end loop;
    wait;
  end process;

  -- Stimulus process
  stim_process : process
  begin
    reset <= '1';  -- Assert reset
    wait for 10 ns;
    reset <= '0';  -- De-assert reset
    wait for 10 ns;
    wait for 10 ns;
    trig_in <= '1';  -- Set trig_in high
    wait for 10 ns;
    trig_in <= '0';  -- Set trig_in low
    wait;
  end process;

end tb_arch;
