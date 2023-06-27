-- Overall, the code implements a timer-based trigger generator that generates a trigger output based on the input trigger 
-- and a specified trigger period. The trigger output remains high during the ACK_ST state, 
-- indicating the acknowledgement of the trigger generation.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity trigen is
  generic (
    C_TIMER_W               : natural
  );
  port(
    clock                   : in std_logic;
    reset                   : in std_logic;
    clock_en                : in std_logic;

    trig_in                 : in std_logic;
    trig_period             : in std_logic_vector(C_TIMER_W-1 downto 0);
    
    trig_ack                : in std_logic;
    trig_out                : out std_logic
  );
end trigen;

architecture rtl of trigen is

  type t_STATE is (
    IDLE_ST,
    ACTIVE_ST,
    ACK_ST
  );
  
  signal timer_state                : t_STATE;                -- State of the timer state machine
  signal timer_cntr                 : unsigned(trig_period'range);  -- Counter for tracking the timer duration

begin

  process(clock, reset)
  begin
    if reset = '1' then
      -- Reset condition: Set trig_out to '0' and reset timer_cntr
      timer_cntr    <= (others => '0');
      timer_state   <= IDLE_ST;
    elsif rising_edge(clock) then
      -- On rising edge of clock
      case timer_state is
        when IDLE_ST =>
          timer_cntr    <= (others => '0');
          if (clock_en = '1' and trig_in = '1') then
            timer_state   <= ACTIVE_ST;  -- Transition to ACTIVE_ST if clock_en is enabled and trig_in is high
          end if;
        when ACTIVE_ST =>
          if (clock_en = '1') then
            if (timer_cntr >= unsigned(trig_period)-1) then
              timer_state   <= ACK_ST;    -- Transition to ACK_ST when the timer_cntr reaches the specified trig_period
            else
              -- Increment timer_cntr
              timer_cntr    <= timer_cntr + 1;
            end if;
          end if;
        when ACK_ST =>
          if (clock_en = '1' and trig_ack = '1') then
            timer_state   <= IDLE_ST;    -- Transition back to IDLE_ST if clock_en is enabled and trig_ack is high
          end if;
        when others =>
          null;
      end case;
    end if;
  end process;
  
  trig_out  <= '1' when timer_state = ACK_ST else '0';  -- Output trig_out is high when in ACK_ST, otherwise low

end rtl;
