
--------------------------------------------------------------------
--========== https://github.com/up-stairs/vhdl_ip_cores ==========--
--------------------------------------------------------------------

-- the following comment is generated by chatgpt
--
-- Overall, this code implements a UART receiver that receives serial data, 
-- detects start, data, parity, and stop bits, 
-- and provides the received data on m_axi_data_tdata. 
-- It also sets m_axi_data_tvalid to indicate the validity of the received data 
-- and err_parity to indicate any parity errors.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_recv is
  generic (
    C_SYMBOL_PERIOD : std_logic_vector;
    C_SERIAL_DATA_W : natural
  );
  port (
    clock             : in std_logic;
    reset             : in std_logic;
    serial_data_recv  : in std_logic;
    m_axi_data_tvalid : out std_logic;
    m_axi_data_tdata  : out std_logic_vector(C_SERIAL_DATA_W-1 downto 0);
    err_parity        : out std_logic
  );
end uart_recv;

architecture str of uart_recv is

  -- Type definitions
  type t_STATE is (
    IDLE_ST,
    RECEIVE_START_ST,
    RECEIVE_DATA_ST,
    RECEIVE_PARITY_ST,
    RECEIVE_STOP_ST
  );

  constant C_SYMBOL_PERIOD_I    : natural := to_integer(unsigned(C_SYMBOL_PERIOD));

  -- Signal definitions
  signal serial_data_recv_r1   : std_logic;
  signal serial_data_recv_r2   : std_logic;
  signal serial_data_recv_r3   : std_logic;
  signal timer_cntr            : unsigned(C_SYMBOL_PERIOD'range);
  signal timer_pulse           : std_logic;
  signal uart_recv_state       : t_STATE;
  signal st_sym_cntr         : natural range C_SERIAL_DATA_W-1 downto 0;
  -- signal st_sym_cntr           : unsigned(UNSIGNED_NUM_BITS(C_SERIAL_DATA_W) downto 0);
  signal st_rcvd_data          : std_logic_vector(m_axi_data_tdata'range);
  signal st_parity             : std_logic;

begin

  -- Process to create delayed versions of serial_data_recv
  process (clock, reset)
  begin
    if reset = '1' then
      -- Reset the delayed versions of serial_data_recv
      serial_data_recv_r1 <= '0';
      serial_data_recv_r2 <= '0';
      serial_data_recv_r3 <= '0';
    elsif rising_edge(clock) then
      -- Create delayed versions of serial_data_recv
      serial_data_recv_r1 <= serial_data_recv;
      serial_data_recv_r2 <= serial_data_recv_r1;
      serial_data_recv_r3 <= serial_data_recv_r2;
    end if;
  end process;

  -- Theis process handles the timer functionality. 
  -- It increments timer_cntr on each clock cycle and sets timer_pulse high when timer_cntr reaches C_SYMBOL_PERIOD_I - 1.
  process(clock, reset)
  begin
    if reset = '1' then
      -- Reset condition: Set timer_pulse to '0' and reset timer_cntr
      timer_pulse  <= '0';
      timer_cntr   <= (others => '0');
    elsif rising_edge(clock) then
      -- On rising edge of clock
      timer_pulse  <= '0';
      if (uart_recv_state = IDLE_ST) then
        -- When uart_recv_state is stable
        timer_cntr   <= to_unsigned(C_SYMBOL_PERIOD_I/2, timer_cntr'length);
      else
        -- When uart_recv_state changes
        if (timer_cntr >= C_SYMBOL_PERIOD_I-1) then
          -- If timer_cntr is equal to or greater than C_SYMBOL_PERIOD-1
          timer_pulse  <= '1';
          timer_cntr   <= (others => '0');
        else
          -- Increment timer_cntr
          timer_cntr   <= timer_cntr + 1;
        end if;
      end if;
    end if;
  end process;
  
  -- Main process for UART receiver functionality
  -- This process is the main process of the UART receiver. 
  -- It controls the state transitions based on the received data and timer pulses.
  -- Inside the main process, there is a case statement that handles different states of the UART receiver. 
  -- It transitions between states based on the received data and the timer pulse.
  process (clock, reset)
  begin
    if reset = '1' then
      -- Reset condition: Set the initial state and other variables
      uart_recv_state   <= IDLE_ST;
    elsif rising_edge(clock) then
      -- On rising edge of clock
      case uart_recv_state is
        when IDLE_ST =>
          -- Idle state
          st_sym_cntr     <= C_SERIAL_DATA_W - 1;
          st_parity       <= '0';
          if serial_data_recv_r3 = '1' and serial_data_recv_r2 = '0' then
            -- Check for start bit
            uart_recv_state <= RECEIVE_START_ST;
          end if;
        when RECEIVE_START_ST =>
          -- Receiving start bit
          if timer_pulse = '1' then
            uart_recv_state <= RECEIVE_DATA_ST;
          end if;
        when RECEIVE_DATA_ST =>
          -- Receiving data bits
          if timer_pulse = '1' then
            -- Store received data bit, update parity, and decrement symbol index
            st_parity                   <= st_parity xor serial_data_recv_r3;
            st_rcvd_data(st_sym_cntr)   <= serial_data_recv_r3;
            if st_sym_cntr = 0 then
              -- All data bits received
              uart_recv_state             <= RECEIVE_PARITY_ST;
            else
              st_sym_cntr                 <= st_sym_cntr - 1;
            end if;
          end if;
        when RECEIVE_PARITY_ST =>
          -- Receiving parity bit
          if timer_pulse = '1' then
            -- Update parity and move to the stop bit
            st_parity           <= st_parity xor serial_data_recv_r3;
            uart_recv_state     <= RECEIVE_STOP_ST;
          end if;
        when RECEIVE_STOP_ST =>
          -- Receiving stop bit
          if timer_pulse = '1' then
            -- Move to the idle state
            uart_recv_state     <= IDLE_ST;
          end if;
        when others =>
          -- Handle other states (should not occur in this code)
          null;
      end case;
    end if;
  end process;
  
  -- Process for output generation
  process (clock)
  begin
    if rising_edge(clock) then
      -- Reset outputs
      m_axi_data_tvalid   <= '0';
      err_parity          <= '0';
      if (uart_recv_state = RECEIVE_STOP_ST) then
        -- If in the stop state
        if timer_pulse = '1' then
          -- Check for valid data and parity error
          if st_parity = '0' and serial_data_recv_r3 = '1' then
            -- Set valid data and output received data
            m_axi_data_tvalid   <= '1';
            m_axi_data_tdata    <= st_rcvd_data;
          else
            -- Set parity error flag
            err_parity          <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

end str;
