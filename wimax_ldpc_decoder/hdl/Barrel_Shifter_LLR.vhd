		----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:17:31 12/02/2010 
-- Design Name: 
-- Module Name:    Barrel_Shifter - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE STD.TEXTIO.ALL;

entity Barrel_Shifter_LLR is
	generic(
		z						: integer := 96;
		W						: integer := 8 --ceil(log2(z))
	);
	port(
		clk						: in  std_logic;
		
		Shift					: in  std_logic_vector(6 downto 0);
		
		Di						: in  std_logic_vector(z*W-1 downto 0);
		
		Do						: out std_logic_vector(z*W-1 downto 0)
	);
end Barrel_Shifter_LLR;

architecture Behavioral of Barrel_Shifter_LLR is
	type bit_vect_type is array (0 to W-1) of bit_vector(z-1 downto 0);
begin
	process(clk)
		variable DIN_BIT,DOUT_BIT: bit_vect_type;
	begin
		if rising_edge(clk) then
			for i in 0 to W-1 loop
				for j in 0 to z-1 loop
					DIN_BIT(i)(j) := to_bit(Di(j*W+i));
				end loop;
			end loop;

			for i in 0 to W-1 loop
				DOUT_BIT(i) := DIN_BIT(i) ror conv_integer(Shift);
			end loop;

			for i in 0 to W-1 loop
				for j in 0 to z-1 loop
					Do(j*W+i downto j*W+i) <= to_stdlogicvector(DOUT_BIT(i)(j downto j));
				end loop;
			end loop;
		end if;
	end process;
end Behavioral;

