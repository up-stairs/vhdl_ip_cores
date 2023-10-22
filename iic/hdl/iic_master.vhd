
--------------------------------------------------------------------
--========== https://github.com/up-stairs/vhdl_ip_cores ==========--
--------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity iic_master is
  generic (
    C_SERIAL_DATA_W : natural := 16
  );
  port (
    clock               : in std_logic;
    reset               : in std_logic;
    
    iic_sda             : out std_logic;
    iic_scl             : out std_logic;
    
    s_xfer_tvalid       : in std_logic; -- tells the module to start a new iic transfer. a transfer starts when s_xfer_tvalid and s_xfer_tready are both ACTIVE (1)
    s_xfer_tready       : out std_logic; -- the modules output stating that it is ready for a new transfer. 
    s_xfer_ttype        : in std_logic_vector(3 downto 0); -- transfer type (see the constant within the module). sampled by the module when s_xfer_tvalid and s_xfer_tready are both ACTIVE (1)
    s_xfer_tdata        : in std_logic_vector(7 downto 0); -- data to be transferred to the slave. sampled by the module when s_xfer_tvalid and s_xfer_tready are both ACTIVE (1)
    s_xfer_tperiod      : in std_logic_vector(7 downto 0); -- defines the IIC clock period. sampled by the module when s_xfer_tvalid and s_xfer_tready are both ACTIVE (1)
    
    m_xfer_tstatus      : out std_logic; -- signal indicating that an active iic transaction is active or not 
                                         -- goes to ACTIVE (1) after a START condition and to PASSIVE (0) after an END condition
    
    m_data_tvalid       : out std_logic;
    m_data_tdata        : out std_logic_vector(7 downto 0);
    
    err_no_ack          : out std_logic -- signal indicating that the xfer is not ACKnowledged by the the slave.
                                        -- goes to ACTIVE (1) after an ACK is not received and to PASSIVE (0) after an ACK is received
  );
end iic_master;

architecture str of iic_master is

  -- Type definitions
  type t_STATE is (
    IDLE_ST,
    XFER_ST
  );

  constant C_TYPE_START         : std_logic_vector(s_xfer_ttype'range) := 1;
  constant C_TYPE_START         : std_logic_vector(s_xfer_ttype'range) := 1;

  -- Signal definitions
  signal csn_sr                 : std_logic_vector(C_SRL-1 downto 0);
  signal sck_sr                 : std_logic_vector(C_SRL-1 downto 0);
  signal mosi_sr                : std_logic_vector(C_SRL-1 downto 0);
  
  signal iic_master_state       : t_STATE;
  signal st_sym_cntr           : natural range C_SERIAL_DATA_W-1 downto 0;
  -- signal st_sym_cntr           : unsigned(UNSIGNED_NUM_BITS(C_SERIAL_DATA_W) downto 0);
  signal st_rcvd_data          : std_logic_vector(m_axi_data_tdata'range);
  signal st_rcvd_valid         : std_logic;

begin

  -- Process to create delayed versions of inputs
  process (clock, reset)
  begin
    if reset = '1' then
      clk_period_cntr <= (others => '0');
      clk_period_reg  <= (others => '0');
      clk_pulse       <= '0';
    elsif rising_edge(clock) then
      clk_pulse       <= '0';
      if (iic_master_state = IDLE_ST) then
        clk_period_cntr   <= (others => '0');
        if (s_xfer_tvalid = '1' and s_xfer_tready_sig = '1') then
          clk_period_reg    <= s_xfer_tperiod;
        end if;
      else
        if (clk_period_cntr = clk_period_reg-1) then
          clk_pulse         <= '1';
          clk_period_cntr   <= (others => '0');
        else
          clk_period_cntr   <= clk_period_cntr + 1;
          if (clk_period_cntr = clk_period_reg/2-1) then
            clk_pulse         <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;
  
  -- Main process for SPI functionality
  process (clock, reset)
  begin
    if reset = '1' then
      -- Reset condition: Set the initial state and other variables
      iic_master_state   <= IDLE_ST;
    elsif rising_edge(clock) then
      -- On rising edge of clock
      st_rcvd_valid <= '0';
      case iic_master_state is
        when IDLE_ST =>
          -- Idle state
          st_sym_cntr     <= C_SERIAL_DATA_W - 1;
          
          -- detect falling edge of CSN signal
          if csn_sr(C_SRL-1 downto C_SRL-2) = "10" then
            -- Check for start bit
            iic_master_state <= XFER_ST;
          end if;
          
        when XFER_ST =>
          -- detect rising edge of CSN signal
          if csn_sr(C_SRL-1 downto C_SRL-2) = "01" then
            -- Move to the idle state
            iic_master_state     <= IDLE_ST;
          else
            -- sample the data on MOSI on the rising edge of SCK
            if sck_sr(C_SRL-1 downto C_SRL-2) = "01" then
              st_rcvd_data(st_sym_cntr)   <= mosi_sr(C_SRL-1);
              if st_sym_cntr = 0 then
                st_rcvd_valid     <= '1';
                st_sym_cntr       <= C_SERIAL_DATA_W - 1;
              else
                st_sym_cntr       <= st_sym_cntr - 1;
              end if;
            end if;
          end if;
          
        when others =>
          -- Handle other states (should not occur in this code)
          null;
      end case;
    end if;
  end process;
  
  -- an intentionally created latch
  MISO    <= s_axi_data_tdata(st_sym_cntr) when SCK = '0';
  
  -- Reports the status of active spi transfer
  process (clock)
  begin
    if rising_edge(clock) then
      if (iic_master_state = IDLE_ST) then 
        m_axi_xfer_tstatus  <= '0';
      else
        m_axi_xfer_tstatus  <= '1';
      end if;
    end if;
  end process;
  
  -- Process for output generation
  process (clock)
  begin
    if rising_edge(clock) then
      m_axi_data_tvalid   <= '0';
      if (iic_master_state = XFER_ST and st_rcvd_valid = '1') then
        m_axi_data_tvalid   <= '1';
        m_axi_data_tdata    <= st_rcvd_data;
      end if;
    end if;
  end process;

end str;
