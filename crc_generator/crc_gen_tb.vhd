library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

library work;
use work.test_pkg.all;

entity crc_gen_tb is
end crc_gen_tb;

architecture testbench of crc_gen_tb is


  constant c_CRC_POLY               : std_logic_vector := X"04C11DB7";
  constant c_CRC_INIT               : std_logic_vector := X"52325032";
  constant c_DATAW                  : natural := 8;
  constant c_USERW                  : natural := 8;
  
  constant c_TEST_DATA              : std_logic_vector := X"123056789abcde";

  signal clock                      : std_logic := '0';
  signal reset                      : std_logic := '0';
 
  signal s_axi_data_tvalid          : std_logic;
  signal s_axi_data_tlast           : std_logic;
  signal s_axi_data_tdata           : std_logic_vector(c_DATAW-1 downto 0);
  signal s_axi_data_tuser           : std_logic_vector(c_USERW-1 downto 0);
  signal m_axi_data_tvalid          : std_logic;
  signal m_axi_data_tdata           : std_logic_vector(c_CRC_POLY'range);
  signal m_axi_data_tuser           : std_logic_vector(c_USERW-1 downto 0);

  
  constant CPERIOD                  : time := 10 ns;
  
begin
  
  uut : entity work.crc_gen
  generic map(
    g_CRC_POLY             => c_CRC_POLY,
    g_CRC_INIT             => c_CRC_INIT,
    g_DATAW                => c_DATAW,
    g_USERW                => c_USERW
  )
  port map(
    clock                 => clock,
    reset                 => reset,

    s_axi_data_tvalid     => s_axi_data_tvalid,
    s_axi_data_tlast      => s_axi_data_tlast,
    s_axi_data_tdata      => s_axi_data_tdata,
    s_axi_data_tuser      => s_axi_data_tuser,
    
    m_axi_data_tvalid     => m_axi_data_tvalid,
    m_axi_data_tdata      => m_axi_data_tdata,
    m_axi_data_tuser      => m_axi_data_tuser
  );

  clock_process: process
  begin
    while now < 100000 ms loop
      clock <= not clock;
      wait for CPERIOD/2;
    end loop;
    wait;
  end process;

  stimulus_process: process
  begin
    reset               <= '1';
    s_axi_data_tvalid   <= '0';
    s_axi_data_tlast    <= '0';

    wait for CPERIOD * 20;

    reset               <= '0';
    
    
    while now < 1000 ms loop
      wait until falling_edge(clock);

      for i in 0 to c_TEST_DATA'length/c_DATAW-1 loop
        -- Example input data
        s_axi_data_tvalid <= '1';  -- Initiating the sending of the command
        s_axi_data_tdata  <= c_TEST_DATA(i*c_DATAW to i*c_DATAW+c_DATAW-1);
        if (i = c_TEST_DATA'length/c_DATAW-1) then
          s_axi_data_tlast <= '1';
        end if;
        wait for CPERIOD;
        
        
        if (randi(0, 1000) = 0) then
          reset   <= '1';
        else
          reset   <= '0';
        end if;
      
      end loop;

      s_axi_data_tvalid   <= '0';
      s_axi_data_tlast    <= '0';
    end loop;

    wait;
  end process;

  
end testbench;
