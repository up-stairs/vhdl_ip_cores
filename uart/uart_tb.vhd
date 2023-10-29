
--------------------------------------------------------------------
--========== https://github.com/up-stairs/vhdl_ip_cores ==========--
--------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity uart_tb is
end uart_tb;

architecture tb_arch of uart_tb is

  ------------------------------------------------------------------------------
  type t_integer_vector is array (integer range <>) of integer;
  shared variable DEFAULT_SEEDs       : t_integer_vector(0 to 1) := (26513879, 20136548);
  
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
  
  constant C_SYMBOL_PERIOD   : std_logic_vector(7 downto 0) := x"08";  -- Width of the timer period
  constant C_SERIAL_DATA_W   : natural := 31;  -- Width of the timer period

  signal clock         : std_logic := '0';
  signal clock_recv    : std_logic := '0';
  signal reset         : std_logic := '1';
  signal clock_en      : std_logic := '1';
  signal s_axi_data_tvalid    : std_logic;
  signal s_axi_data_tdata     : std_logic_vector(C_SERIAL_DATA_W-1 downto 0);
  signal m_axi_data_tvalid    : std_logic;
  signal m_axi_data_tdata     : std_logic_vector(C_SERIAL_DATA_W-1 downto 0);
  signal serial_data_pin      : std_logic;
  signal err_parity           : std_logic;

  constant CPERIOD            : time := 10 ns;
begin

  -- simulasyon icin clock ve reset uretimi
  process
  begin
    wait for CPERIOD/2;
    clock   <= '1';
    wait for CPERIOD/2;
    clock   <= '0';
  end process;
  
  process
  begin
    wait for CPERIOD/2;
    wait for randi(1, 100) * 1ps;
    clock_recv   <= '1';
    wait for CPERIOD/2;
    wait for randi(1, 100) * 1ps;
    clock_recv   <= '0';
  end process;
  
  process
  begin
    reset   <= '1';
    wait for CPERIOD*100;
    reset   <= '0';
    wait;
  end process;
  
  
  process
    variable modcod_v   : integer;
  begin
    s_axi_data_tvalid   <= '0';
    wait until falling_edge(reset);
    
    while (true) loop
      s_axi_data_tvalid   <= '0';
      
      modcod_v := randi(0, 2**30-1);
      s_axi_data_tdata    <= std_logic_vector(to_unsigned(modcod_v, C_SERIAL_DATA_W));
      
      wait for CPERIOD;
      s_axi_data_tvalid   <= '1';
      wait for CPERIOD;
      s_axi_data_tvalid   <= '0';
      
      wait until rising_edge(m_axi_data_tvalid);
      wait for CPERIOD*randi(0, 100);
    end loop;
    
    wait;
  end process;
  
  -- Instantiate the trigen module
  dut_xmit : entity work.uart_xmit
    generic map (
      C_SYMBOL_PERIOD => C_SYMBOL_PERIOD,
      C_SERIAL_DATA_W => C_SERIAL_DATA_W
    )
    port map (
      clock               => clock,
      reset               => reset,
      s_axi_data_tvalid   => s_axi_data_tvalid,
      s_axi_data_tdata    => s_axi_data_tdata,
      serial_data_xmit    => serial_data_pin
    );
    
  dut_recv : entity work.uart_recv
    generic map (
      C_SYMBOL_PERIOD => C_SYMBOL_PERIOD,
      C_SERIAL_DATA_W => C_SERIAL_DATA_W
    )
    port map (
      clock               => clock_recv,
      reset               => reset,
      m_axi_data_tvalid   => m_axi_data_tvalid,
      m_axi_data_tdata    => m_axi_data_tdata,
      serial_data_recv    => serial_data_pin,
      err_parity          => err_parity
    );


end tb_arch;
