													--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   12:42:23 01/20/2011
-- Design Name:   
-- Module Name:   D:/WiMAX/I_S_E/WiMAX_DECODER/T_Decoder.vhd
-- Project Name:  wimax_encoder
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: Decoder
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
 
ENTITY T_Encoder IS
END T_Encoder;
 
ARCHITECTURE behavior OF T_Encoder IS 
	constant z		: integer := 60;
	constant logZ	: integer := 6;
	
	type INT_TYPE_A is array (0 to 5) of integer;
	constant mb								: INT_TYPE_A := (12, 8, 8, 6, 6, 4);
	constant kb								: INT_TYPE_A := (12,16,16,18,18,20);

	--Inputs
	signal clk : std_logic := '0';
	signal Pi : std_logic := '0';
	signal Vi : std_logic := '0';
	signal Di : std_logic_vector(z-1 downto 0) := (others => '0');
	signal CodeSel : std_logic_vector(2 downto 0) := (others => '0');

	--Outputs
	signal Vo : std_logic;
	signal Ready : std_logic;
	signal Do : std_logic_vector(z-1 downto 0);
	--
 
BEGIN

	-- synthesis translate_off 	
	process(clk)
		file CodeWord			: text open READ_MODE is "MATLAB/u.txt";
		file Codes				: text open READ_MODE is "MATLAB/codes.txt";
		
		variable LineRead 		: LINE;
		variable SysBit			: integer;
		variable i_CodeSel		: integer;
		
		variable State			: integer := 0;
		variable k				: integer := 0;
	begin
		if rising_edge(clk) then
			
			
			Pi <= '0';
			Vi <= '0';
			case State is
			when 0 =>
				k := 0;
				if Ready = '1' then
					if not endfile(Codes) then
						State := 1;
						readline(Codes, LineRead);
						read(LineRead,i_CodeSel);
					end if;
				end if;
			when 1 =>
				k := k + 1;
				if k <= kb(i_CodeSel) then
					CodeSel <= conv_std_logic_vector(i_CodeSel,3);
					Pi <= '1';
					Vi <= '1';
					for i in z-1 downto 0 loop
						readline(CodeWord, LineRead);
						read(LineRead,SysBit);
						Di(1*(i+1)-1 downto 1*i) <= conv_std_logic_vector(SysBit,1);
					end loop;
				else
					State := 0;
				end if;
			when others =>
			end case;
		end if;	
	end process;
	-- synthesis translate_on 	
	
	-- Instantiate the Unit Under Test (UUT)
	uut: entity work.Encoder 
	generic map(
		z 		=> z,
		logZ	=> logZ
	)
	PORT MAP (
		clk => clk,
		
		Ready => Ready,
		CodeSel => CodeSel,
		
		Pi => Pi,
		Vi => Vi,
		Di => Di,
		
		Po => open,
		Vo => Vo,
		Do => Do
	);

	clk <= not clk after 5 ns;
	
	process(clk)
		file RESULT_FILE	: text open WRITE_MODE is "MATLAB/c_hdl.txt";		
		variable LineWrite 	: LINE;
	begin
		if rising_edge(clk) then
			if Vo = '1' then
				for k in z-1 downto 0 loop
					if Do(k) = '0' then
						write(LineWrite, 0);
					else
						write(LineWrite, 1);
					end if;	
					writeLine(RESULT_FILE, LineWrite);								
				end loop;
			end if;
		end if;	
	end process;
END;
