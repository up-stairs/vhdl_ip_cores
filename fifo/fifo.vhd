
--------------------------------------------------------------------
--========== https://github.com/up-stairs/vhdl_ip_cores ==========--
--------------------------------------------------------------------

-- The code is a FIFO implementation in VHDL with the option to choose between two modes: normal mode and First Word Fall Through (FWFT) mode. 
-- It includes read and write processes, as well as data count tracking and control signals for full and empty conditions. 
-- The code also handles the special case of the first read in FWFT mode.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo is
  generic (
    C_IS_FWFT_MODE    : boolean := true;
    C_DATA_WIDTH      : natural := 16;
    C_FIFO_DEPTH_LOG2 : natural := 10
  );
  port (
    clock             : in  std_logic;
    reset             : in  std_logic;
    wr_en             : in  std_logic;
    rd_en             : in  std_logic;
    wr_data           : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
    rd_data           : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
    data_count        : out std_logic_vector(C_FIFO_DEPTH_LOG2 downto 0);
    full              : out std_logic;
    empty             : out std_logic
  );
end fifo;

architecture rtl of fifo is
  
  constant C_FIFO_DEPTH     : natural := 2**C_FIFO_DEPTH_LOG2;

  type t_FIFO_TYPE is array (0 to C_FIFO_DEPTH-1) of std_logic_vector(C_DATA_WIDTH-1 downto 0);

  shared variable fifo_mem : t_FIFO_TYPE;
  
  signal wr_ptr           : unsigned(C_FIFO_DEPTH_LOG2-1 downto 0);
  signal rd_ptr           : unsigned(C_FIFO_DEPTH_LOG2-1 downto 0);
  signal data_count_reg   : unsigned(C_FIFO_DEPTH_LOG2 downto 0);
  signal rd_data_reg      : std_logic_vector(C_DATA_WIDTH-1 downto 0);
  signal full_sig         : std_logic;
  signal empty_sig        : std_logic;
  signal write_fifo       : std_logic;
  signal read_fifo        : std_logic;
  
begin

  rd_data       <= rd_data_reg;
  full          <= full_sig;
  data_count    <= std_logic_vector(data_count_reg);

  -- Full signal is high when the FIFO is full
  full_sig      <= '1' when (data_count_reg = C_FIFO_DEPTH) else '0';

  -- Empty signal is high when the FIFO is empty
  empty_sig     <= '1' when (data_count_reg = 0) else '0';

  -- Write enable signal for the FIFO
  write_fifo    <= wr_en when full_sig = '0' else '0';


  -- Normal mode: Data is read from the FIFO
  normal_mode: if (not(C_IS_FWFT_MODE)) generate
  begin
    empty         <= empty_sig;
    -- Read enable signal for the FIFO
    read_fifo     <= rd_en when empty_sig = '0' else '0';
  
    process (clock, reset)
    begin
      if reset = '1' then
        rd_ptr  <= (others => '0');
      elsif rising_edge(clock) then
        if read_fifo = '1' then
          rd_data_reg   <= fifo_mem(to_integer(rd_ptr));
          if (rd_ptr >= C_FIFO_DEPTH-1) then
            rd_ptr  <= (others => '0');
          else
            rd_ptr  <= (rd_ptr + 1);
          end if;
        end if;
      end if;
    end process;
  end generate;
  
  -- First Word Fall Through (FWFT) mode: Data is read from the FIFO with special handling for the first read
  fwft_mode: if (C_IS_FWFT_MODE) generate
    signal first_read     : std_logic;
    signal empty_r1       : std_logic;
    signal temp       : std_logic;
  begin
    
    empty     <= not first_read;
    temp      <= '1' when first_read = '0' or rd_en = '1' else '0';
    read_fifo <= '1' when empty_sig = '0' and temp = '1' else '0' ;
    
    process (clock, reset)
    begin
      if reset = '1' then
        first_read  <= '0';
      elsif rising_edge(clock) then
        if (empty_sig = '0' or temp = '0') then
          first_read  <= '1';
        else
          first_read  <= '0';
        end if;
      end if;
    end process;
    
  end generate;
  
  -- Write process: Data is written to the FIFO
  process (clock, reset)
  begin
    if reset = '1' then
      wr_ptr  <= (others => '0');
    elsif rising_edge(clock) then
      if write_fifo = '1' then
        fifo_mem(to_integer(wr_ptr)) := wr_data;
        if (wr_ptr >= C_FIFO_DEPTH-1) then
          wr_ptr  <= (others => '0');
        else
          wr_ptr  <= (wr_ptr + 1);
        end if;
      end if;
    end if;
  end process;

    
  -- Read process: Data is read from the FIFO
  process (clock, reset)
  begin
    if reset = '1' then
      rd_ptr  <= (others => '0');
      rd_data_reg  <= (others => '0');
    elsif rising_edge(clock) then
      if read_fifo = '1' then
        rd_data_reg   <= fifo_mem(to_integer(rd_ptr));
        if (rd_ptr >= C_FIFO_DEPTH-1) then
          rd_ptr  <= (others => '0');
        else
          rd_ptr  <= (rd_ptr + 1);
        end if;
      end if;
    end if;
  end process;
    
  -- Data count update process: Updates the data count based on read and write operations
  process (clock, reset)
  begin
    if reset = '1' then
      data_count_reg  <= (others => '0');
    elsif rising_edge(clock) then
      if write_fifo = '0' and read_fifo = '1' then
        data_count_reg    <= data_count_reg - 1;
      end if;
      if write_fifo = '1' and read_fifo = '0' then
        data_count_reg    <= data_count_reg + 1;
      end if;
    end if;
  end process;

end rtl;
