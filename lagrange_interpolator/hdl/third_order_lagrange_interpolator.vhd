
--------------------------------------------------------------------
--========== https://github.com/up-stairs/vhdl_ip_cores ==========--
--------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity third_order_lagrange_interpolator is
  generic (
    C_DATAW                 : natural range 18 downto 4 := 17;
    C_FIFO_DEPTH_LOG2       : natural range 18 downto 2 := 8
  );
  port(
    clock                   : in std_logic;
    reset                   : in std_logic;

    s_cfg_interp_rate       : in std_logic_vector(31 downto 0); -- unsigned, 1 bit integer, 31 bit fractional - [0.000:1.000]
    s_axi_data_rate_pulse   : out std_logic; -- indicates the input data rate to the user

    s_axi_data_tvalid       : in std_logic;
    s_axi_data_tready       : out std_logic;
    s_axi_data_tdata        : in std_logic_vector(C_DATAW-1 downto 0);
    -- s_axi_data_tuser        : in std_logic;

    m_axi_data_treq         : in std_logic; -- used to get required output data rate from the user
    m_axi_data_tdata        : out std_logic_vector(C_DATAW-1 downto 0);

    -- signal to control when to generate err outputs
    err_enable              : in std_logic;
    err_data_underrun       : out std_logic
  );
end third_order_lagrange_interpolator;

architecture rtl of third_order_lagrange_interpolator is

  constant C_MU_FRACW         : natural := 14;
  constant C_MU_DATAW         : natural := 18;
  constant C_MU_ACCW          : natural := s_cfg_interp_rate'length;

  signal interp_rate_reg      : unsigned(s_cfg_interp_rate'range);

  signal get_input_sample     : std_logic;
  signal fifo_empty           : std_logic;
  signal fifo_full            : std_logic;
  signal fifo_rd_data         : std_logic_vector(C_DATAW-1 downto 0);

  signal mu_acc_msb_sig       : std_logic;
  signal mu_acc               : unsigned(C_MU_ACCW-1 downto 0);
  signal mu_acc_sig           : unsigned(C_MU_ACCW-1 downto 0);
  signal mu_third             : std_logic_vector(C_MU_DATAW-1 downto 0);
  signal mu_third_delayed     : std_logic_vector(C_MU_DATAW-1 downto 0);
  signal mu_second            : std_logic_vector(C_MU_DATAW-1 downto 0);
  signal mu_second_delayed    : std_logic_vector(C_MU_DATAW-1 downto 0);
  signal mu_first             : std_logic_vector(C_MU_DATAW-1 downto 0);

  signal node_up_zero         : std_logic_vector(C_DATAW-1 downto 0);
  signal node_up_one          : std_logic_vector(C_DATAW-1 downto 0);
  signal node_up_two          : std_logic_vector(C_DATAW-1 downto 0);
  signal node_dn_zero         : std_logic_vector(C_DATAW-1 downto 0);
  signal node_dn_one          : std_logic_vector(C_DATAW-1 downto 0);
  signal node_dn_two          : std_logic_vector(C_DATAW-1 downto 0);

begin

  s_axi_data_rate_pulse   <= get_input_sample;

  s_axi_data_tready       <= not(fifo_full);

  get_input_sample        <= m_axi_data_treq and mu_acc_msb_sig;

  -- indicates that there is not enough data in the buffer
  err_data_underrun       <= err_enable and fifo_empty and get_input_sample;


  -- input buffer to temporarily store incoming samples
  i_sample_buffer : entity work.fifo
  generic map (
    C_IS_FWFT_MODE    => TRUE,
    C_DATA_WIDTH      => C_DATAW,
    C_FIFO_DEPTH_LOG2 => C_FIFO_DEPTH_LOG2
  )
  port map (
    clock             => clock,
    reset             => reset,
    wr_en             => s_axi_data_tvalid,
    rd_en             => get_input_sample,
    wr_data           => s_axi_data_tdata,
    rd_data           => fifo_rd_data,
    data_count        => open,
    full              => fifo_full,
    empty             => fifo_empty
  );

  -----------------------------------------------
  -- INPUT DATA PATH
  -----------------------------------------------
  
  -- the first block on the input data path
  i_mult_deriv_0 : entity work.mult_deriv
  generic map (
    C_DATAW                 => C_DATAW,
    C_COE                   => 1024
  )
  port map (
    clock                   => clock,
    reset                   => reset,
    sample_en               => get_input_sample,
    clock_en                => m_axi_data_treq,
    data_in                 => fifo_rd_data,
    data_out                => node_up_zero
  );

  -- the second block on the input data path
  i_mult_deriv_1 : entity work.mult_deriv
  generic map (
    C_DATAW                 => C_DATAW,
    C_COE                   => 512
  )
  port map (
    clock                   => clock,
    reset                   => reset,
    sample_en               => get_input_sample,
    clock_en                => m_axi_data_treq,
    data_in                 => node_up_zero,
    data_out                => node_up_one
  );

  -- the third block on the input data path
  i_mult_deriv_2 : entity work.mult_deriv
  generic map (
    C_DATAW                 => C_DATAW,
    C_COE                   => 341
  )
  port map (
    clock                   => clock,
    reset                   => reset,
    sample_en               => get_input_sample,
    clock_en                => m_axi_data_treq,
    data_in                 => node_up_one,
    data_out                => node_up_two
  );

  -----------------------------------------------
  -- MU PATH
  -----------------------------------------------
  -- register s_cfg_interp_rate to improve timing performance
  process(clock, reset)
  begin
    if reset = '1' then
      interp_rate_reg   <= (others => '0');
    elsif rising_edge(clock) then
      if s_cfg_interp_rate(C_MU_ACCW-1) = '1' then
        interp_rate_reg   <= (others => '0');
        interp_rate_reg(C_MU_ACCW-1)   <= '1';
      else  
        interp_rate_reg   <= unsigned(s_cfg_interp_rate);
    end if;
    end if;
  end process;
  
  -- mu accumulator, the MSB bit is used to request new input sample
  mu_acc_sig          <= mu_acc + interp_rate_reg;
  mu_acc_msb_sig      <= mu_acc_sig(C_MU_ACCW-1);

  -- the distribution of delayed versions of mu
  process(clock, reset)
    variable data_x_mult_v    : signed(C_MU_DATAW+C_DATAW-1 downto 0);
  begin
    if reset = '1' then
      mu_acc   <= (others => '0');
    elsif rising_edge(clock) then
      if (m_axi_data_treq = '1') then
        mu_acc            <= resize(mu_acc_sig(C_MU_ACCW-2 downto 0), C_MU_ACCW);

        mu_third          <= std_logic_vector(unsigned(mu_acc(C_MU_ACCW-2 downto C_MU_ACCW-C_MU_FRACW-1)) + to_unsigned(2**C_MU_FRACW, mu_third'length));
        mu_third_delayed  <= mu_third;
        mu_second         <= std_logic_vector(unsigned(mu_third_delayed) - to_unsigned(2**C_MU_FRACW, mu_third'length));
        mu_second_delayed <= mu_second;
        mu_first          <= std_logic_vector(unsigned(mu_second_delayed) - to_unsigned(2**C_MU_FRACW, mu_third'length));
      end if;
    end if;
  end process;

  -----------------------------------------------
  -- OUTPUT DATA PATH
  -----------------------------------------------
  -- the third block on the output data path
  i_mult_add_2 : entity work.mult_add
  generic map (
    C_DATAW             => C_DATAW,
    C_MU_DATAW          => C_MU_DATAW,
    C_MU_FRACW          => C_MU_FRACW,
    C_DATA_TO_ADD_SDELAY => 1,
    C_DATA_TO_ADD_CDELAY => 2
  )
  port map (
    clock                   => clock,
    reset                   => reset,
    sample_en               => get_input_sample,
    clock_en                => m_axi_data_treq,
    mu_in                   => mu_third,
    data_to_mult_in         => node_up_two,
    data_to_add_in          => node_up_one,
    data_out                => node_dn_two
  );

  -- the second block on the output data path
  i_mult_add_1 : entity work.mult_add
  generic map (
    C_DATAW             => C_DATAW,
    C_MU_DATAW          => C_MU_DATAW,
    C_MU_FRACW          => C_MU_FRACW,
    C_DATA_TO_ADD_SDELAY => 2,
    C_DATA_TO_ADD_CDELAY => 4
  )
  port map (
    clock                   => clock,
    reset                   => reset,
    sample_en               => get_input_sample,
    clock_en                => m_axi_data_treq,
    mu_in                   => mu_second,
    data_to_mult_in         => node_dn_two,
    data_to_add_in          => node_up_zero,
    data_out                => node_dn_one
  );

  -- the first block on the output data path
  i_mult_add_0 : entity work.mult_add
  generic map (
    C_DATAW             => C_DATAW,
    C_MU_DATAW          => C_MU_DATAW,
    C_MU_FRACW          => C_MU_FRACW,
    C_DATA_TO_ADD_SDELAY => 3,
    C_DATA_TO_ADD_CDELAY => 6
  )
  port map (
    clock                   => clock,
    reset                   => reset,
    sample_en               => get_input_sample,
    clock_en                => m_axi_data_treq,
    mu_in                   => mu_first,
    data_to_mult_in         => node_dn_one,
    data_to_add_in          => fifo_rd_data,
    data_out                => node_dn_zero
  );

  m_axi_data_tdata    <= node_dn_zero;

end rtl;
