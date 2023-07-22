		----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:16:13 01/17/2011 
-- Design Name: 
-- Module Name:    VNP_Top - Behavioral 
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

entity VNP_Top is
	generic(
		z						: integer := 45;
		logZ					: integer := 6;
		maxLogE					: integer := 11;
		maxLogV					: integer := 4;
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
		
		Finished				: out std_logic;
		
		LM_WrEn					: out std_logic;
		LM_WrAddr				: out std_logic_vector(maxLogE-1 downto 0);
		LM_Di					: out std_logic_vector(W*z-1 downto 0);
		HDM_Di					: out std_logic_vector(1*z-1 downto 0);
		ROTo					: out std_logic_vector(logZ-1 downto 0)
	);
end VNP_Top;

architecture Behavioral of VNP_Top is
	------------------------------------O------------------------------------
	type INT_ARRAY is array (0 to C-1) of integer;
	constant EDGE_CNT					: INT_ARRAY := ( 135*360/z, 150*360/z, 162*360/z, 135*360/z, 198*360/z, 150*360/z, 132*360/z, 125*360/z, 137*360/z, 135*360/z);
	constant START_ADDR					: INT_ARRAY := (   0, 1440, 3000, 4656, 6096, 8040, 9600, 11016, 12376, 13832);
	constant END_ADDR					: INT_ARRAY := (1440, 3000, 4656, 6096, 8040, 9600, 11016, 12376, 13832, 15272);
	constant SPECIAL_INDEX				: INT_ARRAY := (   3,   4,   5,   4,  10,   9,   9,  11,  15,  26);
	------------------------------------O------------------------------------
	signal VIM_RdAddr					: std_logic_vector(logTotE-1 downto 0) := (others => '0');
	signal VIM_Do						: std_logic_vector(maxLogE downto 0);
	------------------------------------O------------------------------------
	signal VIVA_State					: integer range 1 downto 0 := 0;
	signal VIVA_Cntr					: std_logic_vector(maxLogE-1 downto 0) := (others => '0');
	signal rLM_RdEn						: std_logic;
	------------------------------------O------------------------------------
	signal VNP_LLRv						: std_logic;
	signal VNP_Restart					: std_logic_vector(1 downto 0) := (others => '0');
	signal VNP_HDo						: std_logic_vector(1*z-1 downto 0);
	signal VNP_LLRo						: std_logic_vector(W*z-1 downto 0);
	------------------------------------O------------------------------------
	signal rFinished					: std_logic := '0';
	signal VNVA_Cntr					: std_logic_vector(maxLogE-1 downto 0) := (others => '0');
	------------------------------------O------------------------------------
	signal VOM_RdAddr					: std_logic_vector(logTotE-1 downto 0) := (others => '0');
	signal VOM_Do						: std_logic_vector(maxLogE+logZ-1 downto 0);
	------------------------------------O------------------------------------
	signal iLM_Di						: std_logic_vector(W*z-1 downto 0);
	signal iHDM_Di						: std_logic_vector(1*z-1 downto 0);
	------------------------------------O------------------------------------
begin
	VNP_Input_Memory : entity work.VNP_Input_Edge_Memory 
	PORT MAP(
		clk => clk,
		
		RdAddr => VIM_RdAddr,
		Do => VIM_Do
	);
	------------------------------------O------------------------------------
	------------------------------------O------------------------------------
	------------------------------------O------------------------------------
	VIM_VNP_Adaptor : process(clk)
	begin
		if rising_edge(clk) then
			--------------------------------------------------------------------------------
			rLM_RdEn <= '0';
			VIVA_Cntr <= (others => '0');
			case VIVA_State is
			when 0 =>
				if Start = '1' then
					rLM_RdEn <= '1';
					VIVA_State <= 1;
				end if;
			when 1 =>
				rLM_RdEn <= '1';
				VIVA_Cntr <= VIVA_Cntr + '1';
				if VIM_RdAddr = END_ADDR(conv_integer(CodeSel))-2 then
					VIVA_State <= 0;
				end if;
			when others =>
			end case;
			--------------------------------------------------------------------------------
			LM_RdEn <= rLM_RdEn;
			VNP_Restart <= VNP_Restart(0 downto 0) & VIM_Do(maxLogE);
			--------------------------------------------------------------------------------
			if rst = '1' then
				VIVA_Cntr <= (others => '0');
				VIVA_State <= 0;
			end if;
		end if;
	end process;
	VIM_RdAddr <= conv_std_logic_vector(START_ADDR(conv_integer(CodeSel)), logTotE) + VIVA_Cntr;
	
	
	LM_RdAddr <= VIM_Do(maxLogE-1 downto 0);
	------------------------------------O------------------------------------
	------------------------------------O------------------------------------
	------------------------------------O------------------------------------
	Variable_Node_Processor : entity work.VNP
	generic map(
		z => z,
		maxLogV => maxLogV,
		W => W
	)
	port map(
		clk => clk,
		
		Restart => VNP_Restart(1),
		
		LLRn => LM_Dv,
		LLRi => LM_Do,
		
		LLRv => VNP_LLRv,
		LLRo => VNP_LLRo,
		HDo => VNP_HDo
	);
	------------------------------------O------------------------------------
	------------------------------------O------------------------------------
	------------------------------------O------------------------------------
	VNP_VOM_Adaptor : process(clk)
	begin
		if rising_edge(clk) then
			LM_WrEn <= VNP_LLRv;
			iLM_Di <= VNP_LLRo;
			iHDM_Di <= VNP_HDo;
	
			if Start = '1' or rst = '1' then
				VNVA_Cntr <= (others => '0');
			elsif VNP_LLRv = '1' then
				VNVA_Cntr <= VNVA_Cntr + '1';
			end if;
			
			rFinished <= '0';
			if VOM_RdAddr = END_ADDR(conv_integer(CodeSel))-1 then
				rFinished <= '1';
			end if;
			Finished <= rFinished;
		end if;
	end process;
	VOM_RdAddr <= conv_std_logic_vector(START_ADDR(conv_integer(CodeSel)), logTotE) + VNVA_Cntr;
	------------------------------------O------------------------------------
	------------------------------------O------------------------------------
	------------------------------------O------------------------------------
	VNP_Output_Memory : entity work.VNP_Output_Edge_Memory
	PORT MAP(
		clk => clk,
		
		RdAddr => VOM_RdAddr,
		Do => VOM_Do
	);
	LM_WrAddr <= VOM_Do(maxLogE-1 downto 0);
	ROTo <= VOM_Do(logZ-1+maxLogE downto maxLogE);
	
	LM_Di(W-1 downto 0) <= 	iLM_Di(W-1 downto 0) when VOM_Do(maxLogE-1 downto 0) /= conv_std_logic_vector(SPECIAL_INDEX(conv_integer(CodeSel)),maxLogE) else 
							conv_std_logic_vector((2**(W-1))-1,W);
	LM_Di(W*z-1 downto W) <=	iLM_Di(W*z-1 downto W);
	
	
	HDM_Di(0) <= 	iHDM_Di(0) when VOM_Do(maxLogE-1 downto 0) /= conv_std_logic_vector(SPECIAL_INDEX(conv_integer(CodeSel)),maxLogE) else 
					'0';
	HDM_Di(z-1 downto 1) <=	iHDM_Di(z-1 downto 1);
end Behavioral;

