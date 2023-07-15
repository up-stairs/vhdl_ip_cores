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
	constant z		: integer := 180;
	constant logZ	: integer := 8;
	constant logC	: integer := 5;
	constant logA	: integer := 9;
	constant logMaE	: integer := 11;
	constant logToE	: integer := 14;
	
	constant S							: integer := 360/z;
	constant C							: integer := 21;--2**logC;
	
	type INT_VECTOR_A is array (0 to C-1) of integer;
	constant kb							: INT_VECTOR_A := (   9*S,  15*S,  18*S,  20*S,  27*S,  30*S,  33*S,  35*S,  37*S,  40*S,  45*S,  60*S,  72*S,  90*S, 108*S, 120*S, 135*S, 144*S, 150*S, 160*S, 162*S);
	constant mb							: INT_VECTOR_A := (  36*S,  30*S,  27*S,  25*S,  18*S,  15*S,  12*S,  10*S,   8*S,   5*S, 135*S, 120*S, 108*S,  90*S,  72*S,  60*S,  45*S,  36*S,  30*S,  20*S,  18*S);

	--Inputs
	signal clk : std_logic := '0';
	signal Pi : std_logic := '0';
	signal Vi : std_logic := '0';
	signal Di : std_logic_vector(z-1 downto 0) := (others => '0');
	signal CodeSel : std_logic_vector(logC-1 downto 0) := (others => '0');

	--Outputs
	signal Vo : std_logic;
	signal Ready : std_logic;
	signal Do : std_logic_vector(z-1 downto 0);
	--
 
BEGIN

	-- synthesis translate_off 	
	process(clk)
		file CodeWord			: text open READ_MODE is "MATLAB/u.txt";
		file CodeTypes			: text open READ_MODE is "MATLAB/codes.txt";
		variable LineRead 		: LINE;
		variable LlrTemp		: integer;
		variable CodeTemp		: integer;
		variable tmpstd			: std_logic_vector(1 downto 0);
		
		variable State			: integer := 0;
		variable k				: integer := 0;
		variable m				: integer := 0;
	begin
		if rising_edge(clk) then
			
			
			Pi <= '0';
			Vi <= '0';
			case State is
			when 0 =>
				k := 0;
				if Ready = '1' then
					if not endfile(CodeTypes) then
						State := 1;
						readline(CodeTypes, LineRead);
						read(LineRead,CodeTemp);
						CodeTemp := CodeTemp - 1;
					end if;
				end if;
			when 1 =>
				k := k + 1;
				if k <= kb(CodeTemp) then
					CodeSel <= conv_std_logic_vector(CodeTemp,logC);
					Pi <= '1';
					Vi <= '1';
					for i in z-1 downto 0 loop
						readline(CodeWord, LineRead);
						read(LineRead,LlrTemp);
						Di(1*(i+1)-1 downto 1*i) <= conv_std_logic_vector(LlrTemp,1);
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
		logZ	=> logZ,	
		logC	=> logC,	
		logA	=> logA,	
		logMaE  => logMaE,
		logToE  => logToE
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
