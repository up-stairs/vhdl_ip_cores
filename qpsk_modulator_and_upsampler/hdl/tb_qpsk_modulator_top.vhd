library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity tb_qpsk_modulator_top is
end entity tb_qpsk_modulator_top;

architecture tb of tb_qpsk_modulator_top is

  -- Signal declarations
  constant IQ_WIDTH        : natural := 12;

  -- Signal declarations
  signal clk               : std_logic;
  signal rst               : std_logic;

  signal port_symbol_rate  : std_logic_vector(11 downto 0) := std_logic_vector(to_unsigned(32, 12));
  signal port_output_stage : std_logic_vector(1 downto 0) := std_logic_vector(to_unsigned(3, 2));

  signal m_axi_real_tvalid : STD_LOGIC;
  signal m_axi_real_tdata  : STD_LOGIC_VECTOR(IQ_WIDTH-1 DOWNTO 0);
  signal m_axi_imag_tvalid : STD_LOGIC;
  signal m_axi_imag_tdata  : STD_LOGIC_VECTOR(IQ_WIDTH-1 DOWNTO 0);
  -- tb ye ozel sinyal tanimlari
  constant CPERIOD            : time := 31.25 ns; -- 32MHz ref clock

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

  uut : entity work.qpsk_modulator_top
  generic map (
    SYMBOL_LEVEL            => 1000,
    IQ_WIDTH                => IQ_WIDTH
  )
  port map (
    clock                   => clk,
    reset                   => rst,

    port_enable             => '1',
    port_symbol_rate        => port_symbol_rate,
    port_output_stage       => port_output_stage,

    m_axi_real_tvalid       => m_axi_real_tvalid,
    m_axi_real_tdata        => m_axi_real_tdata,
    m_axi_imag_tvalid       => m_axi_imag_tvalid,
    m_axi_imag_tdata        => m_axi_imag_tdata
  );


end architecture tb;

