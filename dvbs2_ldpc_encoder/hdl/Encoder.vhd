----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:24:00 12/01/2010 
-- Design Name: 
-- Module Name:    Encoder_All_Rates_Top - Behavioral 
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


-- throughput is kb*z/(# of nonzero rotations in Hb1+kb+12) bits/clock cycle
entity Encoder is
	generic(				
		z						: integer :=180;
		logZ					: integer :=8; --ceil(log2(z))
		logC					: integer :=5; -- log2( # of supported codes )
		logA					: integer :=9; -- max( log2( max(kb)*360/z ), log2( max(mb)*360/z ) )
		logMaE					: integer :=11; -- log2( max # of edges * 360/z)
		logToE					: integer :=14 -- log2( total # of edges * 360/z )
	);
	port(
		clk								: in std_logic;
		
		CodeSel							: in  std_logic_vector(logC-1 downto 0);
		Ready							: out std_logic;
		
		Pi								: in  std_logic;
		Vi								: in  std_logic;
		Di								: in  std_logic_vector(z-1 downto 0);
		
		Po								: out std_logic;
		Vo								: out std_logic;
		Do								: out std_logic_vector(z-1 downto 0)
	);
end Encoder;

architecture Behavioral of Encoder is
--	constant kb							: INT_VECTOR_A := (9, 15, 18, 20, 27, 30, 33, 35, 37, 40, 45, 60, 72, 90, 108, 120, 135, 144, 150, 160, 162);
--	constant mb							: INT_VECTOR_A := (36, 30, 27, 25, 18, 15, 13, 10, 8, 5, 135, 120, 108, 90, 72, 60, 45, 36, 30, 20, 18);
	
	constant S							: integer := 360/z;
	constant C							: integer := 21;--2**logC;
	
	type INT_VECTOR_A is array (0 to C-1) of integer;
	constant kb							: INT_VECTOR_A := (   9*S,  15*S,  18*S,  20*S,  27*S,  30*S,  33*S,  35*S,  37*S,  40*S,  45*S,  60*S,  72*S,  90*S, 108*S, 120*S, 135*S, 144*S, 150*S, 160*S, 162*S);
	constant mb							: INT_VECTOR_A := (  36*S,  30*S,  27*S,  25*S,  18*S,  15*S,  12*S,  10*S,   8*S,   5*S, 135*S, 120*S, 108*S,  90*S,  72*S,  60*S,  45*S,  36*S,  30*S,  20*S,  18*S);
	constant EdgeCnts					: INT_VECTOR_A := (  63*S,  90*S, 108*S,  85*S, 162*S, 120*S, 108*S, 105*S, 121*S, 125*S, 270*S, 360*S, 432*S, 450*S, 648*S, 480*S, 540*S, 576*S, 600*S, 500*S, 504*S);
	constant EdgeStartIndex				: INT_VECTOR_A := (   0*S,  63*S, 153*S, 261*S, 346*S, 508*S, 628*S, 736*S, 841*S, 962*S, 1087*S, 1357*S, 1717*S, 2149*S, 2599*S, 3247*S, 3727*S, 4267*S, 4843*S, 5443*S, 5943*S);
	------------------------------------O------------------------------------
	type ARRAY_TYPE_A is array ((2**(logA+1))-1 downto 0) of std_logic_vector(z-1 downto 0);
	signal Memory						: ARRAY_TYPE_A := (others => (others=> '0'));
	
	signal Memory_WrAddr				: std_logic_vector(logA downto 0) := (others => '0');
	signal Memory_RdAddr				: std_logic_vector(logA downto 0) := (others => '0');
	
	signal Memory_Do					: std_logic_vector(z-1 downto 0) := (others => '0');
	signal Memory_Di					: std_logic_vector(z-1 downto 0) := (others => '0');
	
	signal r_CodeSel					: std_logic_vector(logC-1 downto 0) := (others => '0');
	signal i_CodeSel					: integer range C-1 downto 0 := 0;
	
	signal ResetState					: integer range 3 downto 0 := 0;
	
	signal rst							: std_logic := '0';
	------------------------------------O------------------------------------
	------
	signal EdgeAddr						: std_logic_vector(logToE-1 downto 0) := (others => '0');
	------
	------
	signal EdgeInfo						: std_logic_vector(17 downto 0); -- 1 bit 'restart' için, max(kb) için log2(kb*S) bit input adresleme için, 'logZ' bit rotasyon için
	------
	------------------------------------O------------------------------------
	------
	signal EdgeCntr						: std_logic_vector(logMaE downto 0) := (others => '1');
	------
	
	signal RowSumsWE					: std_logic := '0';
	signal r_RowSumsWE					: std_logic := '0';
	signal rr_RowSumsWE					: std_logic := '0';
	signal rrr_RowSumsWE				: std_logic := '0';
	
	signal RowColSum					: std_logic_vector(z-1 downto 0) := (others => '0');
	signal RowSum						: std_logic_vector(z-1 downto 0) := (others => '0');
	
	signal Rotation						: std_logic_vector(logZ-1 downto 0) := (others => '0');
	signal r_Rotation					: std_logic_vector(logZ-1 downto 0) := (others => '0');
	signal NewXOR						: std_logic_vector(4 downto 0) := (others => '0');
	------------------------------------O------------------------------------
	signal Durum						: integer range 1 downto 0 := 0;
	signal Sayac						: std_logic_vector(logZ-1 downto 0) := (others => '0');
	signal Parite						: std_logic_vector(z-1 downto 0) := (others => '0');
	------------------------------------O------------------------------------
	signal State						: integer range 2 downto 0 := 0;
	signal Parity						: std_logic_vector(z-1 downto 0) := (others => '0');
	------------------------------------O------------------------------------
	signal BS_Do						: std_logic_vector(z-1 downto 0);
	------------------------------------O------------------------------------
	signal i_Po							: std_logic := '0';
	------------------------------------O------------------------------------
begin
	
	------------------------------------------------------------------------------------------------
	-- 
	------------------------------------------------------------------------------------------------
	encoder_control_and_memory : process(clk)
	begin
		if rising_edge(clk) then
			if Pi = '1' then
				Ready <= '0';
				if Vi = '1' then
					Memory(conv_integer(Memory_WrAddr)) <= Di;
					Memory_WrAddr <= Memory_WrAddr + '1';
				end if;
				ResetState <= 1;
				r_CodeSel <= CodeSel;
				rst <= '1';
			else
				i_CodeSel <= conv_integer(r_CodeSel);
				rst <= '0';
				case ResetState is
				when 1 =>
					if Memory_WrAddr /= kb(conv_integer(r_CodeSel)) then
						ResetState <= 2;
					else
						Memory_WrAddr <= conv_std_logic_vector(2**logA, logA+1);
						ResetState <= 3;
					end if;
				when 2 =>
					Ready <= '1';
					Memory_WrAddr <= (others => '0');
					rst <= '1';
				when 3 =>
					if i_Po = '1' then
						ResetState <= 0;
					else
						if RowSumsWE = '1' then
							Memory(conv_integer(Memory_WrAddr)) <= Memory_Di;
							Memory_WrAddr <= Memory_WrAddr + '1';
						end if;
					end if;
				when 0 =>
					if i_Po = '0' then
						ResetState <= 2;
					end if;
				when others =>
				end case;
			end if;
			Memory_Do <= Memory(conv_integer(Memory_RdAddr));
		end if;
	end process;
	------------------------------------------------------------------------------------------------
	--
	------------------------------------------------------------------------------------------------
	Edge_Map_Rom: entity work.EdgeMap 
	port map(
		clk => clk,
		Addr => EdgeAddr,
		Do => EdgeInfo
	);
	------------------------------------------------------------------------------------------------
	--
	------------------------------------------------------------------------------------------------
	calculation_of_summation_terms : process(clk)
	begin
		if rising_edge(clk) then
			------------------------------------O------------------------------------
			-- Calculation of summation terms in parity expressions
			------------------------------------O------------------------------------
								-----
								--1--
								-----
			NewXOR <= NewXOR(3 downto 0) & '0';
			if EdgeCntr < EdgeCnts(i_CodeSel) then
				EdgeCntr <= EdgeCntr + '1';
				
				NewXOR <= NewXOR(3 downto 0) & '1';
				
				EdgeAddr <= conv_std_logic_vector(EdgeStartIndex(i_CodeSel),EdgeAddr'length) + EdgeCntr;
			end if;
								-----
								--3--
								-----
			Rotation <= EdgeInfo(logZ-1 downto 0);
			Memory_RdAddr <= '0' & EdgeInfo(logZ+logA-1 downto logZ);
			rrr_RowSumsWE <= EdgeInfo(EdgeInfo'left);
								-----
								--4--
								-----
			r_Rotation <= Rotation;
			rr_RowSumsWE <= rrr_RowSumsWE;
								-----
								--5--
								-----
			r_RowSumsWE <= rr_RowSumsWE;
								-----
								--6--
								-----
			RowSumsWE <= '0';
			if NewXOR(4) = '1' then
				RowColSum <= RowColSum xor BS_Do;
				if r_RowSumsWE = '0' then
					RowSum <= RowSum xor BS_Do;
				else
					RowSum <= (others => '0');
				end if;
				RowSumsWE <= r_RowSumsWE;
			end if;
			Memory_Di <= RowSum xor BS_Do;
			
			
			
			if rst = '1' then
				RowSum <= (others => '0');
				RowColSum <= (others => '0');
				RowSumsWE <= '0';
				r_RowSumsWE <= '0';
				rr_RowSumsWE <= '0';
				rrr_RowSumsWE <= '0';
				
				EdgeCntr <= (others => '0');
				NewXOR <= (others => '0');
			end if;
			------------------------------------O------------------------------------
			-- Calculation of Parite
			------------------------------------O------------------------------------
			Sayac <= conv_std_logic_vector(z-2,logZ);
			case Durum is
			when 0 =>
				if NewXOR(4) = '1' and NewXOR(3) = '0' then
					Durum <= 1;
				end if;
			when 1 =>
				Sayac <= Sayac - '1';
				Parite( conv_integer(Sayac) ) <= Parite( conv_integer(Sayac)+1 ) xor RowColSum( conv_integer(Sayac)+1 );
				if Sayac = 0 then
					Durum <= 0;
				end if;
			when others =>
			end case;
			
			
			if rst = '1' then
				Parite <= (others => '0');
				Durum <= 0;
			end if;
			------------------------------------O------------------------------------
			-- calculation of parities
			------------------------------------O------------------------------------
			i_Po <= '0';
			case State is
			when 0 =>
--				if NewXOR(4) = '1' and NewXOR(3) = '0' then
				if Durum = 1 and Sayac = 0 then
					Memory_RdAddr <= conv_std_logic_vector(2**logA,logA+1);
					State <= 1;
				end if;
			when 1 =>
				Memory_RdAddr <= Memory_RdAddr + '1';
				State <= 2;
			when 2 =>
				Memory_RdAddr <= Memory_RdAddr + '1';
				i_Po <= '1'; --outputing v0
				if Memory_RdAddr = 2**logA+1 then
					Parity <= Parite xor Memory_Do;
				else
					Parity <= Parity xor Memory_Do;
				end if;
				
				if Memory_RdAddr = 2**logA+mb(i_CodeSel) then
					State <= 0;
				end if;
			when others =>
			end case;
			
			
			if rst = '1' then
				State <= 0;
			end if;
		end if;
	end process;
	Do <= Parity;
	Po <= i_Po;
	Vo <= i_Po;
	
	Barrel_Shifter : entity work.Barrel_Shifter
	generic map(
		z => z,
		logZ => logZ
	)
	port map(
		clk => clk,
		Shift => r_Rotation,
		Di => Memory_Do,
		Do => BS_Do
	);
end Behavioral;

