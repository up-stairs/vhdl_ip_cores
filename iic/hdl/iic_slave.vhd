
--------------------------------------------------------------------
--========== https://github.com/up-stairs/vhdl_ip_cores ==========--
--------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity iic_slave is
  generic (
    C_IIC_SLAVE_ADDR    : std_logic_vector(6 downto 0) := "1010101" -- not used in the code, added just to give insight
  );
  port (
    clock               : in std_logic;
    reset               : in std_logic;
    
    iic_sda_i           : in std_logic;
    iic_sda_o           : out std_logic;
    -- iic_sda_t           : out std_logic;
    iic_scl_i           : in std_logic;
    iic_scl_o           : out std_logic;
    -- iic_scl_t           : out std_logic;
    
    m_data_tvalid       : out std_logic;
    m_data_tdata        : out std_logic_vector(7 downto 0);
    
    m_xfer_tstatus      : out std_logic; -- 1 => There is an active IIC transaction, 0 => No movement on the bus
    
    m_xfer_tack         : out std_logic; -- 1 => The master acknowledged the transfer, 0 => steady state
    m_xfer_tnoack       : out std_logic  -- 1 => The master not acknowledged the transfer, 0 => steady state
  );
end iic_slave;

architecture str of iic_slave is

  -- Type definitions
  type t_STATE is (
    IDLE_ST,
    XEND_ST,
    XWRITE_ST,
    XSENDACK_ST,
    XREAD_ST,
    XGETACK_ST
  );

  constant C_IIC_WRITE          : std_logic := '0';
  constant C_IIC_READ           : std_logic := '1';

  -- Signal definitions
  signal iic_scl_r1             : std_logic;
  signal iic_scl_r2             : std_logic;
  signal iic_scl_r3             : std_logic;
  signal iic_sda_r1             : std_logic;
  signal iic_sda_r2             : std_logic;
  signal iic_sda_r3             : std_logic;
  
  signal iic_slave_state       : t_STATE;
  signal st_sym_cntr           : natural range 15 downto 0;
  -- signal st_sym_cntr           : unsigned(UNSIGNED_NUM_BITS(C_SERIAL_DATA_W) downto 0);
  signal st_rcvd_data          : std_logic_vector(m_data_tdata'range);
  signal st_rcvd_valid         : std_logic;
  signal st_dev_addr           : std_logic;
  
  signal st_iic_read_data      : std_logic_vector(31 downto 0);

begin
  
  -- this entity does not modify the clock
  iic_scl_o <= '1';
  
  -- register iic output signals the create a setup and hold delay
  process (clock, reset)
  begin
    if reset = '1' then
      iic_scl_r1  <= '1';
      iic_scl_r2  <= '1';
      iic_scl_r3  <= '1';
      iic_sda_r1  <= '1';
      iic_sda_r2  <= '1';
      iic_sda_r3  <= '1';
    elsif rising_edge(clock) then
      iic_scl_r1  <= iic_scl_i;
      iic_scl_r2  <= iic_scl_r1;
      iic_scl_r3  <= iic_scl_r2;
      iic_sda_r1  <= iic_sda_i;
      iic_sda_r2  <= iic_sda_r1;
      iic_sda_r3  <= iic_sda_r2;
    end if;
  end process;
  
  -- Main process for SPI functionality
  process (clock, reset)
  begin
    if reset = '1' then
      -- Reset condition: Set the initial state and other variables
      iic_slave_state         <= IDLE_ST;
      m_xfer_tack         <= '0';
      m_xfer_tnoack       <= '0';
      st_rcvd_valid           <= '0';
      st_dev_addr             <= '1';
      st_iic_read_data        <= X"DEADBEEF";
    elsif rising_edge(clock) then
    
      -- assign the default values to control signals
      m_xfer_tack         <= '0';
      m_xfer_tnoack       <= '0';
      st_rcvd_valid <= '0';
      
      --------------------------------------------------
      -- detect start/repeated start condition
      if (iic_sda_r3 = '1' and iic_sda_r2 = '0' and iic_scl_r3 = '1' and iic_scl_r2 = '1') then
        st_sym_cntr     <= 0;
        st_dev_addr     <= '1';
        iic_slave_state <= XWRITE_ST;
      --------------------------------------------------
      
      --------------------------------------------------
      -- detect END condition
      elsif (iic_sda_r3 = '0' and iic_sda_r2 = '1' and iic_scl_r3 = '1' and iic_scl_r2 = '1') then 
        iic_slave_state <= IDLE_ST;
      --------------------------------------------------
      
      --------------------------------------------------
      -- the slave state machine
      else
        case iic_slave_state is
          when IDLE_ST =>
            st_sym_cntr     <= 0;
          
          --------------------------------------------------
          -- IIC Write transaction (IIC Master writes data to IIC Slave)
          --------------------------------------------------
          when XWRITE_ST =>
            -- detect rising edge of SCL
            if (iic_scl_r2 = '1' and iic_scl_r3 = '0') then
              st_sym_cntr       <= st_sym_cntr + 1;
              st_rcvd_data(st_sym_cntr)   <= iic_sda_r1; -- it assumed that the SDA line is stable at this moment
              if st_sym_cntr = 7 then -- all data is read
                st_rcvd_valid     <= '1';
              end if;
            end if;
            
            -- detect falling edge of SCL to drive the SDA line
            if (iic_scl_r2 = '0' and iic_scl_r3 = '1') then
              if st_sym_cntr = 8 then -- it is time to ACK
                iic_slave_state <= XSENDACK_ST;
              end if;
            end if;
          --------------------------------------------------
          -- IIC Write ACKnowledge (IIC Slave acknowledges the IIC Master)
          --------------------------------------------------
          when XSENDACK_ST =>
            -- detect falling edge of SCL to drive the SDA line
            if (iic_scl_r2 = '0' and iic_scl_r3 = '1') then
              -- check it is the first BYTE of the transfer
              if (st_dev_addr = '1') then
                st_dev_addr     <= '0';
                --------------------------------------------------
                -- C_IIC_SLAVE_ADDR can be controlled here
                --------------------------------------------------
                -- check the READ/WRITE request
                if (st_rcvd_data(7) = C_IIC_WRITE) then
                  iic_slave_state <= XWRITE_ST;
                else
                  iic_slave_state <= XREAD_ST;
                end if;
              else
                iic_slave_state <= XWRITE_ST;
              end if;
            end if;
            
          --------------------------------------------------
          -- IIC Read transaction (IIC Master reads data from IIC Slave)
          --------------------------------------------------
          when XREAD_ST =>
            -- detect falling edge of SCL to drive the SDA line
            if (iic_scl_r2 = '0' and iic_scl_r3 = '1') then
              st_sym_cntr       <= st_sym_cntr + 1;
              
              -- drive the SDA line with the new data bit whenever a falling edge SCL detected
              if (st_sym_cntr <= 7) then
                -- the bus is driven by a constant word just to test the code
                -- you can change the code such that the data is read from outside of the entity
                
                -- rotate st_iic_read_data
                st_iic_read_data  <= st_iic_read_data(30 downto 0) & st_iic_read_data(31);
              else -- its time the IIC Master ACKnowledge to ACK Slave
              end if;
              -- all data is sent, so it is time get ACK
              if (st_sym_cntr >= 8) then
                iic_slave_state   <= XGETACK_ST;
              end if;
            end if;
          when XGETACK_ST =>
            -- detect rising edge of SCL before reading SDI line
            if (iic_scl_r2 = '1' and iic_scl_r3 = '0') then
              -- SDI = '0' means the IIC Master is acknowledging the Slave
              m_xfer_tack     <= not(iic_sda_r1); -- it assumed that the SDA line is stable at this moment
              m_xfer_tnoack   <= iic_sda_r1; -- it assumed that the SDA line is stable at this moment
              iic_slave_state     <= XREAD_ST;
            end if;
            
          when others =>
            -- Handle other states (should not occur in this code)
            null;
        end case;
        -- end of the state machine
        --------------------------------------------------
        
      end if;
    end if;
  end process;
  
  iic_sda_o       <= '0' when iic_slave_state = XSENDACK_ST else
                     '0' when iic_slave_state = XREAD_ST and st_iic_read_data(15) = '0' else
                     '1';
  
  
  -- Reports the status of active spi transfer
  process (clock)
  begin
    if rising_edge(clock) then
      if (iic_slave_state = IDLE_ST) then 
        m_xfer_tstatus  <= '0';
      else
        m_xfer_tstatus  <= '1';
      end if;
    end if;
  end process;
  
  -- Process for output generation
  process (clock)
  begin
    if rising_edge(clock) then
      m_data_tvalid   <= '0';
      if (st_rcvd_valid = '1') then
        m_data_tvalid   <= '1';
        m_data_tdata    <= st_rcvd_data;
      end if;
    end if;
  end process;

end str;
