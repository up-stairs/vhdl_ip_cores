		----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:46:26 01/11/2011 
-- Design Name: 
-- Module Name:    VNP - Behavioral 
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
USE IEEE.STD_LOGIC_SIGNED.ALL;
USE STD.TEXTIO.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity VNP is
	generic(
		z						: integer := 45;
		maxLogV					: integer := 4;
		W						: integer := 6
	);
	port(
		clk						: in  std_logic;
		
		Restart					: in  std_logic;
		
		LLRn					: in  std_logic;
		LLRi					: in  std_logic_vector(W*z-1 downto 0);
		
		HDo						: out std_logic_vector(z-1 downto 0);
		LLRv					: out std_logic;
		LLRo					: out std_logic_vector(W*z-1 downto 0)
	);
end VNP;

architecture Behavioral of VNP is
	------------------------------------O------------------------------------
	type ARRAY_TYPE_A is array (0 to z-1) of std_logic_vector(W-1+maxLogV downto 0);
	------------------------------------O------------------------------------
	signal LF_Do						: std_logic_vector(W*z-1 downto 0) := (others => '0');
	signal LF_RdEn						: std_logic := '0';
	------------------------------------O------------------------------------
	signal LlrSum						: ARRAY_TYPE_A := (others => (others => '0'));
	signal LastLlrSum					: ARRAY_TYPE_A := (others => (others => '0'));
	
	signal EdgeCntr1					: unsigned(maxLogV-1 downto 0) := (others => '0');
	signal EdgeCntr2					: unsigned(maxLogV-1 downto 0) := (others => '0');
	
	signal LastHD						: std_logic_vector(z-1 downto 0) := (others => '0');
	------------------------------------O------------------------------------
	signal tHDo							: std_logic_vector(z-1 downto 0) := (others => '0');
	signal tLLRv						: std_logic := '0';
	signal tLLRo						: ARRAY_TYPE_A := (others => (others => '0'));
	------------------------------------O------------------------------------
--	attribute USE_DSP48					: string;
--	attribute USE_DSP48 of LlrSum : signal is "yes";
	------------------------------------O------------------------------------
begin
	LLR_Fifo: entity work.vnp_input_fifo 
	generic map(
		z => z,
		maxLogV => maxLogV,
		W => W
	)
	PORT MAP(
		clk => clk,
		WrEn => LLRn,
		Din => LLRi,
		RdEn => LF_RdEn,
		Dout => LF_Do
	);
	
	process(clk)
	begin
		if rising_edge(clk) then
			if Restart = '1' then
				if LLRn = '1' then
					for i in 0 to z-1 loop
						LlrSum(i) <= sxt(LLRi(W*(i+1)-1 downto W*i),W+maxLogV);
					end loop;
					EdgeCntr1 <= conv_unsigned(1,maxLogV);
				else
					LlrSum <= (others => (others => '0'));
					EdgeCntr1 <= conv_unsigned(0,maxLogV);
				end if;
			else
				if LLRn = '1' then
					for i in 0 to z-1 loop
						LlrSum(i) <= LlrSum(i) + LLRi(W*(i+1)-1 downto W*i);
					end loop;
					EdgeCntr1 <= EdgeCntr1 + '1';
				end if;
			end if;
			--------------------------------------------------------------------------------
			LF_RdEn <= '0';
			if Restart = '1' then
				for i in 0 to z-1 loop
					LastLlrSum(i) <= LlrSum(i);
					LastHD(i) <= LlrSum(i)(W-1+maxLogV);
				end loop;
				EdgeCntr2 <= EdgeCntr1;
				LF_RdEn <= '1';
			else
				if EdgeCntr2 /= 0 then
					EdgeCntr2 <= EdgeCntr2 - '1';
				end if;
				if EdgeCntr2 /= 0 and EdgeCntr2 /= 1 then
					LF_RdEn <= '1';
				end if;
			end if;
			
			tLLRv <= '0';
			if EdgeCntr2 /= 0 then
				tLLRv <= '1';
			end if;
			tHDo <= LastHD;
			for i in 0 to z-1 loop
				tLLRo(i) <= LastLlrSum(i) - LF_Do(W*(i+1)-1 downto W*i);
			end loop;
			--------------------------------------------------------------------------------
			HDo <= tHDo;
			LLRv <= tLLRv;
			for i in 0 to z-1 loop
				LLRo(W*(i+1)-1 downto W*i) <= tLLRo(i)(W-1 downto 0);
				if tLLRo(i)(W-1+maxLogV downto W-1) > 0 then
					LLRo(W*(i+1)-1 downto W*i) <= conv_std_logic_vector(+(2**(W-1))-1,W);
				elsif tLLRo(i)(W-1+maxLogV downto W-1) < -1 then
					LLRo(W*(i+1)-1 downto W*i) <= conv_std_logic_vector(-(2**(W-1))+1,W);
				end if;
			end loop;
			--------------------------------------------------------------------------------
		end if;
	end process;
end Behavioral;