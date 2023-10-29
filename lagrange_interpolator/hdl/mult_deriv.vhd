
--------------------------------------------------------------------
--========== https://github.com/up-stairs/vhdl_ip_cores ==========--
--------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mult_deriv is
  generic (
    C_COE                   : natural range 1024 downto 0;
    C_DATAW                 : natural range 18 downto 4
  );
  port(
    clock                   : in std_logic;
    reset                   : in std_logic;
    sample_en               : in std_logic;
    clock_en                : in std_logic;

    data_in                 : in std_logic_vector(C_DATAW-1 downto 0);
    data_out                : out std_logic_vector(C_DATAW-1 downto 0)
  );
end mult_deriv;

architecture rtl of mult_deriv is
  
  signal data_in_mult   : signed(C_DATAW+11 downto 0);
  signal data_mult_pre  : signed(C_DATAW+11 downto 0);
  signal data_out_sig   : signed(C_DATAW+11 downto 0);

begin

  data_in_mult    <= to_signed(C_COE, 12) * signed(data_in);

  process(clock, reset)
  begin
    if reset = '1' then
      data_mult_pre   <= (others => '0');
    elsif rising_edge(clock) then
      if (sample_en = '1') then
        data_mult_pre   <= data_in_mult;
      end if;
    end if;
  end process;
  
  process(clock, reset)
  begin
    if reset = '1' then
      data_out_sig  <= (others => '0');
    elsif rising_edge(clock) then
      if (sample_en = '1') then
        data_out_sig  <= data_in_mult - data_mult_pre;
      end if;
    end if;
  end process;
  
  -- data_out_sig  <= data_in_mult - data_mult_pre;
  data_out <= std_logic_vector(data_out_sig(C_DATAW+9 downto 10));

end rtl;
