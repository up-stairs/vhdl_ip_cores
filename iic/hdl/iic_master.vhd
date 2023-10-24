
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
    
    iic_sda             : inout std_logic;
    iic_scl             : inout std_logic;
    
    s_xfer_tvalid       : in std_logic; -- tells the module to start a new iic transfer. a transfer starts when s_xfer_tvalid and s_xfer_tready are both ACTIVE (1)
    s_xfer_tready       : out std_logic; -- the modules output stating that it is ready for a new transfer. 
    s_xfer_ttype        : in std_logic_vector(2 downto 0); -- transfer type (see the constant within the module). sampled by the module when s_xfer_tvalid and s_xfer_tready are both ACTIVE (1)
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
    WAIT_ST,
    XSTART_ST,
    XREPSTART_ST,
    XEND_ST,
    XWRITE0_ST,
    XWRITE1_ST,
    XREAD0_ST,
    XREAD1_ST
  );

  constant C_TYPE_START         : std_logic_vector(s_xfer_ttype'range) := std_logic_vector(to_unsigned(1, s_xfer_ttype'length));
  constant C_TYPE_WRITE         : std_logic_vector(s_xfer_ttype'range) := std_logic_vector(to_unsigned(2, s_xfer_ttype'length));
  -- constant C_TYPE_WRITE_N_END   : std_logic_vector(s_xfer_ttype'range) := std_logic_vector(to_unsigned(3, s_xfer_ttype'length); -- TODO
  constant C_TYPE_READ          : std_logic_vector(s_xfer_ttype'range) := std_logic_vector(to_unsigned(4, s_xfer_ttype'length));
  constant C_TYPE_READNOACK     : std_logic_vector(s_xfer_ttype'range) := std_logic_vector(to_unsigned(5, s_xfer_ttype'length));
  constant C_TYPE_END           : std_logic_vector(s_xfer_ttype'range) := std_logic_vector(to_unsigned(6, s_xfer_ttype'length));
  
  constant C_SDA_START          : std_logic_vector(0 to 1) := "00";
  constant C_SCL_START          : std_logic_vector(0 to 1) := "10";
  constant C_SDA_REPSTART       : std_logic_vector(0 to 3) := "1100";
  constant C_SCL_REPSTART       : std_logic_vector(0 to 3) := "0110";
  constant C_SDA_END            : std_logic_vector(0 to 1) := "01";
  constant C_SCL_END            : std_logic_vector(0 to 1) := "11";
  
  constant C_TRISTATE           : std_logic := '1';
  constant C_DRIVELOW           : std_logic := not C_TRISTATE;

  -- Signal definitions
  signal iic_scl_i              : std_logic;
  signal iic_scl_t              : std_logic;
  signal iic_sda_i              : std_logic;
  signal iic_sda_t              : std_logic;
  signal iic_scl_r1             : std_logic;
  signal iic_scl_r2             : std_logic;
  signal iic_sda_r1             : std_logic;
  signal iic_sda_r2             : std_logic;
  
  signal s_xfer_tready_sig      : std_logic;
  
  signal clk_pulse              : std_logic;
  signal clk_period_reg         : unsigned(s_xfer_tperiod'range);
  signal clk_period_cntr        : unsigned(s_xfer_tperiod'range);
  
  signal iic_master_state       : t_STATE;
  signal st_iic_cntr            : natural range 0 to 15;
  signal st_write_data          : std_logic_vector(0 to 7); 
  signal st_read_data           : std_logic_vector(0 to 7); 
  signal st_read_valid          : std_logic;
  signal st_send_ack            : std_logic;

begin

  s_xfer_tready   <= s_xfer_tready_sig;
  
  iic_sda         <= '0'      when iic_sda_t = C_DRIVELOW else 'Z';
  iic_scl         <= '0'      when iic_scl_t = C_DRIVELOW else 'Z';
  
  iic_sda_i       <= iic_sda;
  iic_scl_i       <= iic_scl;

  -- register iic output signals the create a setup and hold delay
  process (clock, reset)
  begin
    if reset = '1' then
      iic_scl_r1  <= C_TRISTATE;
      iic_scl_r2  <= C_TRISTATE;
      -- iic_scl_r3  <= C_TRISTATE;
      iic_sda_r1  <= C_TRISTATE;
      iic_sda_r2  <= C_TRISTATE;
    elsif rising_edge(clock) then
      iic_scl_r1  <= iic_scl_i;
      iic_scl_r2  <= iic_scl_r1;
      -- iic_scl_r3  <= iic_scl_r2;
      iic_sda_r1  <= iic_sda_i;
      iic_sda_r2  <= iic_sda_r1;
    end if;
  end process;
  
  -- Process to create delayed versions of inputs
  process (clock, reset)
  begin
    if reset = '1' then
      clk_period_cntr <= (others => '0');
      clk_period_reg  <= (others => '0');
      clk_pulse       <= '0';
    elsif rising_edge(clock) then
      clk_pulse       <= '0';
      if (iic_master_state = IDLE_ST or iic_master_state = WAIT_ST) then
        clk_period_cntr   <= (others => '0');
        if (s_xfer_tvalid = '1' and s_xfer_tready_sig = '1') then
          clk_period_reg    <= unsigned(s_xfer_tperiod);
        end if;
      else
        -- the frequency of SCL must be at least half of or even lower than the frequency of clk
        if (clk_period_cntr = clk_period_reg-1 and clk_period_cntr >= 3) then
          clk_pulse         <= '1';
          clk_period_cntr   <= (others => '0');
        else
          clk_period_cntr   <= clk_period_cntr + 1;
          if (clk_period_cntr = clk_period_reg/2-1 and clk_period_cntr >= 1) then
            clk_pulse         <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;
  
  -- Main process for IIC functionality
  process (clock, reset)
  begin
    if reset = '1' then
      -- Reset condition: Set the initial state and other variables
      iic_master_state    <= IDLE_ST;
      s_xfer_tready_sig   <= '0';
    elsif rising_edge(clock) then
      s_xfer_tready_sig   <= '0';
      
      case iic_master_state is
        when IDLE_ST =>
            -- check for s_xfer_tvalid signal
          if (s_xfer_tvalid = '1' and s_xfer_tready_sig = '1') then
            -- leave this state only with IIC START request
            if (s_xfer_ttype = C_TYPE_START) then
              s_xfer_tready_sig   <= '0';
              iic_master_state <= XSTART_ST;
            end if;
          else
            s_xfer_tready_sig   <= '1';
          end if;
          
        when WAIT_ST =>
          st_iic_cntr   <= 0;
            -- check for s_xfer_tvalid signal
          if (s_xfer_tvalid = '1' and s_xfer_tready_sig = '1') then
            -- leave this state only with IIC START request
            case s_xfer_ttype is
              when C_TYPE_START =>
                iic_master_state    <= XREPSTART_ST;
                s_xfer_tready_sig   <= '0';
              when C_TYPE_END =>
                iic_master_state    <= XEND_ST;
                s_xfer_tready_sig   <= '0';
              when C_TYPE_WRITE =>
                iic_master_state    <= XWRITE0_ST;
                s_xfer_tready_sig   <= '0';
                st_write_data       <= s_xfer_tdata;
              when C_TYPE_READ =>
                iic_master_state    <= XREAD0_ST;
                s_xfer_tready_sig   <= '0';
                st_send_ack         <= '1';
              when C_TYPE_READNOACK =>
                iic_master_state    <= XREAD0_ST;
                s_xfer_tready_sig   <= '0';
                st_send_ack         <= '0';
              when others =>
                iic_master_state <= IDLE_ST;
            end case;
          else
            s_xfer_tready_sig   <= '1';
          end if;
          
        when XSTART_ST =>
          if (clk_pulse = '1') then
            st_iic_cntr   <= st_iic_cntr + 1;
            if (st_iic_cntr = 1) then
              iic_master_state    <= WAIT_ST;
            end if;
          end if;
          
        when XREPSTART_ST =>
          if (clk_pulse = '1') then
            st_iic_cntr   <= st_iic_cntr + 1;
            if (st_iic_cntr = 3) then
              iic_master_state    <= WAIT_ST;
            end if;
          end if;
          
        when XWRITE0_ST =>
          if (clk_pulse = '1') then
            iic_master_state    <= XWRITE1_ST;
          end if;
        when XWRITE1_ST =>
          -- checking the status of SCL because the SLAVE might be stretching the CLK
          if (clk_pulse = '1' and iic_scl_r2 = '1') then
            st_iic_cntr   <= st_iic_cntr + 1;
            if (st_iic_cntr >= 8) then
              iic_master_state    <= WAIT_ST;
            else
              iic_master_state    <= XWRITE0_ST;
            end if;
          end if;
          
        when XREAD0_ST =>
          if (clk_pulse = '1') then
            iic_master_state    <= XREAD1_ST;
          end if;
        when XREAD1_ST =>
          -- checking the status of SCL because the SLAVE might be stretching the CLK
          if (clk_pulse = '1' and iic_scl_r2 = '1') then
            st_iic_cntr   <= st_iic_cntr + 1;
            if (st_iic_cntr >= 8) then
              iic_master_state    <= WAIT_ST;
            else
              iic_master_state    <= XREAD0_ST;
            end if;
          end if;
          
        when XEND_ST =>
          if (clk_pulse = '1') then
            st_iic_cntr   <= st_iic_cntr + 1;
            if (st_iic_cntr = 1) then
              iic_master_state    <= IDLE_ST;
            end if;
          end if;
          
        when others =>
          -- Handle other states (should not occur in this code)
          null;
      end case;
    end if;
  end process;
  
  -- Process to create delayed versions of inputs
  process (clock, reset)
  begin
    if reset = '1' then
      iic_sda_t       <= C_TRISTATE;
      iic_scl_t       <= C_TRISTATE;
      err_no_ack      <= '0';
      st_read_valid   <= '0';
    elsif rising_edge(clock) then
      st_read_valid   <= '0';
      case iic_master_state is
        when IDLE_ST =>
          iic_sda_t       <= C_TRISTATE;
          iic_scl_t       <= C_TRISTATE;
          
        when XSTART_ST =>
          if (clk_pulse = '1') then
            iic_sda_t       <= C_SDA_START(st_iic_cntr);
            iic_scl_t       <= C_SCL_START(st_iic_cntr);
          end if;
          
        when XREPSTART_ST =>
          if (clk_pulse = '1') then
            iic_sda_t       <= C_SDA_REPSTART(st_iic_cntr);
            iic_scl_t       <= C_SCL_REPSTART(st_iic_cntr);
          end if;
          
        when XEND_ST =>
          if (clk_pulse = '1') then
            iic_sda_t       <= C_SDA_END(st_iic_cntr);
            iic_scl_t       <= C_SCL_END(st_iic_cntr);
          end if;
          
        when XWRITE0_ST =>
          if (st_iic_cntr < 8) then
            iic_sda_t       <= st_write_data(st_iic_cntr);
          else
            iic_sda_t       <= C_TRISTATE;
          end if;
          if (clk_pulse = '1') then
            iic_scl_t       <= C_TRISTATE;
          end if;
        when XWRITE1_ST =>
          if (clk_pulse = '1' and iic_scl_r2 = '1') then
            -- get the write ack result
            if (st_iic_cntr >= 8) then
              err_no_ack      <= iic_sda_r2;
            end if;
            iic_scl_t       <= C_DRIVELOW;
          end if;
          
        when XREAD0_ST =>
          -- send acknowledge
          if (st_iic_cntr >= 8 and st_send_ack = '1') then
            iic_sda_t       <= C_DRIVELOW;
          else
            iic_sda_t       <= C_TRISTATE;
          end if;
          if (clk_pulse = '1') then
            iic_scl_t       <= C_TRISTATE;
          end if;
        when XREAD1_ST =>
          if (clk_pulse = '1' and iic_scl_r2 = '1') then
            -- get the value of SDA
            if (st_iic_cntr < 8) then
              st_read_data(st_iic_cntr) <= iic_sda_r2;
              st_read_valid   <= '1';
            end if;
            iic_scl_t       <= C_DRIVELOW;
          end if;
          
        when others =>
          null;
      end case;
    end if;
  end process;
  
  -- register iic output signals the create a setup and hold delay
  process (clock, reset)
  begin
    if reset = '1' then
      m_data_tvalid   <= '0';
      m_data_tdata    <= (others => '0');
    elsif rising_edge(clock) then
      m_data_tvalid   <= st_read_valid;
      m_data_tdata    <= st_read_data;
    end if;
  end process;

end str;
