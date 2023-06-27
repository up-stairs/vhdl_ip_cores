library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity pepugen is
  generic (
    C_TIMER_W               : natural
  );
  port(
    clock                   : in std_logic;
    reset                   : in std_logic;
    clock_en                : in std_logic;

    pulse_period            : in std_logic_vector(C_TIMER_W-1 downto 0);
    
    pulse_signal            : out std_logic
  );
end pepugen;

architecture rtl of pepugen is

  signal timer_cntr                 : unsigned(pulse_period'range);

begin

  process(clock, reset)
  begin
    if reset = '1' then
      -- Reset condition: Set pulse_signal to '0' and reset timer_cntr
      pulse_signal  <= '0';
      timer_cntr    <= (others => '0');
    elsif rising_edge(clock) then
      -- On rising edge of clock
      pulse_signal  <= '0';
      if (clock_en = '1') then
        -- When clock_en is '1'
        if (timer_cntr >= unsigned(pulse_period)-1) then
          -- If timer_cntr is equal to or greater than pulse_period-1
          pulse_signal  <= '1';
          timer_cntr    <= (others => '0');
        else
          -- Increment timer_cntr
          timer_cntr    <= timer_cntr + 1;
        end if;
      end if;
    end if;
  end process;

end rtl;
