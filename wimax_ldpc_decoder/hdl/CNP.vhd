----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:21:38 09/07/2011 
-- Design Name: 
-- Module Name:    CNP_Combined - Behavioral 
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

entity CNP is
	generic(
		z						: integer := 24;
		W						: integer := 6
	);
	port(
		clk						: in  std_logic;
		
		Restart					: in  std_logic;
		
		LLRn					: in  std_logic;
		LLRi					: in  std_logic_vector(W*z-1 downto 0);
		HDi						: in  std_logic_vector(z-1 downto 0);
		
		PARv					: out std_logic;
		PARo					: out std_logic_vector(z-1 downto 0);
		
		LLRv					: out std_logic;
		LLRo					: out std_logic_vector(W*z-1 downto 0)
	);
end CNP;

architecture Behavioral of CNP is
	function MaxLLR (z : integer; DW : integer) return std_logic_vector is
		variable InitValue : std_logic_vector(z*DW-1 downto 0);
	begin
		for i in 0 to z-1 loop
			InitValue(DW*i+DW-1 downto DW*i) := conv_std_logic_vector(2**(DW-1)-1,DW);
		end loop;
		return InitValue;
	end MaxLLR;
	------------------------------------O------------------------------------
	constant MaxValue					: std_logic_vector(W-1 downto 0) := conv_std_logic_vector(+(2**(W-1))-1,W);
	constant MinValue					: std_logic_vector(W-1 downto 0) := conv_std_logic_vector(-(2**(W-1))-0,W);
	------------------------------------O------------------------------------
	type ARRAY_TYPE_A is array (0 to z-1) of std_logic_vector(31 downto 0);
	type ARRAY_TYPE_B is array (0 to z-1) of std_logic_vector(W-1 downto 0);
	type ARRAY_TYPE_C is array (0 to z-1) of unsigned(4 downto 0);
	type ARRAY_TYPE_D is array (0 to z-1) of std_logic;
	------------------------------------O------------------------------------
	signal InputSignArray				: ARRAY_TYPE_A := (others => (others => '0'));
	signal InputMin1Llr					: ARRAY_TYPE_B := (others => (MaxValue));
	signal InputMin2Llr					: ARRAY_TYPE_B := (others => (MaxValue));
	signal InputMin1Index				: ARRAY_TYPE_C := (others => (others => '0'));
	signal InputSignProd				: ARRAY_TYPE_D := (others => ('0'));
	signal InputParity					: ARRAY_TYPE_D := (others => ('0'));
	signal InputEdgeCntr				: unsigned(4 downto 0) := (others => '0');
	
	signal rRestart						: std_logic := '0';
	signal rrRestart					: std_logic := '0';
	signal rLLRn						: std_logic := '0';
	signal rHDi							: std_logic_vector(z-1 downto 0) := (others => '0');
	signal LlrSign						: std_logic_vector(z-1 downto 0) := (others => '0');
	
	signal LlrAbs						: ARRAY_TYPE_B := (others => (others => '0'));
	signal LastEdgeCnt					: unsigned(4 downto 0) := (others => '0');
	------------------------------------O------------------------------------
	signal State						: integer range 1 downto 0 := 0;

	signal OutputSignArray				: ARRAY_TYPE_A := (others => (others => '0'));
	signal OutputMin1Llr				: ARRAY_TYPE_B := (others => (MaxValue));
	signal OutputMin2Llr				: ARRAY_TYPE_B := (others => (MaxValue));
	signal OutputMin1Index				: ARRAY_TYPE_C := (others => (others => '0'));
	signal OutputSignProd				: ARRAY_TYPE_D := (others => ('0'));
	signal OutputParity					: ARRAY_TYPE_D := (others => ('0'));
	signal OutputEdgeCntr				: unsigned(4 downto 0) := (others => '0');
	
	signal tLLRv						: std_logic := '0';
	signal tPARv						: std_logic := '0';
	signal tPARo						: ARRAY_TYPE_D := (others => '0');
	signal tLLRo						: ARRAY_TYPE_B := (others => (others => '0'));
	------------------------------------O------------------------------------
begin
	input_processing : process(clk)
	begin
		if rising_edge(clk) then
			rRestart <= Restart;
			rrRestart <= rRestart;
			
			rLLRn <= LLRn;
			for i in 0 to z-1 loop
				if LLRi(W*(i+1)-1 downto W*i) = MinValue then
					LlrAbs(i) <= MaxValue;
				else
					LlrAbs(i) <= abs(LLRi(W*(i+1)-1 downto W*i));
				end if;
				LlrSign(i) <= LLRi(W*(i+1)-1);
			end loop;
			rHDi <= HDi;
			--------------------------------------------------------------------------------
			if rRestart = '1' then
				InputMin1Index <= (others => (others => '0'));
				InputMin2Llr <= (others => MaxValue);
				if rLLRn = '1' then
					for i in 0 to z-1 loop
						InputMin1Llr(i) <= LlrAbs(i);
						InputSignProd(i) <= LlrSign(i);
						InputSignArray(i)(0) <= LlrSign(i);
						InputParity(i) <= rHDi(i);
					end loop;
					InputEdgeCntr <= "00001";
				else
					for i in 0 to z-1 loop
						InputMin1Llr(i) <= MaxValue;
						InputSignProd(i) <= '0';
						InputParity(i) <= '0';
					end loop;
					InputEdgeCntr <= "00000";
				end if;
				
				OutputSignArray <= InputSignArray;
				OutputMin1Llr <= InputMin1Llr;
				OutputMin1Index <= InputMin1Index;
				OutputMin2Llr <= InputMin2Llr;
				OutputSignProd <= InputSignProd;
				OutputParity <= InputParity;
				LastEdgeCnt <= InputEdgeCntr;
			else
				if rLLRn = '1' then
					InputEdgeCntr <= InputEdgeCntr + '1';
					for i in 0 to z-1 loop
						InputSignProd(i) <= InputSignProd(i) xor LlrSign(i);
						InputSignArray(i)(conv_integer(InputEdgeCntr)) <= LlrSign(i);
						InputParity(i) <= InputParity(i) xor rHDi(i);
						
						if InputMin1Llr(i) > LlrAbs(i) then
							InputMin1Llr(i) <= LlrAbs(i);
							InputMin1Index(i) <= InputEdgeCntr;
							InputMin2Llr(i) <= InputMin1Llr(i);
						else
							if InputMin2Llr(i) > LlrAbs(i) then
								InputMin2Llr(i) <= LlrAbs(i);
							end if;
						end if;
					end loop;
				end if;
			end if;
		end if;
	end process;
	
	output_processing : process(clk)
	begin
		if rising_edge(clk) then
			tLLRv <= '0';
			tPARv <= '0';
			OutputEdgeCntr <= "00000";
			case State is
			when 0 =>
				if rrRestart = '1' then
					tLLRv <= '1';
					tPARv <= '1';
					
					OutputEdgeCntr <= OutputEdgeCntr + '1';
					State <= 1;
				end if;
			when 1 =>
				tLLRv <= '1';
				
				OutputEdgeCntr <= OutputEdgeCntr + '1';
				if rRestart = '0' then
					if OutputEdgeCntr = LastEdgeCnt-1 then
						OutputEdgeCntr <= "00000";
						State <= 0;
					end if;
				else
					OutputEdgeCntr <= "00000";
					State <= 0;
				end if;
			when others =>
			end case;
			
			for i in 0 to z-1 loop
				if OutputMin1Index(i)  = OutputEdgeCntr then
					if OutputSignProd(i) /= OutputSignArray(i)(conv_integer(OutputEdgeCntr)) then
						tLLRo(i) <= -OutputMin2Llr(i);
					else
						tLLRo(i) <= +OutputMin2Llr(i);
					end if;
				else
					if OutputSignProd(i) /= OutputSignArray(i)(conv_integer(OutputEdgeCntr)) then
						tLLRo(i) <= -OutputMin1Llr(i);
					else
						tLLRo(i) <= +OutputMin1Llr(i);
					end if;
				end if;
			end loop;
			tPARo <= OutputParity;
			--------------------------------------------
			LLRv <= tLLRv;
			PARv <= tPARv;
			for i in 0 to z-1 loop
				LLRo(W*(i+1)-1 downto W*i) <= tLLRo(i) - sxt(tLLRo(i)(W-1 downto 2),W);
				PARo(i) <= tPARo(i);
			end loop;
		end if;
	end process;
end Behavioral;