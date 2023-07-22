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
USE IEEE.STD_LOGIC_SIGNED.ALL;
USE STD.TEXTIO.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY T_Decoder IS
END T_Decoder;
 
ARCHITECTURE behavior OF T_Decoder IS 
	constant	z						: integer := 45;
	constant	logZ					: integer := 6;
	constant	maxLogE					: integer := 11; -- logarithm of maximum number of edges
	constant	logTotE					: integer := 14; -- logarithm of total number of edges
	constant	maxLogV					: integer := 4; -- logarithm of maximum number of edges that a variable node is connected among the supported codes
	constant	maxLogC					: integer := 5; -- logarithm of maximum number of edges that a check node is connected among the supported codes
	constant	C						: integer := 10; -- number of supported codes
	constant	logC					: integer := 4; -- logarithm of number of supported codes
	constant	W						: integer := 6; -- llr width in number of bits
	
	type INT_ARRAY is array (0 to C-1) of integer;
	constant nb							: INT_ARRAY := (   45*360/z,  45*360/z,  45*360/z,  45*360/z,  45*360/z,  45*360/z,  45*360/z,  45*360/z,  45*360/z,  45*360/z);

	--Inputs
	signal clk : std_logic := '0';
	signal Pi : std_logic := '0';
	signal Vi : std_logic := '0';
	signal Di : std_logic_vector(W*z-1 downto 0) := (others => '0');
	signal CodeSel : std_logic_vector(logC-1 downto 0) := (others => '0');
	signal MaxIter : std_logic_vector(7 downto 0) := X"14";

	--Outputs
	signal Vo : std_logic;
	signal Ready : std_logic;
	signal Do : std_logic_vector(z-1 downto 0);
	signal IterCnt : std_logic_vector(7 downto 0);
	signal PacketParity : std_logic;
	
	--
 
BEGIN

	-- synthesis translate_off 	
	process(clk)
		file CodeWord			: text open READ_MODE is "MATLAB/y.txt";
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
					end if;
				end if;
			when 1 =>
				k := k + 1;
				if k <= nb(CodeTemp) then
					CodeSel <= conv_std_logic_vector(CodeTemp,logC);
					Pi <= '1';
					Vi <= '1';
					for i in z-1 downto 0 loop
						readline(CodeWord, LineRead);
						read(LineRead,LlrTemp);
						Di(W*(i+1)-1 downto W*i) <= conv_std_logic_vector(LlrTemp,W);
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
	uut: entity work.Decoder 
	generic map(
		z => z,
		logZ => logZ,
		maxLogE => maxLogE,
		logTotE => logTotE,
		maxLogV => maxLogV,
		maxLogC => maxLogC,
		C => C,
		logC => logC,
		W => W
	)
	PORT MAP (
		clk => clk,
		Ready => Ready,
		CodeSel => CodeSel,
		MaxIter => MaxIter,
		Pi => Pi,
		Vi => Vi,
		Di => Di,
		Vo => Vo,
		Do => Do,
		IterCnt => IterCnt,
		PacketParity => PacketParity
	);

	clk <= not clk after 5 ns;
	
	process(clk)
		file RESULT_FILE	: text open WRITE_MODE is "MATLAB/u_est.txt";		
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
