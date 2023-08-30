library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mult_add is
  generic (
    C_DATAW                 : natural range 18 downto 4;
    C_MUW                   : natural range 18 downto 4;
    C_MU_FRACW              : natural range 14 downto 0; -- fractional part of mu
    C_DATA_TO_ADD_SDELAY    : natural;
    C_DATA_TO_ADD_CDELAY    : natural
  );
  port(
    clock                   : in std_logic;
    reset                   : in std_logic;
    sample_en               : in std_logic;
    clock_en                : in std_logic;

    mu_in                   : in std_logic_vector(C_MUW-1 downto 0);
    data_to_mult_in         : in std_logic_vector(C_DATAW-1 downto 0);
    data_to_add_in          : in std_logic_vector(C_DATAW-1 downto 0);
    data_out                : out std_logic_vector(C_DATAW-1 downto 0)
  );
end mult_add;

architecture rtl of mult_add is
  
  signal mu_delayed           : std_logic_vector(C_MUW-1 downto 0);
  signal data_to_add_sdelayed : std_logic_vector(C_DATAW-1 downto 0);
  signal data_to_add_delayed  : std_logic_vector(C_DATAW-1 downto 0);
  signal data_x_mult          : signed(C_DATAW-1 downto 0);
  signal data_out_sig         : signed(C_DATAW-1 downto 0);

begin
  
  i_data_to_add_sdelay : entity work.arb_delay
  generic map (
    C_DELAY   => C_DATA_TO_ADD_SDELAY,
    C_DATAW   => C_DATAW
  )
  port map (
    clock                   => clock,           
    reset                   => reset,           
    clock_en                => sample_en,  
    data_in                 => data_to_add_in,           
    data_out                => data_to_add_sdelayed           
  );
  
  i_data_to_add_cdelay : entity work.arb_delay
  generic map (
    C_DELAY   => C_DATA_TO_ADD_CDELAY,
    C_DATAW   => C_DATAW
  )
  port map (
    clock                   => clock,           
    reset                   => reset,           
    clock_en                => clock_en,  
    data_in                 => data_to_add_sdelayed,           
    data_out                => data_to_add_delayed           
  );
  

  process(clock, reset)
    variable data_x_mult_v    : signed(C_MUW+C_DATAW-1 downto 0);
  begin
    if reset = '1' then
      data_x_mult   <= (others => '0');
    elsif rising_edge(clock) then
      if (clock_en = '1') then
        data_x_mult_v   := signed(data_to_mult_in) * signed(mu_in);
        data_x_mult     <= data_x_mult_v(C_DATAW+C_MU_FRACW-1 downto C_MU_FRACW);
      end if;
    end if;
  end process;
  
  process(clock, reset)
  begin
    if reset = '1' then
      data_out_sig  <= (others => '0');
    elsif rising_edge(clock) then
      if (clock_en = '1') then
        data_out_sig  <= data_x_mult + signed(data_to_add_delayed);
      end if;
    end if;
  end process;
  
  data_out <= std_logic_vector(data_out_sig);

end rtl;
