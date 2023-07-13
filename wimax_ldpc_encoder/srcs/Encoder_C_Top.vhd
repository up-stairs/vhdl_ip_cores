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


-- throughput is kb*z/(kb*mb+kb+3) bits/clock cycle
entity Encoder_C_Top is
	generic(
		z						: integer := 96;
		logZ					: integer := 7; --ceil(log2(z))
		
		nb						: integer := 24;
		kb						: integer := 16;
		mb						: integer := 8
	);
	port(
		clk						: in std_logic;
		
		Ready					: out std_logic;
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
	-- rate 1/2
--	type MATRIX_TYPE_A is array (0 to mb-1,0 to kb-1) of integer range (2**logZ)-1 downto 0;
--	constant Hbm1						: MATRIX_TYPE_A := (
--((2**logZ)-1, 94*z/96, 73*z/96, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, 55*z/96, 83*z/96, (2**logZ)-1, (2**logZ)-1 ),
--((2**logZ)-1, 27*z/96, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, 22*z/96, 79*z/96,  9*z/96, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, 12*z/96 ),
--((2**logZ)-1, (2**logZ)-1, (2**logZ)-1, 24*z/96, 22*z/96, 81*z/96, (2**logZ)-1, 33*z/96, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1,  0*z/96 ),
--(61*z/96, (2**logZ)-1, 47*z/96, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, 65*z/96, 25*z/96, (2**logZ)-1, (2**logZ)-1 ),
--((2**logZ)-1, (2**logZ)-1, 39*z/96, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, 84*z/96, (2**logZ)-1, (2**logZ)-1, 41*z/96, 72*z/96, (2**logZ)-1 ),
--((2**logZ)-1, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, 46*z/96, 40*z/96, (2**logZ)-1, 82*z/96, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, 79*z/96 ),
--((2**logZ)-1, (2**logZ)-1, 95*z/96, 53*z/96, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, 14*z/96, 18*z/96, (2**logZ)-1 ),
--((2**logZ)-1, 11*z/96, 73*z/96, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1,  2*z/96, (2**logZ)-1, (2**logZ)-1, 47*z/96, (2**logZ)-1, (2**logZ)-1 ),
--(12*z/96, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, 83*z/96, 24*z/96, (2**logZ)-1, 43*z/96, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, 51*z/96 ),
--((2**logZ)-1, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, 94*z/96, (2**logZ)-1, 59*z/96, (2**logZ)-1, (2**logZ)-1, 70*z/96, 72*z/96 ),
--((2**logZ)-1, (2**logZ)-1,  7*z/96, 65*z/96, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, 39*z/96, 49*z/96, (2**logZ)-1, (2**logZ)-1 ),
--(43*z/96, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, 66*z/96, (2**logZ)-1, 41*z/96, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, 26*z/96 )
--);
--											
--	constant hbm_0							: integer range (2**logZ)-1 downto 0 := 7*z/96;
--	constant hbm_x							: integer range (2**logZ)-1 downto 0 := 0*z/96;
--	constant x								: integer range (2**logZ)-1 downto 0 := 5; --unpaired shift value for rate 1/2
	-- rate 2/3 A
	type MATRIX_TYPE_A is array (0 to mb-1,0 to kb-1) of integer range (2**logZ)-1 downto 0;
	constant Hbm1						: MATRIX_TYPE_A := (
( 3-z*( 3/z),  0-z*( 0/z), (2**logZ)-1, (2**logZ)-1,  2-z*( 2/z),  0-z*( 0/z), (2**logZ)-1,  3-z*( 3/z),  7-z*( 7/z), (2**logZ)-1,  1-z*( 1/z),  1-z*( 1/z), (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1),
((2**logZ)-1, (2**logZ)-1,  1-z*( 1/z), (2**logZ)-1, 36-z*(36/z), (2**logZ)-1, (2**logZ)-1, 34-z*(34/z), 10-z*(10/z), (2**logZ)-1, (2**logZ)-1, 18-z*(18/z),  2-z*( 2/z), (2**logZ)-1,  3-z*( 3/z),  0-z*( 0/z) ),
((2**logZ)-1, (2**logZ)-1, 12-z*(12/z),  2-z*( 2/z), (2**logZ)-1, 15-z*(15/z), (2**logZ)-1, 40-z*(40/z), (2**logZ)-1,  3-z*( 3/z), (2**logZ)-1, 15-z*(15/z), (2**logZ)-1,  2-z*( 2/z), 13-z*(13/z), (2**logZ)-1),
((2**logZ)-1, (2**logZ)-1, 19-z*(19/z), 24-z*(24/z), (2**logZ)-1,  3-z*( 3/z),  0-z*( 0/z), (2**logZ)-1,  6-z*( 6/z), (2**logZ)-1, 17-z*(17/z), (2**logZ)-1, (2**logZ)-1, (2**logZ)-1,  8-z*( 8/z), 39-z*(39/z) ),
(20-z*(20/z), (2**logZ)-1,  6-z*( 6/z), (2**logZ)-1, (2**logZ)-1, 10-z*(10/z), 29-z*(29/z), (2**logZ)-1, (2**logZ)-1, 28-z*(28/z), (2**logZ)-1, 14-z*(14/z), (2**logZ)-1, 38-z*(38/z), (2**logZ)-1, (2**logZ)-1),
((2**logZ)-1, (2**logZ)-1, 10-z*(10/z), (2**logZ)-1, 28-z*(28/z), 20-z*(20/z), (2**logZ)-1, (2**logZ)-1,  8-z*( 8/z), (2**logZ)-1, 36-z*(36/z), (2**logZ)-1,  9-z*( 9/z), (2**logZ)-1, 21-z*(21/z), 45-z*(45/z) ),
(35-z*(35/z), 25-z*(25/z), (2**logZ)-1, 37-z*(37/z), (2**logZ)-1, 21-z*(21/z), (2**logZ)-1, (2**logZ)-1,  5-z*( 5/z), (2**logZ)-1, (2**logZ)-1,  0-z*( 0/z), (2**logZ)-1,  4-z*( 4/z), 20-z*(20/z), (2**logZ)-1),
((2**logZ)-1,  6-z*( 6/z),  6-z*( 6/z), (2**logZ)-1, (2**logZ)-1, (2**logZ)-1,  4-z*( 4/z), (2**logZ)-1, 14-z*(14/z), 30-z*(30/z), (2**logZ)-1,  3-z*( 3/z), 36-z*(36/z), (2**logZ)-1, 14-z*(14/z), (2**logZ)-1)
);
											
	constant hbm_0							: integer range (2**logZ)-1 downto 0 := 1-z*(1/z);
	constant hbm_x							: integer range (2**logZ)-1 downto 0 := 0-z*(0/z);
	constant x								: integer range (2**logZ)-1 downto 0 := 4; --unpaired shift value for rate 1/2
--	-- rate 2/3 B
--	type MATRIX_TYPE_A is array (0 to mb-1,0 to kb-1) of integer range (2**logZ)-1 downto 0;
--	constant Hbm1						: MATRIX_TYPE_A := (
--( 2*z/96, (2**logZ)-1, 19*z/96, (2**logZ)-1, 47*z/96, (2**logZ)-1, 48*z/96, (2**logZ)-1, 36*z/96, (2**logZ)-1, 82*z/96, (2**logZ)-1, 47*z/96, (2**logZ)-1, 15*z/96, (2**logZ)-1 ),
--((2**logZ)-1, 69*z/96, (2**logZ)-1, 88*z/96, (2**logZ)-1, 33*z/96, (2**logZ)-1,  3*z/96, (2**logZ)-1, 16*z/96, (2**logZ)-1, 37*z/96, (2**logZ)-1, 40*z/96, (2**logZ)-1, 48*z/96 ),
--(10*z/96, (2**logZ)-1, 86*z/96, (2**logZ)-1, 62*z/96, (2**logZ)-1, 28*z/96, (2**logZ)-1, 85*z/96, (2**logZ)-1, 16*z/96, (2**logZ)-1, 34*z/96, (2**logZ)-1, 73*z/96, (2**logZ)-1 ),
--((2**logZ)-1, 28*z/96, (2**logZ)-1, 32*z/96, (2**logZ)-1, 81*z/96, (2**logZ)-1, 27*z/96, (2**logZ)-1, 88*z/96, (2**logZ)-1,  5*z/96, (2**logZ)-1, 56*z/96, (2**logZ)-1, 37*z/96 ),
--(23*z/96, (2**logZ)-1, 29*z/96, (2**logZ)-1, 15*z/96, (2**logZ)-1, 30*z/96, (2**logZ)-1, 66*z/96, (2**logZ)-1, 24*z/96, (2**logZ)-1, 50*z/96, (2**logZ)-1, 62*z/96, (2**logZ)-1 ),
--((2**logZ)-1, 30*z/96, (2**logZ)-1, 65*z/96, (2**logZ)-1, 54*z/96, (2**logZ)-1, 14*z/96, (2**logZ)-1,  0*z/96, (2**logZ)-1, 30*z/96, (2**logZ)-1, 74*z/96, (2**logZ)-1,  0*z/96 ),
--(32*z/96, (2**logZ)-1,  0*z/96, (2**logZ)-1, 15*z/96, (2**logZ)-1, 56*z/96, (2**logZ)-1, 85*z/96, (2**logZ)-1,  5*z/96, (2**logZ)-1,  6*z/96, (2**logZ)-1, 52*z/96, (2**logZ)-1 ),
--((2**logZ)-1,  0*z/96, (2**logZ)-1, 47*z/96, (2**logZ)-1, 13*z/96, (2**logZ)-1, 61*z/96, (2**logZ)-1, 84*z/96, (2**logZ)-1, 55*z/96, (2**logZ)-1, 78*z/96, (2**logZ)-1, 41*z/96 )
--);
--											
--	constant hbm_0							: integer range (2**logZ)-1 downto 0 := 95*z/96;
--	constant hbm_x							: integer range (2**logZ)-1 downto 0 := 0*z/96;
--	constant x								: integer range (2**logZ)-1 downto 0 := 6; --unpaired shift value for rate 1/2
--	-- rate 3/4 A
--	type MATRIX_TYPE_A is array (0 to mb-1,0 to kb-1) of integer range (2**logZ)-1 downto 0;
--	constant Hbm1						: MATRIX_TYPE_A := (
--( 6*z/96, 38*z/96,  3*z/96, 93*z/96, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, 30*z/96, 70*z/96, (2**logZ)-1, 86*z/96, (2**logZ)-1, 37*z/96, 38*z/96,  4*z/96, 11*z/96, (2**logZ)-1, 46*z/96 ),
--(62*z/96, 94*z/96, 19*z/96, 84*z/96, (2**logZ)-1, 92*z/96, 78*z/96, (2**logZ)-1, 15*z/96, (2**logZ)-1, (2**logZ)-1, 92*z/96, (2**logZ)-1, 45*z/96, 24*z/96, 32*z/96, 30*z/96, (2**logZ)-1 ),
--(71*z/96, (2**logZ)-1, 55*z/96, (2**logZ)-1, 12*z/96, 66*z/96, 45*z/96, 79*z/96, (2**logZ)-1, 78*z/96, (2**logZ)-1, (2**logZ)-1, 10*z/96, (2**logZ)-1, 22*z/96, 55*z/96, 70*z/96, 82*z/96 ),
--(38*z/96, 61*z/96, (2**logZ)-1, 66*z/96,  9*z/96, 73*z/96, 47*z/96, 64*z/96, (2**logZ)-1, 39*z/96, 61*z/96, 43*z/96, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, 95*z/96, 32*z/96 ),
--((2**logZ)-1, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, 32*z/96, 52*z/96, 55*z/96, 80*z/96, 95*z/96, 22*z/96,  6*z/96, 51*z/96, 24*z/96, 90*z/96, 44*z/96, 20*z/96, (2**logZ)-1, (2**logZ)-1 ),
--((2**logZ)-1, 63*z/96, 31*z/96, 88*z/96, 20*z/96, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1,  6*z/96, 40*z/96, 56*z/96, 16*z/96, 71*z/96, 53*z/96, (2**logZ)-1, (2**logZ)-1, 27*z/96, 26*z/96 )
--);
--											
--	constant hbm_0							: integer range (2**logZ)-1 downto 0 := 48*z/96;
--	constant hbm_x							: integer range (2**logZ)-1 downto 0 := 0*z/96;
--	constant x								: integer range (2**logZ)-1 downto 0 := 3; --unpaired shift value for rate 1/2
--	-- rate 3/4 B
--	type MATRIX_TYPE_A is array (0 to mb-1,0 to kb-1) of integer range (2**logZ)-1 downto 0;
--	constant Hbm1						: MATRIX_TYPE_A := (
--((2**logZ)-1, 81*z/96, (2**logZ)-1, 28*z/96, (2**logZ)-1, (2**logZ)-1, 14*z/96, 25*z/96, 17*z/96, (2**logZ)-1, (2**logZ)-1, 85*z/96, 29*z/96, 52*z/96, 78*z/96, 95*z/96, 22*z/96, 92*z/96 ),
--(42*z/96, (2**logZ)-1, 14*z/96, 68*z/96, 32*z/96, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, 70*z/96, 43*z/96, 11*z/96, 36*z/96, 40*z/96, 33*z/96, 57*z/96, 38*z/96, 24*z/96 ),
--((2**logZ)-1, (2**logZ)-1, 20*z/96, (2**logZ)-1, (2**logZ)-1, 63*z/96, 39*z/96, (2**logZ)-1, 70*z/96, 67*z/96, (2**logZ)-1, 38*z/96,  4*z/96, 72*z/96, 47*z/96, 29*z/96, 60*z/96,  5*z/96 ),
--(64*z/96,  2*z/96, (2**logZ)-1, (2**logZ)-1, 63*z/96, (2**logZ)-1, (2**logZ)-1,  3*z/96, 51*z/96, (2**logZ)-1, 81*z/96, 15*z/96, 94*z/96,  9*z/96, 85*z/96, 36*z/96, 14*z/96, 19*z/96 ),
--((2**logZ)-1, 53*z/96, 60*z/96, 80*z/96, (2**logZ)-1, 26*z/96, 75*z/96, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, 86*z/96, 77*z/96,  1*z/96,  3*z/96, 72*z/96, 60*z/96, 25*z/96 ),
--(77*z/96, (2**logZ)-1, (2**logZ)-1, (2**logZ)-1, 15*z/96, 28*z/96, (2**logZ)-1, 35*z/96, (2**logZ)-1, 72*z/96, 30*z/96, 68*z/96, 85*z/96, 84*z/96, 26*z/96, 64*z/96, 11*z/96, 89*z/96 )
--);
--											
--	constant hbm_0							: integer range (2**logZ)-1 downto 0 := 0*z/96;
--	constant hbm_x							: integer range (2**logZ)-1 downto 0 := 80*z/96;
--	constant x								: integer range (2**logZ)-1 downto 0 := 2; --unpaired shift value for rate 1/2
--	-- rate 5/6
--	type MATRIX_TYPE_A is array (0 to mb-1,0 to kb-1) of integer range (2**logZ)-1 downto 0;
--	constant Hbm1						: MATRIX_TYPE_A := (
--( 1*z/96, 25*z/96, 55*z/96, (2**logZ)-1, 47*z/96,  4*z/96, (2**logZ)-1, 91*z/96, 84*z/96,  8*z/96, 86*z/96, 52*z/96, 82*z/96, 33*z/96,  5*z/96,  0*z/96, 36*z/96, 20*z/96,  4*z/96, 77*z/96 ),
--((2**logZ)-1,  6*z/96, (2**logZ)-1, 36*z/96, 40*z/96, 47*z/96, 12*z/96, 79*z/96, 47*z/96, (2**logZ)-1, 41*z/96, 21*z/96, 12*z/96, 71*z/96, 14*z/96, 72*z/96,  0*z/96, 44*z/96, 49*z/96,  0*z/96 ),
--(51*z/96, 81*z/96, 83*z/96,  4*z/96, 67*z/96, (2**logZ)-1, 21*z/96, (2**logZ)-1, 31*z/96, 24*z/96, 91*z/96, 61*z/96, 81*z/96,  9*z/96, 86*z/96, 78*z/96, 60*z/96, 88*z/96, 67*z/96, 15*z/96 ),
--(50*z/96, (2**logZ)-1, 50*z/96, 15*z/96, (2**logZ)-1, 36*z/96, 13*z/96, 10*z/96, 11*z/96, 20*z/96, 53*z/96, 90*z/96, 29*z/96, 92*z/96, 57*z/96, 30*z/96, 84*z/96, 92*z/96, 11*z/96, 66*z/96 )
--);
--											
--	constant hbm_0							: integer range (2**logZ)-1 downto 0 := 80*z/96;
--	constant hbm_x							: integer range (2**logZ)-1 downto 0 := 0*z/96;
--	constant x								: integer range (2**logZ)-1 downto 0 := 1; --unpaired shift value for rate 1/2
	------------------------------------O------------------------------------
	type ARRAY_TYPE_A is array (kb-1 downto 0) of std_logic_vector(z-1 downto 0);
	signal U								: ARRAY_TYPE_A := (others => (others=> '0'));
	
	signal U_WrAddr							: std_logic_vector(4 downto 0) := (others => '0'); --max kb = 20 in the standard
	
	signal u_j								: std_logic_vector(z-1 downto 0) := (others => '0');
	------------------------------------O------------------------------------
	type ARRAY_TYPE_B is array (mb-1 downto 0) of std_logic_vector(z-1 downto 0); -- ilk mb-1 indeksi summation kaydetmek icin kullaniliyor. Son indeks koddaki bi hatanin uzerini kapatmak icin kullaniliyor
	signal RowSums							: ARRAY_TYPE_B := (others => (others=> '0'));
	
	signal RowSumsWE						: std_logic := '0';
	signal RowSumsWrAddr					: std_logic_vector(3 downto 0) := (others => '0'); --max mb = 12 
	signal RowSumsRdAddr					: std_logic_vector(3 downto 0) := (others => '0'); --max mb = 12 
	------------------------------------O------------------------------------
	signal i								: std_logic_vector(3 downto 0) := conv_std_logic_vector(mb,4);
	signal j								: std_logic_vector(4 downto 0) := (others => '0');
	
	signal v0								: std_logic_vector(z-1 downto 0) := (others => '0');
	signal prev_v0							: std_logic_vector(z-1 downto 0) := (others => '0');
	signal P0kb_v0							: std_logic_vector(z-1 downto 0) := (others => '0');
	
	signal p_ij								: std_logic_vector(logZ-1 downto 0) := (others => '0');
	
	signal NewXOR							: std_logic := '0';
	signal NewRowSum						: std_logic_vector(2 downto 0) := (others => '0');
	signal NewShift							: std_logic_vector(2 downto 0) := (others => '0');
	
	signal Durum							: integer range 6 downto 0 := 0;
	signal State							: integer range 3 downto 0 := 0;
	
	signal r_Pi								: std_logic := '0';
	------------------------------------O------------------------------------
	signal BS_Shift							: std_logic_vector(logZ-1 downto 0) := (others => '0');
	signal BS_Di							: std_logic_vector(z-1 downto 0) := (others => '0');
	signal BS_Do							: std_logic_vector(z-1 downto 0) := (others => '0');
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
	summation_terms_array : process(clk)
	begin
		if rising_edge(clk) then
			r_Pi <= Pi;
			if Pi = '0' and r_Pi = '1' then
				RowSumsWrAddr <= (others => '0');
			else
				if RowSumsWE = '1' then
					RowSums(conv_integer(RowSumsWrAddr)) <= v0;
					
					RowSumsWrAddr <= RowSumsWrAddr + '1';
				end if;
			end if;
		end if;
	end process;

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
			NewRowSum <= NewRowSum(1 downto 0) & '0';
			NewShift <= NewShift(1 downto 0) & '0';
			if i < mb then
				NewShift <= NewShift(1 downto 0) & '1';
				p_ij <= conv_std_logic_vector( Hbm1(conv_integer(i),conv_integer(j)) , logZ );
--				p_ij <= conv_std_logic_vector( Hbm1(conv_integer(i)*kb+conv_integer(j)) , logZ );
				u_j <= U( conv_integer(j) );
				if j < kb-1 then
					j <= j + '1';
				else
					j <= (others => '0');
					i <= i + '1';
					NewRowSum <= NewRowSum(1 downto 0) & '1';
				end if;
			end if;
								-----
								--2--
								-----
			BS_Shift <= p_ij;
			BS_Di <= u_j;
								-----
								--3--
								-----
			if BS_Shift /= (2**logZ)-1 then
				NewXOR <= '1';
			else
				NewXOR <= '0';
			end if;
								-----
								--4--
								-----
			RowSumsWE <= '0';
			if NewXOR = '1' and NewShift(2) = '1' then
				v0 <= v0 xor BS_Do;
			end if;
			if NewRowSum(2) = '1' then
				RowSumsWE <= '1';
			end if;
			------------------------------------O------------------------------------
			-- Calculation of v0
			------------------------------------O------------------------------------
			case Durum is
			when 0 =>
				if i = mb and NewRowSum(2) = '1' then
					Ready <= '1';
					Durum <= 1;
				end if;
			when 1 =>
				BS_Shift <= conv_std_logic_vector( z-hbm_x , logZ );
				BS_Di <= v0;
				Durum <= 2;
			when 2 =>
				Durum <= 3;
			when 3 =>
				prev_v0 <= v0;
				v0 <= BS_Do;
				Durum <= 4;
			when 4 =>
				BS_Shift <= conv_std_logic_vector( hbm_0 , logZ );
				BS_Di <= v0;
				Durum <= 5;
			when 5 =>
				Durum <= 6;
			when 6 =>
				P0kb_v0 <= BS_Do;
				Durum <= 0;
			when others =>
			end case;
			------------------------------------O------------------------------------
			-- calculation of parities
			------------------------------------O------------------------------------
			Po <= '1';
			Vo <= '0';
			RowSumsRdAddr <= (others => '0');
			case State is
			when 0 =>
				Po <= '0';
				if Durum = 6 then
					State <= 1;
				end if;
			when 1 =>
				Vo <= '1'; --outputing v0
				Do <= v0;
				
				State <= 2;
			when 2 =>
				Vo <= '1';
				Do <= RowSums(conv_integer(RowSumsRdAddr)) xor P0kb_v0;
				
				RowSumsRdAddr <= RowSumsRdAddr + 1;
				if RowSumsRdAddr = x-1 then
					State <= 3;
				end if;
			when 3 =>
				Vo <= '1';
				Do <= RowSums(conv_integer(RowSumsRdAddr)) xor P0kb_v0 xor prev_v0;
				
				RowSumsRdAddr <= RowSumsRdAddr + 1;
				if RowSumsRdAddr = mb-2 then
					State <= 0;
				end if;
			when others =>
			end case;
			------------------------------------O------------------------------------
			-- resetting variables
			------------------------------------O------------------------------------
			if Pi = '1' then
				Ready <= '0';
			end if;
			if Pi = '0' and r_Pi = '1' then
				i <= (others => '0');
				j <= (others => '0');
				v0 <= (others => '0');
			end if;
		end if;
	end process;
	
	Barrel_Shifter_Intance: entity work.Barrel_Shifter
	generic map(
		z => z,
		logZ => logZ
	)
	port map(
		clk => clk,
		Shift => BS_Shift,
		Di => BS_Di,
		Do => BS_Do
	);
end Behavioral;

