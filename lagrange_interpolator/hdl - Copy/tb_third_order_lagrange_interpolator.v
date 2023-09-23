library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity tb_third_order_lagrange_interpolator is
end entity tb_third_order_lagrange_interpolator;

architecture tb of tb_third_order_lagrange_interpolator is

  type t_integer_vector is array (integer range <>) of integer;
  shared variable DEFAULT_SEEDs       : t_integer_vector(0 to 1) := (26513879, 20136548);

  constant tb_third_order_lagrange_interpolator1_SIZE              : natural := 65536;
  shared variable tb_third_order_lagrange_interpolator1            : t_integer_vector(0 to tb_third_order_lagrange_interpolator1_SIZE-1);
  shared variable tb_third_order_lagrange_interpolator1_wr_addr    : natural := 0;
  shared variable tb_third_order_lagrange_interpolator1_rd_addr    : natural := 0;
  shared variable tb_third_order_lagrange_interpolator1_data_count : natural := 0;

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


  -- Signal declarations
  constant C_DATA_WIDTH       : natural := 18;
  constant C_FIFO_DEPTH_LOG2  : natural := 4;
  constant C_PHASE_INCR       : natural := 512;
  constant C_PHASE_LIMIT      : natural := 2**10;

  -- Signal declarations
  signal clk                    : std_logic;
  signal rst                    : std_logic;

  signal phase_generator        : unsigned(31 downto 0);
  signal generate_new_sample    : std_logic;

  signal clock_en               : std_logic;
  signal s_axi_data_rate_pulse  : std_logic;
  signal s_cfg_interp_rate      : std_logic_vector (31 downto 0) := X"21230760"; --std_logic_vector(to_unsigned(2**32-1, 32));
  signal s_axi_data_tvalid      : std_logic;
  signal s_axi_data_tready      : std_logic;
  signal s_axi_data_tdata       : std_logic_vector (C_DATA_WIDTH-1 downto 0);
  signal m_axi_data_treq        : std_logic;
  signal m_axi_data_tdata       : std_logic_vector (C_DATA_WIDTH-1 downto 0);
  signal err_enable             : std_logic;
  signal err_data_underrun      : std_logic;

  signal tb_rd_ack              : std_logic;
  signal tb_err                 : std_logic;
  signal tb_rd_data             : std_logic_vector(C_DATA_WIDTH-1 downto 0);
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

  -- process
  -- begin
    -- wr_en     <= '0';
    -- wr_data   <= (others => '0');
    -- wait until falling_edge(rst);

    -- while (true) loop
      -- wait until rising_edge(clk);
      -- wait for CPERIOD/10;
      -- wr_en   <= '1';
      -- wr_data <= std_logic_vector(unsigned(wr_data) + 1);
      -- wait for CPERIOD;
      -- wr_en   <= '0';
      -- wait for CPERIOD*randi(0, 4);
    -- end loop;

    -- wait;
  -- end process;

  process(clk)
    variable phase_generator_v      : unsigned(phase_generator'range);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        phase_generator       <= (others => '0');
        generate_new_sample   <= '0';
      else
        phase_generator_v   := phase_generator + C_PHASE_INCR;
        if phase_generator_v >= C_PHASE_LIMIT then
          phase_generator       <= phase_generator_v - C_PHASE_LIMIT;
          generate_new_sample   <= '1';
        else
          phase_generator       <= phase_generator_v;
          generate_new_sample   <= '0';
        end if;
      end if;
    end if;
  end process;

  -- framer blogunun cektigi datalarÄ± daha sonradan kontrol amaciyla fifoya yazan process
  process(clk)
    variable phase_incr_v       : real;
    variable phase_incr_2_v     : real;
    variable sine_v             : real;
    variable init_v             : natural;
  begin
    if (rising_edge(clk)) then
      s_axi_data_tvalid   <= '0';
      if rst = '1' then
        phase_incr_v    := 0.0;
        phase_incr_2_v  := 0.0;
        init_v          := 10;
      else
        if (s_axi_data_rate_pulse = '1' or init_v > 0) then
          phase_incr_v        := phase_incr_v + 0.07;
          phase_incr_2_v      := phase_incr_2_v + 0.1;
          sine_v              := sin(2*MATH_PI*phase_incr_v)*1000.0 + sin(2*MATH_PI*phase_incr_2_v)*1000.0;
          
          s_axi_data_tvalid   <= '1';
          s_axi_data_tdata    <= std_logic_vector(to_unsigned(integer(sine_v), C_DATA_WIDTH));
          
          init_v              := init_v - 1;
        end if;
      end if;
    end if;
  end process;
    
  dut : entity work.third_order_lagrange_interpolator
  generic map (
    C_DATAW           => C_DATA_WIDTH,
    C_FIFO_DEPTH_LOG2 => C_FIFO_DEPTH_LOG2
  )
  port map (
    clock                   => clk,
    reset                   => rst,
    s_cfg_interp_rate       => s_cfg_interp_rate,
    s_axi_data_rate_pulse   => s_axi_data_rate_pulse,
    s_axi_data_tvalid       => s_axi_data_tvalid,
    s_axi_data_tready       => s_axi_data_tready,
    s_axi_data_tdata        => s_axi_data_tdata,
    m_axi_data_treq         => '1',
    m_axi_data_tdata        => m_axi_data_tdata,
    err_enable              => '1',
    err_data_underrun       => err_data_underrun
  );


end architecture tb;

