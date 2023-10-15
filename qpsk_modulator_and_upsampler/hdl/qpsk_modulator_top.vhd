
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY qpsk_modulator_top IS
  GENERIC (
    SYMBOL_LEVEL            : NATURAL := 1000;
    IQ_WIDTH                : NATURAL := 12
  );
  PORT(
    clock                   : IN STD_LOGIC;
    reset                   : IN STD_LOGIC;

    port_enable             : IN STD_LOGIC; -- '1'
    port_symbol_rate        : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    port_output_stage       : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

    m_axi_real_tvalid       : OUT STD_LOGIC;
    m_axi_real_tdata        : OUT STD_LOGIC_VECTOR(IQ_WIDTH-1 DOWNTO 0);
    m_axi_imag_tvalid       : OUT STD_LOGIC;
    m_axi_imag_tdata        : OUT STD_LOGIC_VECTOR(IQ_WIDTH-1 DOWNTO 0)
  );
END qpsk_modulator_top;

ARCHITECTURE rtl OF qpsk_modulator_top IS

  SIGNAL rng_m_axi_data_tvalid       : STD_LOGIC;
  SIGNAL rng_m_axi_data_tdata        : STD_LOGIC_VECTOR(1 DOWNTO 0);

  SIGNAL qpsk_m_axi_data_tvalid      : STD_LOGIC;
  SIGNAL qpsk_m_axi_data_treal       : STD_LOGIC_VECTOR(IQ_WIDTH-1 DOWNTO 0);
  SIGNAL qpsk_m_axi_data_timag       : STD_LOGIC_VECTOR(IQ_WIDTH-1 DOWNTO 0);
    
BEGIN

  -- a random data generator for test purposes
  -- the symbol rate can be adjusted by port_symbol_rate according to the following formula
  --   effective_symbol_rate = frequency_of_clk / port_symbol_rate
  -- for example if want 2Mbps which is equivalent to 1Mbaud/sec (=2Mbps/(2 bits for each symbol)) and the clock frequency is 100Mhz;
  --   1e6 = 100e6 / port_symbol_rate
  --   port_symbol_rate = 100
  -- 
  -- 2Mbps bit rate, RFIC sample rate (which is adjusted by C drivers in Processor) is 16Msamples/sec and frequency of clock is 32Mhz (which is also adjusted by C drivers in Processor)
  -- 
  -- 1e6 = 32e6 / port_symbol_rate so port_symbol_rate <= 32
  -- 
  -- 2Mbps/2 = 1Msymbols/sec
  -- upsample by 16/1 = 16
  -- port_output_stage <= "11"
  -- 
  -- 4Mbps bit rate, RFIC sample rate (which is adjusted by C drivers in Processor) is 16Msamples/sec and frequency of clock is 32Mhz (which is also adjusted by C drivers in Processor)
  -- 4Mbps/2 = 2Msymbols/sec
  -- upsample by 16/2 = 8
  -- port_output_stage <= "10"
  --
  -- 2e6 = 32e6 / port_symbol_rate so port_symbol_rate <= 16
  
  comp_random_data_gen : ENTITY WORK.random_data_gen
  GENERIC MAP (
    PRBS_INIT               => "1100100011100001110111000111011"
  )
  PORT MAP (
    clock                   => clock,
    reset                   => reset,

    port_enable             => port_enable,
    port_symbol_rate        => port_symbol_rate,

    m_axi_data_tvalid       => rng_m_axi_data_tvalid,
    m_axi_data_tdata        => rng_m_axi_data_tdata
  );

  comp_qpsk_modulator : ENTITY WORK.qpsk_modulator
  GENERIC MAP (
    SYMBOL_LEVEL            => SYMBOL_LEVEL,
    BIT_ENCODING            => 0,
    IQ_WIDTH                => IQ_WIDTH
  )
  PORT MAP (
    clock                   => clock,
    reset                   => reset,

    port_enable             => port_enable,

    s_axi_data_tvalid       => rng_m_axi_data_tvalid,
    s_axi_data_tdata        => rng_m_axi_data_tdata,

    m_axi_data_tvalid       => qpsk_m_axi_data_tvalid,
    m_axi_data_treal        => qpsk_m_axi_data_treal, -- inphase
    m_axi_data_timag        => qpsk_m_axi_data_timag -- quadrature

  );
  
  -- upsampling filters
  comp_filters_imag : ENTITY WORK.filters
  GENERIC MAP (
    INPUT_WIDTH             => IQ_WIDTH
  )
  PORT MAP (
    clock                   => clock,
    reset                   => reset,

    port_output_stage       => port_output_stage, -- 0 => Upsamples by 2, 1 => Upsamples by 4, 2 => Upsamples by 8, 3 Upsamples by 16

    s_axi_data_tvalid       => qpsk_m_axi_data_tvalid,
    s_axi_data_tdata        => qpsk_m_axi_data_timag,

    m_axi_data_tvalid       => m_axi_imag_tvalid,
    m_axi_data_tdata        => m_axi_imag_tdata

  );
  
  comp_filters_real : ENTITY WORK.filters
  GENERIC MAP (
    INPUT_WIDTH             => IQ_WIDTH
  )
  PORT MAP (
    clock                   => clock,
    reset                   => reset,

    port_output_stage       => port_output_stage,

    s_axi_data_tvalid       => qpsk_m_axi_data_tvalid,
    s_axi_data_tdata        => qpsk_m_axi_data_treal,

    m_axi_data_tvalid       => m_axi_real_tvalid,
    m_axi_data_tdata        => m_axi_real_tdata

  );
  

END rtl;
