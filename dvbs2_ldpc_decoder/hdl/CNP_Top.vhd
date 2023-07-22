			----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:16:13 01/17/2011 
-- Design Name: 
-- Module Name:    CNP_Top - Behavioral 
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

entity CNP_Top is
	generic(
		z						: integer := 45;
		logZ					: integer := 6;
		maxLogE					: integer := 11;
		maxLogC					: integer := 5;
		logTotE					: integer := 14;
		logC					: integer := 4;
		C						: integer := 10; -- number of supported codes
		W						: integer := 6
	);
	port(
		clk						: in  std_logic;
		rst						: in  std_logic;
		
		Start					: in  std_logic;
		
		CodeSel					: in  std_logic_vector(logC-1 downto 0);
		
		LM_RdEn					: out std_logic;
		LM_RdAddr				: out std_logic_vector(maxLogE-1 downto 0);
		
		LM_Dv					: in  std_logic;
		LM_Do					: in  std_logic_vector(W*z-1 downto 0);
		HDM_Do					: in  std_logic_vector(1*z-1 downto 0);
		
		Finished				: out std_logic;
		
		ParityCheck				: out std_logic;
		
		LM_WrEn					: out std_logic;
		LM_WrAddr				: out std_logic_vector(maxLogE-1 downto 0);
		LM_Di					: out std_logic_vector(W*z-1 downto 0);
		ROTo					: out std_logic_vector(logZ-1 downto 0)
	);
end CNP_Top;

architecture Behavioral of CNP_Top is
	------------------------------------O------------------------------------
	type INT_ARRAY is array (0 to C-1) of integer;
	constant EDGE_CNT					: INT_ARRAY := ( 135*360/z, 150*360/z, 162*360/z, 135*360/z, 198*360/z, 150*360/z, 132*360/z, 125*360/z, 137*360/z, 135*360/z);
	constant START_ADDR					: INT_ARRAY := (   0, 1080, 2280, 3576, 4656, 6240, 7440, 8496, 9496, 10592);
	constant END_ADDR					: INT_ARRAY := (1080, 2280, 3576, 4656, 6240, 7440, 8496, 9496, 10592, 11672);
	constant SPECIAL_INDEX				: INT_ARRAY := (   3,   4,   5,   4,  10,   9,   9,  11,  15,  26);
	------------------------------------O------------------------------------
	signal CIM_RdAddr					: std_logic_vector(logTotE-1 downto 0) := (others => '0');
	signal CIM_Do						: std_logic_vector(maxLogE downto 0);
	------------------------------------O------------------------------------
	signal CICA_State					: integer range 1 downto 0 := 0;
	signal CICA_Cntr					: std_logic_vector(maxLogE-1 downto 0) := (others => '0');
	signal rLM_RdEn						: std_logic;
	------------------------------------O------------------------------------
	signal CNP_PARv						: std_logic := '0';
	signal CNP_LLRv						: std_logic := '0';
	signal CNP_Restart					: std_logic_vector(1 downto 0) := (others => '0');
	signal CNP_PARo						: std_logic_vector(z-1 downto 0) := (others => '0');
	signal CNP_LLRo						: std_logic_vector(W*z-1 downto 0) := (others => '0');
	------------------------------------O------------------------------------
	signal iParityCheck					: std_logic := '0';
	------------------------------------O------------------------------------
	signal rFinished					: std_logic := '0';
	signal CNCA_Cntr					: std_logic_vector(maxLogE-1 downto 0) := (others => '0');
	------------------------------------O------------------------------------
	signal COM_RdAddr					: std_logic_vector(logTotE-1 downto 0) := (others => '0');
	signal COM_Do						: std_logic_vector(maxLogE+logZ-1 downto 0);
	------------------------------------O------------------------------------
	signal iLM_Di						: std_logic_vector(W*z-1 downto 0);
	------------------------------------O------------------------------------
begin
	CNP_Input_Memory : entity work.CNP_Input_Edge_Memory PORT MAP(
		clk => clk,
		
		RdAddr => CIM_RdAddr,
		Do => CIM_Do
	);
	------------------------------------O------------------------------------
	------------------------------------O------------------------------------
	------------------------------------O------------------------------------
	CIM_CNP_Adaptor : process(clk)
	begin
		if rising_edge(clk) then
			--------------------------------------------------------------------------------
			rLM_RdEn <= '0';
			CICA_Cntr <= (others => '0');
			case CICA_State is
			when 0 =>
				if Start = '1' then
					rLM_RdEn <= '1';
					CICA_State <= 1;
				end if;
			when 1 =>
				rLM_RdEn <= '1';
				CICA_Cntr <= CICA_Cntr + '1';
				if CIM_RdAddr = END_ADDR(conv_integer(CodeSel))-2 then
					CICA_State <= 0;
				end if;
			when others =>
			end case;
			--------------------------------------------------------------------------------
			LM_RdEn <= rLM_RdEn;
			CNP_Restart <= CNP_Restart(0 downto 0) & CIM_Do(maxLogE);
			--------------------------------------------------------------------------------
			if rst = '1' then
				CICA_Cntr <= (others => '0');
				CICA_State <= 0;
			end if;
		end if;
	end process;
	CIM_RdAddr <= conv_std_logic_vector(START_ADDR(conv_integer(CodeSel)), logTotE) + CICA_Cntr;
	
	
	LM_RdAddr <= CIM_Do(maxLogE-1 downto 0);
	------------------------------------O------------------------------------
	------------------------------------O------------------------------------
	------------------------------------O------------------------------------
	Check_Node_Processors : entity work.CNP
	generic map(
		z => z,
		maxLogC => maxLogC,
		W => W
	)
	port map(
		clk => clk,
		
		Restart => CNP_Restart(1),
		
		LLRn => LM_Dv,
		LLRi => LM_Do,
		HDi => HDM_Do,
		
		PARv => CNP_PARv,
		PARo => CNP_PARo,
		
		LLRv => CNP_LLRv,
		LLRo => CNP_LLRo
	);
	------------------------------------O------------------------------------
	------------------------------------O------------------------------------
	------------------------------------O------------------------------------
	parity_check_control : process(clk)
	begin
		if rising_edge(clk) then
			if Start = '1' then
				iParityCheck <= '1';
			elsif CNP_PARv = '1' then
				if iParityCheck = '1' and CNP_PARo /= 0 then
					iParityCheck <= '0';
				end if;
			end if;
		end if;
	end process;
	ParityCheck <= iParityCheck;
	------------------------------------O------------------------------------
	------------------------------------O------------------------------------
	------------------------------------O------------------------------------
	CNP_COM_Adaptor : process(clk)
	begin
		if rising_edge(clk) then
			if Start = '1' or rst = '1' then
				CNCA_Cntr <= (others => '0');
			elsif CNP_LLRv = '1' then
				CNCA_Cntr <= CNCA_Cntr + '1';
			end if;
			
			rFinished <= '0';
			if COM_RdAddr = END_ADDR(conv_integer(CodeSel))-1 then
				rFinished <= '1';
			end if;
			------------------------------
			Finished <= rFinished;
			LM_WrEn <= CNP_LLRv;
			iLM_Di <= CNP_LLRo;
		end if;
	end process;
	COM_RdAddr <= conv_std_logic_vector(START_ADDR(conv_integer(CodeSel)), logTotE) + CNCA_Cntr;
	------------------------------------O------------------------------------
	------------------------------------O------------------------------------
	------------------------------------O------------------------------------
	CNP_Output_Memory : entity work.CNP_Output_Edge_Memory
	PORT MAP(
		clk => clk,
		
		RdAddr => COM_RdAddr,
		Do => COM_Do
	);
	LM_WrAddr <= COM_Do(maxLogE-1 downto 0);
	ROTo <= COM_Do(logZ-1+maxLogE downto maxLogE);
	
	LM_Di(W*z-1 downto W*(z-1)) <= 	iLM_Di(W*z-1 downto W*(z-1)) when COM_Do(maxLogE-1 downto 0) /= conv_std_logic_vector(SPECIAL_INDEX(conv_integer(CodeSel)),maxLogE) else 
									conv_std_logic_vector(0,W);
	LM_Di(W*(z-1)-1 downto 0) <=	iLM_Di(W*(z-1)-1 downto 0);
end Behavioral;

