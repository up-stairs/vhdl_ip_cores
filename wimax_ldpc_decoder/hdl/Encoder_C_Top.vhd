----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:24:00 12/01/2010 
-- Design Name: 
-- Module Name:    Encoder_C_Top - Behavioral 
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

entity Encoder_C_Top is
	generic(
		z						: integer := 96;
		sz						: integer := 7; --ceil(log2(z))
		kb						: integer := 12
	);
	port(
		clk						: in std_logic;
		
		Pi						: in  std_logic;
		Vi						: in  std_logic;
		Di						: in  std_logic_vector(z-1 downto 0);
		
		Po						: out std_logic;
		Vo						: out std_logic;
		Do						: out std_logic_vector(z-1 downto 0)
	);
end Encoder_C_Top;

architecture Behavioral of Encoder_C_Top is
	------------------------------------O------------------------------------
	constant mb							: integer := 24-kb;
	constant hbm_0						: integer := 7*z/96;
	constant hbm_5						: integer := 0*z/96; --unpaired shift value for rate 1/2
	------------------------------------O------------------------------------
	type TYPE_RAM_1 is array (kb-1 downto 0) of std_logic_vector(z-1 downto 0);
	signal U							: TYPE_RAM_1 := (others => (others=> '0'));
	
	signal U_WrAddr						: std_logic_vector(3 downto 0) := (others => '0'); --max kb = 20 in the standard
	
	signal u_j							: std_logic_vector(z-1 downto 0) := (others => '0');
	signal BS_Di						: std_logic_vector(z-1 downto 0) := (others => '0');
	signal BS_Do						: std_logic_vector(z-1 downto 0) := (others => '0');
	------------------------------------O------------------------------------
	type TYPE_RAM_2 is array (mb-1 downto 0) of std_logic_vector(z-1 downto 0); -- ilk mb-1 indeksi summation kaydetmek icin kullaniliyor. Son indeks koddaki bi hatanin uzerini kapatmak icin kullaniliyor
	signal SumTerm						: TYPE_RAM_2 := (others => (others=> '0'));
	
	signal SumTermWrEn					: std_logic := '0';
	signal SumTermWrAddr				: integer range 15 downto 0 := 1; --max mb = 12 in the standard
	signal SumTermRdAddr				: integer range 15 downto 0 := 0; --max mb = 12 in the standard
	
	signal v_0							: std_logic_vector(z-1 downto 0) := (others => '0');
	signal SumTermRdData							: std_logic_vector(z-1 downto 0) := (others => '0');
	------------------------------------O------------------------------------
	type TYPE_ROM is array (0 to 50) of std_logic_vector(11 downto 0); -- 63 yapmakla 50 yapmak arasinda lut kaybi olmuyor
	constant Hbm1						: TYPE_ROM := ( -- for z = 24
											X"5E1", X"492", X"378", X"D39", 
											X"1B1", X"165", X"4F6", X"097", X"8CB", 
											X"183", X"164", X"515", X"217", X"80B", 
											X"3D0", X"2F2", X"418", X"999", 
											X"272", X"546", X"299", X"C8A", 
											X"2E4", X"285", X"527", X"CFB", 
											X"5F2", X"353", X"0E9", X"92A", 
											X"0B1", X"492", X"026", X"AF9", 
											X"0C0", X"534", X"185", X"2B7", X"B3B", 
											X"5E5", X"3B7", X"46A", X"C8B", 
											X"072", X"413", X"278", X"B19", 
											X"2B0", X"425", X"297", X"1AB");
	
	signal Hbm1_RdAddr					: std_logic_vector(5 downto 0) := "111111";
	
	signal p_ij							: std_logic_vector(sz-1 downto 0) := (others => '0');
	signal BS_Shift						: std_logic_vector(sz-1 downto 0) := (others => '0');
	------------------------------------O------------------------------------
	signal StartSumCalc					: std_logic_vector(2 downto 0) := (others => '0');
	signal NewSumTerm					: std_logic_vector(2 downto 0) := (others => '0');
	signal State						: integer range 3 downto 0 := 0;
	
	signal InvalidShift					: std_logic := '0';
	signal r_Pi							: std_logic := '0';
	------------------------------------O------------------------------------
begin
	------------------------------------------------------------------------------------------------
	-- 
	------------------------------------------------------------------------------------------------
	input_ram : process(clk)
	begin
		if rising_edge(clk) then
			if Pi = '1' then
				if Vi = '1' then
					U(conv_integer(U_WrAddr)) <= Di;
					U_WrAddr <= U_WrAddr + '1';
				end if;
			else
				U_WrAddr <= (others => '0');
			end if;
		end if;
	end process;
	------------------------------------------------------------------------------------------------
	-- 
	------------------------------------------------------------------------------------------------
	parity_ram : process(clk)
	begin
		if rising_edge(clk) then
			if Pi = '0' and r_Pi = '1' then
				SumTermWrAddr <= 0;
			else
				if SumTermWrEn = '1' then
					SumTerm(SumTermWrAddr) <= v_0;
					
					SumTermWrAddr <= SumTermWrAddr + 1;
					if SumTermWrAddr = mb-1 then
						SumTermWrAddr <= 0;
					end if;
				end if;
			end if;
			SumTermRdData <= SumTerm(SumTermRdAddr);
		end if;
	end process;

	------------------------------------------------------------------------------------------------
	--
	------------------------------------------------------------------------------------------------
	calculation_of_summation_terms : process(clk)
		variable Temp	: std_logic_vector(11 downto 0);
	begin
		if rising_edge(clk) then
			r_Pi <= Pi;
			if Pi = '0' and r_Pi = '1' then
				Hbm1_RdAddr <= (others => '0');
				v_0 <= (others => '0');
			end if;
			------------------------------------O------------------------------------
			-- Calculation of summation terms in parity expressions
			------------------------------------O------------------------------------
			StartSumCalc <= StartSumCalc(1 downto 0) & '0';
			NewSumTerm <= NewSumTerm(1 downto 0) & '0';
			if Hbm1_RdAddr < 51 then
				Hbm1_RdAddr <= Hbm1_RdAddr + '1';
				
				Temp := Hbm1(conv_integer(Hbm1_RdAddr));
				p_ij <= Temp(sz+3 downto 4);
				u_j <= U( conv_integer( Temp(3 downto 0)));
				
				NewSumTerm <= NewSumTerm(1 downto 0) & Temp(11);
				StartSumCalc <= StartSumCalc(1 downto 0) & '1';
			end if;
			
			if StartSumCalc(0) = '1' then
				BS_Shift <= p_ij;
				BS_Di <= u_j;
			end if;
			
			SumTermWrEn <= '0';
			if StartSumCalc(2) = '1' then
				if NewSumTerm(2) = '1' then
					SumTermWrEn <= '1';
				end if;
				v_0 <= v_0 xor BS_Do;
			end if;
			------------------------------------O------------------------------------
			-- calculation of parities
			------------------------------------O------------------------------------
			Po <= '1';
			Vo <= '0';
			SumTermRdAddr <= 0;
			case State is
			when 0 =>
				Po <= '0';
				if StartSumCalc(2 downto 1) = "10" then
					State <= 1;
				end if;
			when 1 => -- calculation of v_0 (since unpaired rotation is 0, there is no need to shift v0 again)
				Vo <= '1'; --outputing v0
				if hbm_5 = 0 then
					Do <= v_0;
				else
					Do <= v_0(hbm_5-1 downto 0) & v_0(z-1 downto hbm_5);
				end if;
				
				SumTermRdAddr <= SumTermRdAddr + 1; -- burada 0 olmasi lazim
				
				State <= 2;
			when 2 =>
				Vo <= '1';
				if hbm_0 = 0 then
					Do <= SumTermRdData xor v_0;
				else
					Do <= SumTermRdData xor (v_0(hbm_0-1 downto 0) & v_0(z-1 downto hbm_0));
				end if;
				
				SumTermRdAddr <= SumTermRdAddr + 1;
				if SumTermRdAddr = 5 then
					State <= 3;
				end if;
			when 3 =>
				Vo <= '1';
				if hbm_0 = 0 then
					if hbm_5 = 0 then
						Do <= SumTermRdData xor v_0 xor v_0;
					else
						Do <= SumTermRdData xor v_0 xor (v_0(hbm_5-1 downto 0) & v_0(z-1 downto hbm_5));
					end if;
				else
					if hbm_5 = 0 then
						Do <= SumTermRdData xor (v_0(hbm_0-1 downto 0) & v_0(z-1 downto hbm_0)) xor v_0;
					else
						Do <= SumTermRdData xor (v_0(hbm_0-1 downto 0) & v_0(z-1 downto hbm_0)) xor (v_0(hbm_5-1 downto 0) & v_0(z-1 downto hbm_5));
					end if;
				end if;
				
				SumTermRdAddr <= SumTermRdAddr + 1;
				if SumTermRdAddr = mb-1 then
					SumTermRdAddr <= 0;
					State <= 0;
				end if;
			when others =>
			end case;
			
		end if;
	end process;
	
	Barrel_Shifter_Intance: entity work.Barrel_Shifter
	generic map(
		z => z,
		logZ => sz
	)
	port map(
		clk => clk,
		Shift => BS_Shift,
		Di => BS_Di,
		Do => BS_Do
	);
end Behavioral;

