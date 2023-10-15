
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY filters IS
  GENERIC (
    INPUT_WIDTH             : NATURAL := 12
  );
  PORT(
    clock                   : IN STD_LOGIC;
    reset                   : IN STD_LOGIC;

    port_output_stage       : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

    s_axi_data_tvalid       : IN STD_LOGIC;
    s_axi_data_tdata        : IN STD_LOGIC_VECTOR(INPUT_WIDTH-1 DOWNTO 0);

    m_axi_data_tvalid       : OUT STD_LOGIC;
    m_axi_data_tdata        : OUT STD_LOGIC_VECTOR(INPUT_WIDTH-1 DOWNTO 0)
  );
END filters;

ARCHITECTURE rtl OF filters IS

  TYPE DATA_VECTOR_TYPE IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(INPUT_WIDTH-1 DOWNTO 0);

  CONSTANT COEFF_WIDTH              : natural := 16;

  SIGNAL upr_m_axi_data_tvalid      : STD_LOGIC;
  SIGNAL upr_m_axi_data_tdata       : STD_LOGIC_VECTOR(s_axi_data_tdata'RANGE);
  SIGNAL rrc_m_axi_data_tvalid      : STD_LOGIC;
  SIGNAL rrc_m_axi_data_tdata       : STD_LOGIC_VECTOR(COEFF_WIDTH+INPUT_WIDTH-1 DOWNTO 0);

  SIGNAL hbf_enable                 : STD_LOGIC_VECTOR(0 TO 3);
  SIGNAL hbf_s_axi_data_tvalid      : STD_LOGIC_VECTOR(0 TO 4);
  SIGNAL hbf_s_axi_data_tdata       : DATA_VECTOR_TYPE(0 TO 4);

BEGIN

  comp_upsample_pre_rrc : ENTITY WORK.upsample
  GENERIC MAP (
    INPUT_WIDTH             => s_axi_data_tdata'length,
    UPSAMPLE_RATE           => 2,
    UPSAMPLE_GAP            => 16
  )
  PORT MAP (
    clock                   => clock,
    reset                   => reset,

    s_axi_data_tvalid       => s_axi_data_tvalid,
    s_axi_data_tdata        => s_axi_data_tdata,

    m_axi_data_tvalid       => upr_m_axi_data_tvalid,
    m_axi_data_tdata        => upr_m_axi_data_tdata
  );

  comp_rrc : ENTITY WORK.rrc_filter
  GENERIC MAP (
    INPUT_WIDTH             => s_axi_data_tdata'length,
    COEFF_WIDTH             => COEFF_WIDTH
  )
  PORT MAP (
    clk           => clock,
    reset         => reset,

    enable        => upr_m_axi_data_tvalid,
    data_i        => upr_m_axi_data_tdata,

    data_o        => rrc_m_axi_data_tdata
  );

  PROCESS(clock)
  BEGIN
    IF RISING_EDGE(clock) THEN
      hbf_s_axi_data_tvalid(0)  <= upr_m_axi_data_tvalid;
      hbf_s_axi_data_tdata(0)   <= rrc_m_axi_data_tdata(25 downto 14);

      FOR f IN hbf_enable'RANGE LOOP
        IF f <= unsigned(port_output_stage) THEN
          hbf_enable(f) <= '1';
        ELSE
          hbf_enable(f) <= '0';
        END IF;
      END LOOP;
    END IF;
  END PROCESS;

  gen_hbf : FOR g IN hbf_enable'RANGE GENERATE
    SIGNAL s_valid : STD_LOGIC;
    SIGNAL s_data  : STD_LOGIC_VECTOR(INPUT_WIDTH-1 DOWNTO 0);
    SIGNAL upr_m_valid : STD_LOGIC;
    SIGNAL upr_m_data  : STD_LOGIC_VECTOR(INPUT_WIDTH-1 DOWNTO 0);
    SIGNAL hbf_m_valid : STD_LOGIC;
    SIGNAL hbf_m_data  : STD_LOGIC_VECTOR(COEFF_WIDTH+INPUT_WIDTH-1 DOWNTO 0);
  BEGIN

    s_valid                   <= hbf_s_axi_data_tvalid(g) and hbf_enable(g);
    s_data                    <= hbf_s_axi_data_tdata(g);

    comp_upsample_pre_rrc : ENTITY WORK.upsample
    GENERIC MAP (
      INPUT_WIDTH             => s_axi_data_tdata'length,
      UPSAMPLE_RATE           => 2,
    UPSAMPLE_GAP              => 8 / 2**g
    )
    PORT MAP (
      clock                   => clock,
      reset                   => reset,

      s_axi_data_tvalid       => s_valid,
      s_axi_data_tdata        => s_data,

      m_axi_data_tvalid       => upr_m_valid,
      m_axi_data_tdata        => upr_m_data
    );

    comp_hbf : ENTITY WORK.hbf_filter
    GENERIC MAP (
      INPUT_WIDTH             => s_axi_data_tdata'length,
      COEFF_WIDTH             => COEFF_WIDTH
    )
    PORT MAP (
      clk                     => clock,
      reset                   => reset,

      enable                  => upr_m_valid,
      data_i                  => upr_m_data,

      data_o                  => hbf_m_data
    );

    hbf_s_axi_data_tvalid(g+1)  <= upr_m_valid;
    hbf_s_axi_data_tdata(g+1)   <= hbf_m_data(25 DOWNTO 14);
  END GENERATE;


  PROCESS(clock)
    VARIABLE stg  : NATURAL;
  BEGIN
    IF (RISING_EDGE(clock)) THEN
      stg     := conv_integer(unsigned(port_output_stage));

      m_axi_data_tvalid               <= hbf_s_axi_data_tvalid(stg);
      m_axi_data_tdata                <= hbf_s_axi_data_tdata(stg);
    END IF;
  END PROCESS;
  -- PROCESS(clock)
  -- BEGIN
    -- IF (RISING_EDGE(clock)) THEN
      -- m_axi_data_tvalid               <= rrc_m_axi_data_tvalid;
      -- m_axi_data_tdata                <= rrc_m_axi_data_tdata(25 downto 14);
    -- END IF;
  -- END PROCESS;

END rtl;
