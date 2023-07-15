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

entity Barrel_Shifter is
	generic(
		z						: integer := 360;
		logZ					: integer := 9 --ceil(log2(z))
	);
	port(
		clk						: in  std_logic;
		
		Shift					: in  std_logic_vector(logZ-1 downto 0);
		
		Di						: in  std_logic_vector(z-1 downto 0);
		
		Do						: out std_logic_vector(z-1 downto 0)
	);
end Barrel_Shifter;

architecture Behavioral of Barrel_Shifter is
begin
	process(clk)
	begin
		if rising_edge(clk) then
			Do <= to_stdlogicvector(to_bitvector(Di) ror conv_integer(Shift));
		end if;
	end process;
end Behavioral;

