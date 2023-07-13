--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:12:34 08/19/2011
-- Design Name:   
-- Module Name:   H:/Issel/YNHK/WiMAX_LDPC/WiMAX_LDPC_ENCODER/T_Encoder_C_Top.vhd
-- Project Name:  WiMAX_LDPC
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: Encoder_C_Top
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE STD.TEXTIO.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY T_Encoder_C_Top IS
END T_Encoder_C_Top;
 
ARCHITECTURE behavior OF T_Encoder_C_Top IS 
    
	constant	z						: integer := 24;
	constant	logZ					: integer := 7; --ceil(log2(z))
		
	constant	nb						: integer := 24;
	constant	kb						: integer := 16;
	constant	mb						: integer := 8;

   --Inputs
   signal clk : std_logic := '0';
   signal Pi : std_logic := '0';
   signal Vi : std_logic := '0';
   signal Di : std_logic_vector(z-1 downto 0) := (others => '0');

 	--Outputs
   signal Ready : std_logic;
   signal Po : std_logic;
   signal Vo : std_logic;
   signal Do : std_logic_vector(z-1 downto 0);
   
    --Signals
   signal p_Ready : std_logic := '0';
   type ARRAY_TYPE is array (0 to 95) of std_logic_vector(15 downto 0);
   signal RNG : ARRAY_TYPE := (X"D789", X"D53A", X"41A6", X"9D0C", X"950E", X"8A6E", X"DEB4", X"43C9", X"516D", X"1E85", X"F099", X"A543", X"7ABE", X"A3AA", X"8B73", X"A5B6", 
X"8B3C", X"B897", X"85C2", X"FE63", X"37FB", X"1B16", X"1C15", X"1048", X"6793", X"72C9", X"5DA6", X"C375", X"A0BE", X"C5A1", X"EECF", X"F906", 
X"3129", X"238D", X"B23F", X"1805", X"8681", X"87C5", X"DC74", X"7C1F", X"64BA", X"ABE3", X"BDC3", X"8522", X"5904", X"2666", X"960A", X"431C", 
X"0B61", X"C143", X"3E27", X"7141", X"B013", X"5BF6", X"BC81", X"650C", X"AEF4", X"B43C", X"713B", X"0503", X"54B3", X"6CA0", X"4530", X"3272", 
X"D25C", X"6E0F", X"E345", X"6425", X"C4E5", X"6594", X"CEFB", X"C14D", X"609D", X"374D", X"CA58", X"F306", X"53DB", X"ABD8", X"704B", X"D560", 
X"C4D4", X"2AD1", X"DCAB", X"FD68", X"83B1", X"E260", X"9689", X"279E", X"332A", X"682E", X"BFAB", X"D359", X"CA3B", X"518B", X"88B8", X"1707");

BEGIN
	clk <= not clk after 500 ps;
	
	-- synthesis translate_off 	
	process(clk)
		variable k	: integer := 0;
		variable Temp : std_logic_vector(z-1 downto 0);
		
		file RESULT_FILE: text open WRITE_MODE is "MATLAB/iw.txt";		
		variable traceLine : LINE;
	begin
		if rising_edge(clk) then
			for i in 0 to 95 loop
				RNG(i) <= RNG(i)(14 downto 0) & (RNG(i)(15) xor RNG(i)(14) xor RNG(i)(12) xor RNG(i)(3) );
			end loop;
			
			p_Ready <= Ready;
			if p_Ready = '0' and Ready = '1' then
				k := 0;
			end if;
			
			Pi <= '0';
			Vi <= '0';
			if k < kb then
				Pi <= '1';
				Vi <= '1';
				for i in z-1 downto 0 loop
					Di(i) <= RNG(i)(14);
					
					if RNG(i)(14) = '0' then
						write(traceLine, 0);
					else
						write(traceLine, 1);
					end if;
					writeLine(RESULT_FILE, traceLine);	
				end loop;
			end if;
			k := k + 1;
		end if;
	end process;
	-- synthesis translate_on 	
	
	-- Instantiate the Unit Under Test (UUT)
   uut: entity work.Encoder_C_Top 
   generic map(
	   z => z,
	   logZ => logZ,
	   
	   nb => nb,
	   kb => kb,
	   mb => mb
   )
   PORT MAP (
          clk => clk,
          Ready => Ready,
          Pi => Pi,
          Vi => Vi,
          Di => Di,
          Po => Po,
          Vo => Vo,
          Do => Do
        );
	-- synthesis translate_off 	
	process(clk)
		file RESULT_FILE: text open WRITE_MODE is "MATLAB/cw.txt";		
		variable traceLine : LINE;
	begin
		if rising_edge(clk) then
			if Po = '1' and Vo = '1' then
				for i in z-1 downto 0 loop
					if Do(i) = '0' then
						write(traceLine, 0);
					else
						write(traceLine, 1);
					end if;
					writeLine(RESULT_FILE, traceLine);
				end loop;
			end if;
		end if;
	end process;
	-- synthesis translate_on 	
END;
