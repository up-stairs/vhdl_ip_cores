
--------------------------------------------------------------------
--========== https://github.com/up-stairs/vhdl_ip_cores ==========--
--------------------------------------------------------------------

-- Adds arbitrary delay

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity arb_delay is
  generic (
    C_DELAY                 : natural;
    C_DATAW                 : natural
  );
  port(
    clock                   : in std_logic;
    reset                   : in std_logic;
    clock_en                : in std_logic;

    data_in                 : in std_logic_vector(C_DATAW-1 downto 0);
    data_out                : out std_logic_vector(C_DATAW-1 downto 0)
  );
end arb_delay;

architecture rtl of arb_delay is

  type t_DELAY_TYPE is array (integer range <>) of std_logic_vector(C_DATAW-1 downto 0);
  
  signal delay_line   : t_DELAY_TYPE(0 to C_DELAY-1);

begin

  process(clock, reset)
  begin
    if reset = '1' then
      delay_line    <= (others => (others => '0'));
    elsif rising_edge(clock) then
      if (clock_en = '1') then
        delay_line(0)   <= data_in;
        
        if (C_DELAY > 1) then
          for i in 1 to C_DELAY-1 loop
            delay_line(i)   <= delay_line(i-1);
          end loop;
        end if;
      end if;
    end if;
  end process;
  
  data_out <= delay_line(C_DELAY-1);

end rtl;
