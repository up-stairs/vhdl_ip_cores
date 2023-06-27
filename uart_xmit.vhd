-- Overall, the code implements a functional UART transmitter module that can receive data to be transmitted,
-- generate start/stop bits, calculate and transmit parity bit, and control the timing of the transmission using a timer pulse generator.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_xmit is
  generic (
    C_SYMBOL_PERIOD     : std_logic_vector;  -- Symbol period for generating timer pulses
    C_SERIAL_DATA_W     : natural  -- Width of the serial data
  );
  port (
    clock               : in std_logic;  -- Clock signal
    reset               : in std_logic;  -- Reset signal
    s_axi_data_tvalid   : in std_logic;  -- Data valid signal
    s_axi_data_tdata    : in std_logic_vector(C_SERIAL_DATA_W-1 downto 0);  -- Serial data input
    serial_data_xmit    : out std_logic  -- Serial data output
  );
end uart_xmit;

architecture rtl of uart_xmit is

  type t_STATE is (
    IDLE_ST,
    SEND_START_ST,
    SEND_DATA_ST,
    SEND_PARITY_ST,
    SEND_STOP_ST
  );

  signal timer_rst          : std_logic;  -- Timer reset signal
  signal timer_pulse        : std_logic;  -- Timer pulse signal
  signal uart_xmit_state    : t_STATE;  -- State variable for UART transmission
  signal st_sym_cntr        : natural range C_SERIAL_DATA_W-1 downto 0;  -- Index of the current symbol being transmitted
  signal st_data_to_send    : std_logic_vector(s_axi_data_tdata'range);  -- Data to be transmitted
  signal st_parity          : std_logic;  -- Parity bit for transmission

begin

  i_symbol_pulse_gen : entity work.pepugen
  generic map(
    C_TIMER_W     => C_SYMBOL_PERIOD'length  -- Width of the timer pulse generator
  )
  port map (
    clock         => clock,  -- Clock signal
    reset         => timer_rst,  -- Reset signal
    clock_en      => '1',  -- Enable the clock for the pulse generator
    pulse_period  => C_SYMBOL_PERIOD,  -- Period for generating timer pulses
    pulse_signal  => timer_pulse  -- Output pulse signal
  );

  timer_rst   <= '1' when uart_xmit_state = IDLE_ST else '0';  -- Set timer reset based on the current state

  process (clock, reset)
  begin
    if reset = '1' then
      uart_xmit_state <= IDLE_ST;  -- Reset to IDLE state
      serial_data_xmit <= '1';  -- Set serial data output to idle/high
    elsif rising_edge(clock) then
      case uart_xmit_state is
        when IDLE_ST =>
          serial_data_xmit  <= '1';  -- Set serial data output to idle/high
          st_sym_cntr     <= C_SERIAL_DATA_W - 1;  -- Initialize symbol index
          st_data_to_send   <= s_axi_data_tdata;  -- Copy data to be transmitted
          st_parity         <= '0';  -- Initialize parity bit
          if s_axi_data_tvalid = '1' then
            uart_xmit_state <= SEND_START_ST;  -- Transition to sending start bit
          end if;

        when SEND_START_ST =>
          serial_data_xmit <= '0';  -- Set serial data output to start bit/low
          if timer_pulse = '1' then
            uart_xmit_state <= SEND_DATA_ST;  -- Transition to sending data bits
          end if;

        when SEND_DATA_ST =>
          serial_data_xmit <= st_data_to_send(st_sym_cntr);  -- Set serial data output to current data bit
          if timer_pulse = '1' then
            st_parity <= st_data_to_send(st_sym_cntr) xor st_parity;  -- Calculate and update parity bit
            if st_sym_cntr = 0 then
              uart_xmit_state <= SEND_PARITY_ST;  -- Transition to sending parity bit
            else
              st_sym_cntr <= st_sym_cntr - 1;  -- Decrement symbol index
            end if;
          end if;

        when SEND_PARITY_ST =>
          serial_data_xmit <= st_parity;  -- Set serial data output to parity bit
          if timer_pulse = '1' then
            uart_xmit_state <= SEND_STOP_ST;  -- Transition to sending stop bit
          end if;

        when SEND_STOP_ST =>
          serial_data_xmit <= '1';  -- Set serial data output to stop bit/high
          if timer_pulse = '1' then
            uart_xmit_state <= IDLE_ST;  -- Transition to idle state
          end if;

        when others =>
          null;
      end case;
    end if;
  end process;

end rtl;
