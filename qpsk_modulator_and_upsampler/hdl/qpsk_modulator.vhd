
--------------------------------------------------------------------
--========== https://github.com/up-stairs/vhdl_ip_cores ==========--
--------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY qpsk_modulator IS
  GENERIC (
    SYMBOL_LEVEL            : NATURAL := 1000;
    BIT_ENCODING            : NATURAL := 0; -- 0 for gray encoding, 1 for natural order
    IQ_WIDTH                : NATURAL := 12
  );
  PORT(
    clock                   : IN STD_LOGIC;
    reset                   : IN STD_LOGIC;

    port_enable             : IN STD_LOGIC;

    s_axi_data_tvalid       : IN STD_LOGIC;
    s_axi_data_tdata        : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    
    m_axi_data_tvalid       : OUT STD_LOGIC;
    m_axi_data_treal        : OUT STD_LOGIC_VECTOR(IQ_WIDTH-1 DOWNTO 0);
    m_axi_data_timag        : OUT STD_LOGIC_VECTOR(IQ_WIDTH-1 DOWNTO 0)
  );
END qpsk_modulator;

ARCHITECTURE rtl OF qpsk_modulator IS

BEGIN

  PROCESS(clock)
  BEGIN
    IF RISING_EDGE(clock) THEN
      IF reset = '1' THEN
        m_axi_data_treal       <= (OTHERS => '0');
        m_axi_data_timag       <= (OTHERS => '0');
      ELSE
        IF port_enable = '1' AND s_axi_data_tvalid = '1' THEN
          IF BIT_ENCODING = 0 THEN
            CASE s_axi_data_tdata IS
              WHEN "00" =>
                m_axi_data_treal    <= STD_LOGIC_VECTOR(TO_SIGNED(+SYMBOL_LEVEL, IQ_WIDTH));
                m_axi_data_timag    <= STD_LOGIC_VECTOR(TO_SIGNED(+SYMBOL_LEVEL, IQ_WIDTH));
              WHEN "01" =>
                m_axi_data_treal    <= STD_LOGIC_VECTOR(TO_SIGNED(+SYMBOL_LEVEL, IQ_WIDTH));
                m_axi_data_timag    <= STD_LOGIC_VECTOR(TO_SIGNED(-SYMBOL_LEVEL, IQ_WIDTH));
              WHEN "10" =>
                m_axi_data_treal    <= STD_LOGIC_VECTOR(TO_SIGNED(-SYMBOL_LEVEL, IQ_WIDTH));
                m_axi_data_timag    <= STD_LOGIC_VECTOR(TO_SIGNED(+SYMBOL_LEVEL, IQ_WIDTH));
              WHEN OTHERS =>
                m_axi_data_treal    <= STD_LOGIC_VECTOR(TO_SIGNED(-SYMBOL_LEVEL, IQ_WIDTH));
                m_axi_data_timag    <= STD_LOGIC_VECTOR(TO_SIGNED(-SYMBOL_LEVEL, IQ_WIDTH));
            END CASE;
          ELSE
            CASE s_axi_data_tdata IS
              WHEN "00" =>
                m_axi_data_treal    <= STD_LOGIC_VECTOR(TO_SIGNED(+SYMBOL_LEVEL, IQ_WIDTH));
                m_axi_data_timag    <= STD_LOGIC_VECTOR(TO_SIGNED(+SYMBOL_LEVEL, IQ_WIDTH));
              WHEN "01" =>
                m_axi_data_treal    <= STD_LOGIC_VECTOR(TO_SIGNED(-SYMBOL_LEVEL, IQ_WIDTH));
                m_axi_data_timag    <= STD_LOGIC_VECTOR(TO_SIGNED(+SYMBOL_LEVEL, IQ_WIDTH));
              WHEN "10" =>
                m_axi_data_treal    <= STD_LOGIC_VECTOR(TO_SIGNED(-SYMBOL_LEVEL, IQ_WIDTH));
                m_axi_data_timag    <= STD_LOGIC_VECTOR(TO_SIGNED(-SYMBOL_LEVEL, IQ_WIDTH));
              WHEN OTHERS =>
                m_axi_data_treal    <= STD_LOGIC_VECTOR(TO_SIGNED(-SYMBOL_LEVEL, IQ_WIDTH));
                m_axi_data_timag    <= STD_LOGIC_VECTOR(TO_SIGNED(+SYMBOL_LEVEL, IQ_WIDTH));
            END CASE;
          END IF;
        END IF;
      END IF;
    END IF;
  END PROCESS;


  PROCESS(clock)
  BEGIN
    IF RISING_EDGE(clock) THEN
      m_axi_data_tvalid   <= port_enable AND s_axi_data_tvalid;
    END IF;
  END PROCESS;

END rtl;
