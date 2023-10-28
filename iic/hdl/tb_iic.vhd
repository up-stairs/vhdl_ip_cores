library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_iic is
end tb_iic;

architecture tb_arch of tb_iic is

  ------------------------------------------------------------------------------
  type t_integer_vector is array (integer range <>) of integer;
  shared variable DEFAULT_SEEDs       : t_integer_vector(0 to 1) := (26513879, 20136548);
  
  impure function randi(
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

  signal iicm_s_xfer_ttype      : std_logic_vector(2 downto 0);
  
  constant C_TYPE_START         : std_logic_vector(iicm_s_xfer_ttype'range) := std_logic_vector(to_unsigned(1, iicm_s_xfer_ttype'length));
  constant C_TYPE_WRITE         : std_logic_vector(iicm_s_xfer_ttype'range) := std_logic_vector(to_unsigned(2, iicm_s_xfer_ttype'length));
  -- constant C_TYPE_WRITE_N_END   : std_logic_vector(iicm_s_xfer_ttype'range) := std_logic_vector(to_unsigned(3, iicm_s_xfer_ttype'length); -- TODO
  constant C_TYPE_READ          : std_logic_vector(iicm_s_xfer_ttype'range) := std_logic_vector(to_unsigned(4, iicm_s_xfer_ttype'length));
  constant C_TYPE_READNOACK     : std_logic_vector(iicm_s_xfer_ttype'range) := std_logic_vector(to_unsigned(5, iicm_s_xfer_ttype'length));
  constant C_TYPE_END           : std_logic_vector(iicm_s_xfer_ttype'range) := std_logic_vector(to_unsigned(6, iicm_s_xfer_ttype'length));
  
  signal clock         : std_logic;
  signal reset         : std_logic;


  signal iic_sda                  : std_logic;
  signal iic_scl                  : std_logic;
  signal iicm_s_xfer_tvalid       : std_logic;
  signal iicm_s_xfer_tready       : std_logic;
  signal iicm_s_xfer_tdata        : std_logic_vector(7 downto 0);
  signal iicm_s_xfer_tperiod      : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(5, 8));
  signal iicm_m_xfer_tstatus      : std_logic;
  signal iicm_m_data_tvalid       : std_logic;
  signal iicm_m_data_tdata        : std_logic_vector(7 downto 0);
  signal err_no_ack               : std_logic;
  
  signal iics_m_data_tvalid       : std_logic;
  signal iics_m_data_tdata        : std_logic_vector(7 downto 0);
  signal iics_m_xfer_tstatus      : std_logic;
  signal iics_m_xfer_tack         : std_logic;
  signal iics_m_xfer_tnoack       : std_logic;

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
    reset   <= '1';
    wait for CPERIOD*100;
    reset   <= '0';
    wait;
  end process;
  
  
  process
    variable modcod_v   : integer;
  begin
    iicm_s_xfer_tvalid   <= '0';
    wait until falling_edge(reset);
    
    while (true) loop
      iicm_s_xfer_tvalid   <= '0';
      
      if (iicm_s_xfer_tready = '1') then
        modcod_v := randi(0, 2**30-1);
        iicm_s_xfer_tdata    <= std_logic_vector(to_unsigned(modcod_v, iicm_s_xfer_tdata'length));
        
        wait for CPERIOD/10;
        iicm_s_xfer_tvalid    <= '1';
        
        if (iicm_s_xfer_ttype = C_TYPE_START) then
          iicm_s_xfer_ttype     <= C_TYPE_WRITE;
        elsif (iicm_s_xfer_ttype = C_TYPE_WRITE) then
          iicm_s_xfer_ttype     <= C_TYPE_END;
        else
          iicm_s_xfer_ttype     <= C_TYPE_START;
        end if;
      
        wait for CPERIOD;
        iicm_s_xfer_tvalid   <= '0';
      end if;
      
      wait for CPERIOD*randi(0, 100);
    end loop;
    
    wait;
  end process;
  
  dut_iic_master : entity work.iic_master
    port map (
      clock               => clock,
      reset               => reset,
      
      iic_sda             => iic_sda,
      iic_scl             => iic_scl,
      
      s_xfer_tvalid       => iicm_s_xfer_tvalid  ,     
      s_xfer_tready       => iicm_s_xfer_tready  ,     
      s_xfer_ttype        => iicm_s_xfer_ttype   ,     
      s_xfer_tdata        => iicm_s_xfer_tdata   ,     
      s_xfer_tperiod      => iicm_s_xfer_tperiod ,   
      m_xfer_tstatus      => iicm_m_xfer_tstatus ,     
      m_data_tvalid       => iicm_m_data_tvalid,
      m_data_tdata        => iicm_m_data_tdata,
      
      err_no_ack          => err_no_ack
    );
    
  iic_sda   <= '1' when iic_sda = 'Z' else iic_sda;
  -- iic_scl   <= '1' when iic_scl = 'Z' else iic_scl;


  dut_iic_slave : entity work.iic_slave
    port map (
      clock               => clock,
      reset               => reset,
      
      iic_sda             => iic_sda,
      iic_scl             => iic_scl,
      
      m_xfer_tstatus      => iics_m_xfer_tstatus ,     
      m_xfer_tack         => iics_m_xfer_tack ,     
      m_xfer_tnoack       => iics_m_xfer_tnoack ,     
      
      m_data_tvalid       => iics_m_data_tvalid,
      m_data_tdata        => iics_m_data_tdata
    );
    
end tb_arch;
