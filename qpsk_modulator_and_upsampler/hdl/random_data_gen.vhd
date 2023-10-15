
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY random_data_gen IS
  GENERIC (
    PRBS_INIT               : STD_LOGIC_VECTOR(1 TO 31)
  );
  PORT(
    clock                   : IN STD_LOGIC;
    reset                   : IN STD_LOGIC;

    port_enable             : IN STD_LOGIC;
    port_symbol_rate        : IN STD_LOGIC_VECTOR(11 DOWNTO 0);

    m_axi_data_tvalid       : OUT STD_LOGIC;
    m_axi_data_tdata        : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
  );
END random_data_gen;

ARCHITECTURE rtl OF random_data_gen IS

  SIGNAL phase_generator            : UNSIGNED(port_symbol_rate'RANGE);
  SIGNAL generate_new_sample        : STD_LOGIC;

  SIGNAL prbs_poly                  : STD_LOGIC_VECTOR(PRBS_INIT'RANGE);
  SIGNAL prbs_data                  : STD_LOGIC_VECTOR(1 DOWNTO 0);

BEGIN

  PROCESS(clock)
    VARIABLE phase_generator_v      : UNSIGNED(phase_generator'RANGE);
  BEGIN
    IF RISING_EDGE(clock) THEN
      IF reset = '1' THEN
        phase_generator       <= (OTHERS => '0');
        generate_new_sample   <= '0';
      ELSE
        IF port_enable = '1' THEN
          phase_generator_v   := phase_generator + 1;
          IF phase_generator_v >= UNSIGNED(port_symbol_rate) THEN
            phase_generator       <= (OTHERS => '0');
            generate_new_sample   <= '1';
          ELSE
            phase_generator       <= phase_generator_v;
            generate_new_sample   <= '0';
          END IF;
        ELSE
          generate_new_sample   <= '0';
        END IF;
      END IF;
    END IF;
  END PROCESS;

  PROCESS(clock)
    VARIABLE prbs_poly_v        : STD_LOGIC_VECTOR(prbs_poly'RANGE);
    VARIABLE bit1_v             : STD_LOGIC;
  BEGIN
    IF RISING_EDGE(clock) THEN
      IF reset = '1' THEN
        prbs_poly   <= PRBS_INIT;
        prbs_data   <= (others => '0');
      ELSE
        IF generate_new_sample = '1' THEN
          prbs_poly_v   := prbs_poly;
          FOR idx IN m_axi_data_tdata'RANGE LOOP
            bit1_v  := prbs_poly_v(28) xor prbs_poly_v(31);
            prbs_poly_v := bit1_v & prbs_poly_v(1 TO 30);
            prbs_data(idx)  <= prbs_poly_v(31);
          END LOOP;
          prbs_poly   <= prbs_poly_v;
        END IF;
      END IF;
    END IF;
  END PROCESS;


  PROCESS(clock)
  BEGIN
    IF RISING_EDGE(clock) THEN
      m_axi_data_tvalid   <= generate_new_sample;
      m_axi_data_tdata    <= prbs_data;
    END IF;
  END PROCESS;

END rtl;
