--| |-----------------------------------------------------------| |
--| |-----------------------------------------------------------| |
--| |       _______           __      __      __          __    | |
--| |     /|   __  \        /|  |   /|  |   /|  \        /  |   | |
--| |    / |  |  \  \      / |  |  / |  |  / |   \      /   |   | |
--| |   |  |  |\  \  \    |  |  | |  |  | |  |    \    /    |   | |
--| |   |  |  | \  \  \   |  |  | |  |  | |  |     \  /     |   | |
--| |   |  |  |  \  \  \  |  |  |_|__|  | |  |      \/      |   | |
--| |   |  |  |   \  \  \ |  |          | |  |  |\      /|  |   | |
--| |   |  |  |   /  /  / |  |   ____   | |  |  | \    / |  |   | |
--| |   |  |  |  /  /  /  |  |  |__/ |  | |  |  |\ \  /| |  |   | |
--| |   |  |  | /  /  /   |  |  | |  |  | |  |  | \ \//| |  |   | |
--| |   |  |  |/  /  /    |  |  | |  |  | |  |  |  \|/ | |  |   | |
--| |   |  |  |__/  /     |  |  | |  |  | |  |  |      | |  |   | |
--| |   |  |_______/      |  |__| |  |__| |  |__|      | |__|   | |
--| |   |_/_______/       |_/__/  |_/__/  |_/__/       |_/__/   | |
--| |                                                           | |
--| |-----------------------------------------------------------| |
--| |=============-Developed by Dimitar H.Marinov-==============| |
--|_|-----------------------------------------------------------|_|
  
--IP: Parallel FIR Filter
--Version: V1 - Standalone 
--Fuctionality: Generic FIR filter
--IO Description
--  clk     : system clock = sampling clock
--  reset   : resets the M registes (buffers) and the P registers (delay line) of the DSP48 blocks 
--  enable  : acts as bypass switch - bypass(0), active(1) 
--  data_i  : data input (signed)
--  data_o  : data output (signed)
--
--Generics Description
--  FILTER_TAPS  : Specifies the amount of filter taps (multiplications)
--  INPUT_WIDTH  : Specifies the input width (8-25 bits)
--  COEFF_WIDTH  : Specifies the coefficient width (8-18 bits)
--  OUTPUT_WIDTH : Specifies the output width (8-43 bits)
--
--Finished on: 30.06.2019
--Notes: the DSP attribute is required to make use of the DSP slices efficiently
--------------------------------------------------------------------
--================= https://github.com/DHMarinov =================--
--------------------------------------------------------------------
  
  
  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
  
entity hbf_filter is
  generic (
    INPUT_WIDTH   : integer range 8 to 25 := 12;
    COEFF_WIDTH   : integer range 8 to 25 := 16
  );
  port ( 
    clk    : in STD_LOGIC;
    reset  : in STD_LOGIC;
    enable : in STD_LOGIC;
    data_i : in STD_LOGIC_VECTOR (INPUT_WIDTH-1 downto 0);
    data_o : out STD_LOGIC_VECTOR (COEFF_WIDTH+INPUT_WIDTH-1 downto 0)
  );
end hbf_filter;
  
architecture Behavioral of hbf_filter is
  
-- attribute use_dsp : string;
-- attribute use_dsp of Behavioral : architecture is "yes";
  
constant FILTER_TAPS : integer := 27;
constant MAC_WIDTH : integer := COEFF_WIDTH+INPUT_WIDTH;
  
type input_registers is array(0 to FILTER_TAPS-1) of signed(INPUT_WIDTH-1 downto 0);
signal areg_s  : input_registers := (others=>(others=>'0'));
  
type mult_registers is array(0 to FILTER_TAPS-1) of signed(INPUT_WIDTH+COEFF_WIDTH-1 downto 0);
signal mreg_s : mult_registers := (others=>(others=>'0'));
  
type dsp_registers is array(0 to FILTER_TAPS-1) of signed(MAC_WIDTH-1 downto 0);
signal preg_s : dsp_registers := (others=>(others=>'0'));
  
-- rrc filter with roll-off 0.25
-- divide the output by 15bits since the filter gain is set to 90dB
type coefficients is array (0 to FILTER_TAPS-1) of integer;
constant breg_s: coefficients :=( 
    30,      0,   -115,      0,
   309,      0,   -693,      0,
  1426,      0,  -3038,      0,
 10268,  16369,  10268,      0,
 -3038,      0,   1426,      0,
  -693,      0,    309,      0,
  -115,      0,     30
);
  
  
begin
  
  
data_o <= std_logic_vector(preg_s(0)(COEFF_WIDTH+INPUT_WIDTH-1 downto 0));         
        
  
process(clk)
  variable coe_v  : signed(COEFF_WIDTH-1 downto 0);
begin
  
if rising_edge(clk) then
  
    if (reset = '1') then
        for i in 0 to FILTER_TAPS-1 loop
            areg_s(i) <=(others=> '0');
            mreg_s(i) <=(others=> '0');
            preg_s(i) <=(others=> '0');
        end loop;
  
    else
      if (enable = '1') then 
        for i in 0 to FILTER_TAPS-1 loop
            areg_s(i) <= signed(data_i); 
            
            coe_v := to_signed(breg_s(i), COEFF_WIDTH);
        
            if (i < FILTER_TAPS-1) then
              if (breg_s(i) = 0) then
                mreg_s(i) <= resize(areg_s(i), mreg_s(i)'length);         
                preg_s(i) <= mreg_s(i) + preg_s(i+1);
              else
                mreg_s(i) <= areg_s(i)*coe_v;         
                preg_s(i) <= mreg_s(i) + preg_s(i+1);
              end if;
            elsif (i = FILTER_TAPS-1) then
              if (breg_s(i) = 0) then
                mreg_s(i) <= resize(areg_s(i), mreg_s(i)'length);  
                preg_s(i)<= mreg_s(i);
              else
                mreg_s(i) <= areg_s(i)*coe_v; 
                preg_s(i)<= mreg_s(i);
              end if;
            end if;
        end loop; 
      end if;
    end if;
      
end if;
end process;
  
end Behavioral;