--------------------------------------------------------------------
--========== https://github.com/up-stairs/vhdl_ip_cores ==========--
--------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Entity Declaration
entity crc_gen is
  generic (
    g_CRC_POLY            : std_logic_vector; -- assign 0x1D for x8 + x4 + x3 + x2 + 1, i.e., donot enter a value for x8
    g_CRC_INIT            : std_logic_vector; -- initial value for the initial value of the shift register, must of the of the same size with g_CRC_POLY
    g_DATAW               : natural := 8; -- bit width of s_axi_data_tdata
    g_USERW               : natural := 8 -- bit width of s_axi_data_tuser
  );
  port (
    clock                 : in  std_logic; -- Clock input
    reset                 : in  std_logic; -- Reset input

    -- input data bus
    s_axi_data_tvalid     : in std_logic;
    s_axi_data_tlast      : in std_logic;
    s_axi_data_tdata      : in std_logic_vector(g_DATAW-1 downto 0);
    s_axi_data_tuser      : in std_logic_vector(g_USERW-1 downto 0);
 
    -- output data bus
    m_axi_data_tvalid     : out std_logic;
    m_axi_data_tdata      : out std_logic_vector(g_CRC_POLY'range);
    m_axi_data_tuser      : out std_logic_vector(g_USERW-1 downto 0)
  );
end entity crc_gen;

-- RTL Architecture
architecture rtl of crc_gen is

  constant c_CRC_POLY_LEN       : natural := g_CRC_POLY'length;
  constant c_CRC_POLY           : std_logic_vector(c_CRC_POLY_LEN-1 downto 0) := g_CRC_POLY;
  signal crc_shift_reg          : std_logic_vector(c_CRC_POLY_LEN-1 downto 0);
  
  
begin

  
  pr_output : process(clock, reset)
  begin
    if reset = '1' then
      m_axi_data_tvalid   <= '0';
      m_axi_data_tuser    <= (others => '0');
    elsif rising_edge(clock) then
      m_axi_data_tvalid   <= s_axi_data_tvalid and s_axi_data_tlast;
      m_axi_data_tuser    <= s_axi_data_tuser;
    end if;
  end process;
  
  ----------
  -- > calculates the crc of the input by employing a loop
  -- to iterate the shift register g_DATAW bits per clock
  ----------
  pr_crc_gen : process(clock, reset)
    variable v_crcsr    : std_logic_vector(c_CRC_POLY_LEN-1 downto 0);
    variable v_srin     : std_logic;
  begin
    if reset = '1' then
      crc_shift_reg       <= g_CRC_INIT;
      m_axi_data_tdata    <= (others => '0');
    elsif rising_edge(clock) then
      if (s_axi_data_tvalid = '1') then
        v_crcsr         := crc_shift_reg;
        for i in s_axi_data_tdata'range loop
          v_srin          := v_crcsr(c_CRC_POLY_LEN-1) xor s_axi_data_tdata(i);
          v_crcsr         := (v_crcsr(c_CRC_POLY_LEN-2 downto 0) & '0') xor (c_CRC_POLY and v_srin);
        end loop;
          
        if (s_axi_data_tlast = '1') then
          crc_shift_reg     <= g_CRC_INIT;
          m_axi_data_tdata  <= v_crcsr;
        else
          crc_shift_reg     <= v_crcsr;
        end if;
      end if;
    end if;
  end process;


end architecture rtl;
