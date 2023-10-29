
--------------------------------------------------------------------
--========== https://github.com/up-stairs/vhdl_ip_cores ==========--
--------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY upsample IS
  GENERIC (
    INPUT_WIDTH             : NATURAL := 12;
    UPSAMPLE_RATE           : NATURAL := 2;
    UPSAMPLE_GAP            : NATURAL := 4
  );
  PORT(
    clock                   : IN STD_LOGIC;
    reset                   : IN STD_LOGIC;

    s_axi_data_tvalid       : IN STD_LOGIC;
    s_axi_data_tdata        : IN STD_LOGIC_VECTOR(INPUT_WIDTH-1 DOWNTO 0);
    
    m_axi_data_tvalid       : OUT STD_LOGIC;
    m_axi_data_tdata        : OUT STD_LOGIC_VECTOR(INPUT_WIDTH-1 DOWNTO 0)
  );
END upsample;

ARCHITECTURE rtl OF upsample IS

  SIGNAL upsample_cntr      : NATURAL RANGE UPSAMPLE_RATE downto 0;
  SIGNAL upsample_gap_cntr  : NATURAL RANGE UPSAMPLE_GAP downto 0;

BEGIN

  PROCESS(clock)
  BEGIN
    IF RISING_EDGE(clock) THEN
      IF reset = '1' THEN
        upsample_cntr         <= 0;
        upsample_gap_cntr     <= 0;
      ELSE
        IF s_axi_data_tvalid = '1' THEN
          upsample_cntr         <= UPSAMPLE_RATE - 1;
          upsample_gap_cntr     <= UPSAMPLE_GAP-1;
        ELSE
          IF upsample_gap_cntr > 0 THEN
            upsample_gap_cntr     <= upsample_gap_cntr - 1;
          ELSE
            upsample_gap_cntr     <= UPSAMPLE_GAP-1;
            IF upsample_cntr > 0 THEN
              upsample_cntr         <= upsample_cntr - 1;
            END IF;
          END IF;
        END IF;
      END IF;
    END IF;
  END PROCESS;


  PROCESS(clock)
  BEGIN
    IF RISING_EDGE(clock) THEN
      m_axi_data_tvalid   <= '0';
      IF s_axi_data_tvalid = '1' THEN
        m_axi_data_tvalid   <= '1';
        m_axi_data_tdata    <= s_axi_data_tdata;
      ELSIF upsample_gap_cntr = 0 AND upsample_cntr > 0 THEN
        m_axi_data_tvalid   <= '1';
        m_axi_data_tdata    <= (others => '0');
      END IF;
    END IF;
  END PROCESS;

END rtl;
