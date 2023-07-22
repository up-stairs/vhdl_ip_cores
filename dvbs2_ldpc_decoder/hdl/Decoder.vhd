----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:52:42 01/19/2011 
-- Design Name: 
-- Module Name:    Decoder - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
-- yaklasik delay in CC = (EdgeCnt(CodeSel)*2+45*360/z+35)*IterCnt+45*360/z+4
entity Decoder is
	generic(
		z						: integer := 45;
		logZ					: integer := 6;
		maxLogE					: integer := 11; -- logarithm of maximum number of edges
		logTotE					: integer := 14; -- logarithm of total number of edges
		maxLogV					: integer := 4; -- logarithm of maximum number of edges that a variable node is connected among the supported codes
		maxLogC					: integer := 5; -- logarithm of maximum number of edges that a check node is connected among the supported codes
		C						: integer := 10; -- number of supported codes
		logC					: integer := 4; -- logarithm of number of supported codes
		W						: integer := 8 -- llr width in number of bits
	);
	port(
		clk						: in  std_logic;
		
		CodeSel					: in  std_logic_vector(logC-1 downto 0);
		MaxIter					: in  std_logic_vector(7 downto 0);
		
		Ready					: out std_logic;
		Pi						: in  std_logic;
		Vi						: in  std_logic;
		Di						: in  std_logic_vector(W*z-1 downto 0);
		
		Vo						: out std_logic;
		Do						: out std_logic_vector(z-1 downto 0);
		PacketParity			: out std_logic;
		IterCnt					: out std_logic_vector(7 downto 0)
	);
end Decoder;

architecture Behavioral of Decoder is
	------------------------------------O------------------------------------
	type INT_ARRAY is array (0 to C-1) of integer;
	constant EdgeCnt					: INT_ARRAY := ( 135*360/z, 150*360/z, 162*360/z, 135*360/z, 198*360/z, 150*360/z, 132*360/z, 125*360/z, 137*360/z, 135*360/z);
	constant kb							: INT_ARRAY := (   9*360/z,  15*360/z,  18*360/z,  20*360/z,  27*360/z,  30*360/z,  33*360/z,  35*360/z,  37*360/z,  40*360/z);
	------------------------------------O------------------------------------
	signal StateIn						: integer range 3 downto 0 := 0;
	signal StateOut						: integer range 3 downto 0 := 0;
	signal ProcSel						: std_logic := '0';
	signal FirstIter					: std_logic := '0';
	
	signal CntrIn						: std_logic_vector(maxLogE-1 downto 0) := conv_std_logic_vector(0,maxLogE);
	signal CntrOut						: std_logic_vector(maxLogE-1 downto 0) := conv_std_logic_vector(0,maxLogE);
	signal IterCntr						: std_logic_vector(7 downto 0) := conv_std_logic_vector(1,8);
	
	signal rLM_WrEnVNP					: std_logic := '0';
	signal rLM_WrAddrVNP				: std_logic_vector(maxLogE-1 downto 0) := (others => '0');
	signal rLM_WrEnCNP					: std_logic := '0';
	signal rLM_WrAddrCNP				: std_logic_vector(maxLogE-1 downto 0) := (others => '0');
	
	signal r_CodeSel					: std_logic_vector(logC-1 downto 0) := (others => '0');
	signal i_CodeSel					: std_logic_vector(logC-1 downto 0) := (others => '0');
	
	signal r_Pi							: std_logic := '0';
	signal r_Vi							: std_logic := '0';
	signal r_Di							: std_logic_vector(W*z-1 downto 0) := (others => '0');
	------------------------------------O------------------------------------
	signal VNP_Start					: std_logic := '0';
	signal VNP_Finished					: std_logic := '0';
	
	signal LM_DvVNP						: std_logic := '0';
	signal LM_RdEnVNP					: std_logic := '0';
	signal LM_RdAddrVNP					: std_logic_vector(maxLogE-1 downto 0) := (others => '0');
	signal LM_DisAddr					: std_logic_vector(maxLogE-1 downto 0) := (others => '0');
	
	signal LM_WrEnVNP					: std_logic := '0';
	signal LM_WrAddrVNP					: std_logic_vector(maxLogE-1 downto 0) := (others => '0');
	signal ROToVNP						: std_logic_vector(logZ-1 downto 0) := (others => '0');
	signal LM_DiVNP						: std_logic_vector(W*z-1 downto 0) := (others => '0');
	signal HDM_DiVNP					: std_logic_vector(z-1 downto 0) := (others => '0');
	------------------------------------O------------------------------------
	signal CNP_Start					: std_logic := '0';
	signal CNP_Finished					: std_logic := '0';
	signal ParityCheck					: std_logic := '0';
	
	signal LM_DvCNP						: std_logic := '0';
	signal LM_RdEnCNP					: std_logic := '0';
	signal LM_RdAddrCNP					: std_logic_vector(maxLogE-1 downto 0) := (others => '0');
	
	signal LM_WrEnCNP					: std_logic := '0';
	signal LM_WrAddrCNP					: std_logic_vector(maxLogE-1 downto 0) := (others => '0');
	signal ROToCNP						: std_logic_vector(logZ-1 downto 0) := (others => '0');
	signal LM_DiCNP						: std_logic_vector(W*z-1 downto 0) := (others => '0');
	------------------------------------O------------------------------------
	signal LM_WrDis						: std_logic := '0';
	signal LM_WrEn						: std_logic := '0';
	signal LM_RdEn						: std_logic := '0';
	signal LM_Dv						: std_logic := '0';
	signal LM_WrAddr					: std_logic_vector(maxLogE-1 downto 0) := (others => '0');
	signal LM_RdAddr					: std_logic_vector(maxLogE-1 downto 0) := (others => '0');
	signal LM_Di						: std_logic_vector(W*z-1 downto 0) := (others => '0');
	signal LM_Do						: std_logic_vector(W*z-1 downto 0) := (others => '0');
	------------------------------------O------------------------------------
	signal HDM_RdEn						: std_logic := '0';
	signal HDM_RdAddr					: std_logic_vector(maxLogE-1 downto 0) := (others => '0');
	signal HDM_Di						: std_logic_vector(z-1 downto 0) := (others => '0');
	signal HDM_Do						: std_logic_vector(z-1 downto 0) := (others => '0');
	------------------------------------O------------------------------------
	signal BSL_Shift					: std_logic_vector(logZ-1 downto 0) := (others => '0');
	signal BSL_Di						: std_logic_vector(W*z-1 downto 0) := (others => '0');
	signal BSL_Do						: std_logic_vector(W*z-1 downto 0) := (others => '0');
	------------------------------------O------------------------------------

begin
	CNP_VNP_Control : process(clk)
	begin
		if rising_edge(clk) then
			r_Pi <= Pi;
			r_Vi <= Vi;
			r_Di <= Di;
			r_CodeSel <= CodeSel;
			
			VNP_Start <= '0';
			CNP_Start <= '0';
			Ready <= '0';
			case StateIn is
			when 0 =>
				Ready <= '1';
				FirstIter <= '1';
				
				IterCntr <= conv_std_logic_vector(1,8);
				if Pi = '1' then
					if Vi = '1' then
						CntrIn <= conv_std_logic_vector(EdgeCnt(conv_integer(CodeSel)),maxLogE);
					else
						CntrIn <= conv_std_logic_vector(EdgeCnt(conv_integer(CodeSel))-1,maxLogE);
					end if;
					StateIn <= 1;
				end if;
			when 1 =>
				FirstIter <= '1';
				if Pi = '1' then
					if Vi = '1' then
						CntrIn <= CntrIn + '1';
					end if;
				else -- llr'larin tamami alinamasa bile dekoder aldigi paketi cozmeye calisacaktir
					if r_CodeSel >= C then -- check if the selected codeword is valid
						i_CodeSel <= (others => '0');
					else
						i_CodeSel <= r_CodeSel;
					end if;
					VNP_Start <= '1';
					StateIn <= 2;
				end if;
			when 2 =>
				if CNP_Finished = '1' then
					ProcSel <= '0';
					IterCntr <= IterCntr + '1';
					if ParityCheck = '1' or IterCntr = MaxIter then
						IterCnt <= IterCntr;
						StateIn <= 0;
					else
						VNP_Start <= '1';
					end if;
				elsif VNP_Finished = '1' then
					ProcSel <= '1';
					CNP_Start <= '1';
					FirstIter <= '0';
				end if;
			when others =>
			end case;
			----------------------------------------------------------------------------
			rLM_WrEnVNP <= LM_WrEnVNP;
			rLM_WrAddrVNP <= LM_WrAddrVNP;
			rLM_WrEnCNP <= LM_WrEnCNP;
			rLM_WrAddrCNP <= LM_WrAddrCNP;
		end if;
	end process;
	------------
	LM_RdEn 	<= LM_RdEnVNP 		when ProcSel = '0' else 
				   LM_RdEnCNP;
	LM_RdAddr 	<= LM_RdAddrVNP 	when ProcSel = '0' else 
				   LM_RdAddrCNP;
	------------
	LM_DvVNP 	<= LM_Dv 			when ProcSel = '0' else '0';
	LM_DvCNP 	<= LM_Dv 			when ProcSel = '1' else '0';
	------------
	LM_WrDis	<= not r_Pi;
	LM_WrEn 	<= r_Vi				when r_Pi = '1'  else
				   rLM_WrEnVNP 		when r_Pi = '0' and ProcSel = '0' else 
				   rLM_WrEnCNP;
	LM_WrAddr 	<= CntrIn			when r_Pi = '1'  else
				   rLM_WrAddrVNP 	when r_Pi = '0' and ProcSel = '0' else 
				   rLM_WrAddrCNP;
	LM_Di		<= r_Di				when r_Pi = '1' else BSL_Do;
	------------
	HDM_RdAddr 	<= LM_RdAddrCNP		when HDM_RdEn = '0' else CntrOut;
	
	Do			<= HDM_Do;
	------------
	BSL_Di 		<= LM_DiVNP 		when ProcSel = '0' else LM_DiCNP;
	BSL_Shift 	<= ROToVNP 			when ProcSel = '0' else ROToCNP;
	------------
	Variable_Node_Processing : entity work.VNP_Top
	generic map(
		z => z,
		logZ => logZ,
		maxLogE => maxLogE,
		logTotE => logTotE,
		maxLogV => maxLogV,
		C => C,
		logC => logC,
		W => W
	)
	port map(
		clk => clk,
		rst => r_Pi,
		
		CodeSel => i_CodeSel,
		Start => VNP_Start,
		
		LM_RdEn => LM_RdEnVNP,
		LM_RdAddr => LM_RdAddrVNP,
		
		LM_Dv => LM_DvVNP,
		LM_Do => LM_Do,
		
		Finished => VNP_Finished,
		
		LM_WrEn => LM_WrEnVNP,
		LM_WrAddr => LM_WrAddrVNP,
		LM_Di => LM_DiVNP,
		HDM_Di => HDM_DiVNP,
		ROTo => ROToVNP
	);
	
	Check_Node_Processing : entity work.CNP_Top
	generic map(
		z => z,
		logZ => logZ,
		maxLogE => maxLogE,
		logTotE => logTotE,
		maxLogC => maxLogC,
		C => C,
		logC => logC,
		W => W
	)
	port map(
		clk => clk,
		rst => r_Pi,
		
		CodeSel => i_CodeSel,
		Start => CNP_Start,
		
		LM_RdEn => LM_RdEnCNP,
		LM_RdAddr => LM_RdAddrCNP,
		
		LM_Dv => LM_DvCNP,
		LM_Do => LM_Do,
		HDM_Do => HDM_Do,
		
		Finished => CNP_Finished,
		
		ParityCheck => ParityCheck,
		
		LM_WrEn => LM_WrEnCNP,
		LM_WrAddr => LM_WrAddrCNP,
		LM_Di => LM_DiCNP,
		ROTo => ROToCNP
	);

	LM_DisAddr <= conv_std_logic_vector(EdgeCnt(conv_integer(i_CodeSel)), maxLogE);
	
	LLR_Memory : entity work.LLR_MEM
	generic map(
		z => z,
		maxLogE => maxLogE,
		W => W
	)
	port map(
		clk => clk,
		
		WrDis => LM_WrDis,
		WrDisAddr => LM_DisAddr,
		WrEn => LM_WrEn,
		WrAddr => LM_WrAddr,
		Din => LM_Di,
		
		RdDis => FirstIter,
		RdDisAddr => LM_DisAddr,
		RdEn => LM_RdEn,
		RdAddr => LM_RdAddr,
		Dval => LM_Dv,
		Dout => LM_Do
	);
	
	Hard_Decision_Memory: entity work.HD_MEM
	generic map(
		z => z,
		maxLogE => maxLogE
	)
	port map(
		clk => clk,
		
		WrEn => rLM_WrEnVNP,
		WrAddr => rLM_WrAddrVNP,
		Din => HDM_Di,
		
		RdEn => HDM_RdEn,
		RdAddr => HDM_RdAddr,
		Dout => HDM_Do,
		
		Dval => Vo
	);
	Output_Decisions : process(clk)
	begin
		if rising_edge(clk) then
			HDM_RdEn <= '0';
			CntrOut <= conv_std_logic_vector(EdgeCnt(conv_integer(i_CodeSel)),maxLogE);
			case StateOut is
			when 0 =>
				if CNP_Finished = '1' and (ParityCheck = '1' or IterCntr = MaxIter) then
					HDM_RdEn <= '1';
					PacketParity <= ParityCheck;
					StateOut <= 1;
				end if;
			when 1 =>
				HDM_RdEn <= '1';
				
				CntrOut <= CntrOut + '1';
				if CntrOut = EdgeCnt(conv_integer(i_CodeSel))+kb(conv_integer(i_CodeSel))-2 then
					StateOut <= 0;
				end if;
			when others =>
			end case;
		end if;
	end process;
	
	
	Barrel_Shifter_for_LLR: entity work.Barrel_Shifter_LLR 
	generic map(
		z => z,
		logZ => logZ,
		W => W
	)
	port map(
		clk => clk,
		Shift => BSL_Shift,
		Di => BSL_Di,
		Do => BSL_Do
	);
	
	Barrel_Shifter_for_Hard_Decisions : entity work.Barrel_Shifter
	generic map(
		z => z,
		logZ => logZ
	)
	port map(
		clk => clk,
		Shift => ROToVNP,
		Di => HDM_DiVNP,
		Do => HDM_Di
	);
end Behavioral;

