library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity tb_fifo is
end entity tb_fifo;

architecture tb of tb_fifo is

  type t_integer_vector is array (integer range <>) of integer;
  shared variable DEFAULT_SEEDs       : t_integer_vector(0 to 1) := (26513879, 20136548);

  constant TB_FIFO1_SIZE              : natural := 65536;
  shared variable tb_fifo1            : t_integer_vector(0 to TB_FIFO1_SIZE-1);
  shared variable tb_fifo1_wr_addr    : natural := 0;
  shared variable tb_fifo1_rd_addr    : natural := 0;
  shared variable tb_fifo1_data_count : natural := 0;

  ------------------------------------------------------------------------------
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

  ------------------------------------------------------------------------------
  impure function randslv(
    min                                     : integer := 0;
    max                                     : integer := 1;
    size                                    : natural := 32) return std_logic_vector is

  begin
    return std_logic_vector( to_signed(randi(min, max), size));
  end function randslv;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  procedure write_to_fifo(
    value                                   : in  integer;
    success                                 : out boolean) is
  ------------------------------------------------------------------------------
  begin
    if (tb_fifo1_data_count < TB_FIFO1_SIZE) then
      tb_fifo1(tb_fifo1_wr_addr)    := value;
      success                       := true;

      tb_fifo1_wr_addr              := (tb_fifo1_wr_addr + 1) mod TB_FIFO1_SIZE;
      tb_fifo1_data_count           := tb_fifo1_data_count + 1;
    else
      success                       := false;
    end if;
  end procedure;

  ------------------------------------------------------------------------------
  procedure read_from_fifo(
    value                                   : out integer;
    success                                 : out boolean) is
  ------------------------------------------------------------------------------
  begin
    if (tb_fifo1_data_count > 0) then
      value                         := tb_fifo1(tb_fifo1_rd_addr);
      success                       := true;

      tb_fifo1_rd_addr              := (tb_fifo1_rd_addr + 1) mod TB_FIFO1_SIZE;
      tb_fifo1_data_count           := tb_fifo1_data_count - 1;
    else
      success                       := false;
    end if;
  end procedure;

  -- Signal declarations
  constant C_DATA_WIDTH       : natural := 8;
  constant C_FIFO_DEPTH_LOG2  : natural := 4;
  
  -- Signal declarations
  signal clk               : std_logic;
  signal rst               : std_logic;

  signal wr_en             : std_logic;
  signal rd_en             : std_logic;
  signal wr_data           : std_logic_vector(C_DATA_WIDTH-1 downto 0);
  signal rd_data           : std_logic_vector(C_DATA_WIDTH-1 downto 0);
  signal data_count        : std_logic_vector(C_FIFO_DEPTH_LOG2 downto 0);
  signal full              : std_logic;
  signal empty             : std_logic;
  
  signal tb_rd_ack         : std_logic;
  signal tb_err            : std_logic;
  signal tb_rd_data        : std_logic_vector(C_DATA_WIDTH-1 downto 0);
  -- tb ye ozel sinyal tanimlari
  constant CPERIOD            : time := 10 ns;

begin

  -- simulasyon icin clock ve reset uretimi
  process
  begin
    wait for CPERIOD/2;
    clk   <= '1';
    wait for CPERIOD/2;
    clk   <= '0';
  end process;

  process
  begin
    rst   <= '1';
    wait for CPERIOD*100;
    rst   <= '0';
    wait;
  end process;

  process
  begin
    wr_en     <= '0';
    wr_data   <= (others => '0');
    wait until falling_edge(rst);

    while (true) loop
      wait until rising_edge(clk);
      wait for CPERIOD/10;
      wr_en   <= '1';
      wr_data <= std_logic_vector(unsigned(wr_data) + 1);
      wait for CPERIOD;
      wr_en   <= '0';
      wait for CPERIOD*randi(0, 4);
    end loop;

    wait;
  end process;


  -- framer blogunun cektigi datalarÄ± daha sonradan kontrol amaciyla fifoya yazan process
  process(clk)
    variable write_status   : boolean;
  begin
    if (rising_edge(clk)) then
      if (wr_en = '1' and full = '0') then
        write_to_fifo(to_integer(unsigned(wr_data)), write_status);
      end if;
    end if;
  end process;

  uut : entity work.fifo
  generic map (
    C_IS_FWFT_MODE    => false,
    C_DATA_WIDTH      => C_DATA_WIDTH,
    C_FIFO_DEPTH_LOG2 => C_FIFO_DEPTH_LOG2
  )
  port map (
    clock             => clk,
    reset             => rst,
    wr_en             => wr_en,
    rd_en             => rd_en,
    wr_data           => wr_data,
    rd_data           => rd_data,
    data_count        => data_count,
    full              => full,
    empty             => empty
  );
  
  -- rd_en <= not empty;


  -- process(clk)
  -- begin
   -- if (rising_edge(clk)) then
      -- if (rd_en = '1' and empty = '0') then
        -- tb_rd_data    <= rd_data;
        
        -- if (unsigned(tb_rd_data)+1 = unsigned(rd_data)) then
          -- tb_err  <= '0';
        -- else
          -- tb_err  <= '1';
        -- end if;
      -- end if;
    -- end if;
  -- end process;
  
  process(clk)
  begin
    if (rising_edge(clk)) then
      tb_rd_ack <= rd_en and not empty;
    end if;
  end process;
  
  process(clk)
    variable read_value    : integer;
    variable read_status   : boolean;
  begin
    if (rising_edge(clk)) then
      if (tb_rd_ack = '1') then
        read_from_fifo(read_value, read_status);
        
        if (read_status) then
          if (unsigned(rd_data) = read_value) then
            tb_err  <= '0';
          else
            tb_err  <= '1';
          end if;
        else
          tb_err  <= '1';
        end if;
      end if;
    end if;
  end process;
  
  process
    variable v_rw_fact  : natural := 4;
  begin
    rd_en     <= '0';
    wait until falling_edge(rst);

    while (true) loop
      wait until rising_edge(clk);
      wait for CPERIOD/10;
      rd_en   <= '1';
      wait for CPERIOD;
      rd_en   <= '0';
      wait for CPERIOD*randi(0, v_rw_fact);
      
      if (full = '1') then
        v_rw_fact := 3;
      end if;
      if (empty = '1') then
        v_rw_fact := 6;
      end if;
    end loop;

    wait;
  end process;

end architecture tb;

