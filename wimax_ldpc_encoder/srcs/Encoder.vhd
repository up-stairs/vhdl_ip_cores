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


-- throughput is kb*z/(# of nonzero rotations in Hb1+40) bits/clock cycle
entity Encoder is
	generic(				
		z						: integer :=96;
		logZ					: integer :=7 --ceil(log2(z))
	);
	port(
		clk						: in std_logic;
		
		CodeSel					: in  std_logic_vector(2 downto 0);
		Ready					: out std_logic;
		
		Pi						: in  std_logic;
		Vi						: in  std_logic;
		Di						: in  std_logic_vector(z-1 downto 0);
		
		Po						: out std_logic;
		Vo						: out std_logic;
		Do						: out std_logic_vector(z-1 downto 0)
	);
end Encoder;

architecture Behavioral of Encoder is
	------------------------------------O------------------------------------
	type MATRIX_TYPE_A is array (0 to 128*6-1) of integer range 8191 downto 0;
	constant EdgeMap						: MATRIX_TYPE_A := (
4096*0+(128* 1)+(94*z/96),  4096*0+(128* 2)+(73*z/96),  4096*0+(128* 8)+(55*z/96),  4096*1+(128* 9)+(83*z/96),  
4096*0+(128* 1)+(27*z/96),  4096*0+(128* 5)+(22*z/96),  4096*0+(128* 6)+(79*z/96),  4096*0+(128* 7)+( 9*z/96),  4096*1+(128*11)+(12*z/96),  
4096*0+(128* 3)+(24*z/96),  4096*0+(128* 4)+(22*z/96),  4096*0+(128* 5)+(81*z/96),  4096*0+(128* 7)+(33*z/96),  4096*1+(128*11)+( 0*z/96),  
4096*0+(128* 0)+(61*z/96),  4096*0+(128* 2)+(47*z/96),  4096*0+(128* 8)+(65*z/96),  4096*1+(128* 9)+(25*z/96),  
4096*0+(128* 2)+(39*z/96),  4096*0+(128* 6)+(84*z/96),  4096*0+(128* 9)+(41*z/96),  4096*1+(128*10)+(72*z/96),  
4096*0+(128* 4)+(46*z/96),  4096*0+(128* 5)+(40*z/96),  4096*0+(128* 7)+(82*z/96),  4096*1+(128*11)+(79*z/96),  
4096*0+(128* 2)+(95*z/96),  4096*0+(128* 3)+(53*z/96),  4096*0+(128* 9)+(14*z/96),  4096*1+(128*10)+(18*z/96),  
4096*0+(128* 1)+(11*z/96),  4096*0+(128* 2)+(73*z/96),  4096*0+(128* 6)+( 2*z/96),  4096*1+(128* 9)+(47*z/96),  
4096*0+(128* 0)+(12*z/96),  4096*0+(128* 4)+(83*z/96),  4096*0+(128* 5)+(24*z/96),  4096*0+(128* 7)+(43*z/96),  4096*1+(128*11)+(51*z/96),  
4096*0+(128* 5)+(94*z/96),  4096*0+(128* 7)+(59*z/96),  4096*0+(128*10)+(70*z/96),  4096*1+(128*11)+(72*z/96),  
4096*0+(128* 2)+( 7*z/96),  4096*0+(128* 3)+(65*z/96),  4096*0+(128* 8)+(39*z/96),  4096*1+(128* 9)+(49*z/96),  
4096*0+(128* 0)+(43*z/96),  4096*0+(128* 5)+(66*z/96),  4096*0+(128* 7)+(41*z/96),  4096*1+(128*11)+(26*z/96),  
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
4096*0+(128* 0)+( 3 mod z), 4096*0+(128* 1)+( 0 mod z), 4096*0+(128* 4)+( 2 mod z), 4096*0+(128* 5)+( 0 mod z), 4096*0+(128* 7)+( 3 mod z), 4096*0+(128* 8)+( 7 mod z), 4096*0+(128*10)+( 1 mod z), 4096*1+(128*11)+( 1 mod z), 
4096*0+(128* 2)+( 1 mod z), 4096*0+(128* 4)+(36 mod z), 4096*0+(128* 7)+(34 mod z), 4096*0+(128* 8)+(10 mod z), 4096*0+(128*11)+(18 mod z), 4096*0+(128*12)+( 2 mod z), 4096*0+(128*14)+( 3 mod z), 4096*1+(128*15)+( 0 mod z), 
4096*0+(128* 2)+(12 mod z), 4096*0+(128* 3)+( 2 mod z), 4096*0+(128* 5)+(15 mod z), 4096*0+(128* 7)+(40 mod z), 4096*0+(128* 9)+( 3 mod z), 4096*0+(128*11)+(15 mod z), 4096*0+(128*13)+( 2 mod z), 4096*1+(128*14)+(13 mod z), 
4096*0+(128* 2)+(19 mod z), 4096*0+(128* 3)+(24 mod z), 4096*0+(128* 5)+( 3 mod z), 4096*0+(128* 6)+( 0 mod z), 4096*0+(128* 8)+( 6 mod z), 4096*0+(128*10)+(17 mod z), 4096*0+(128*14)+( 8 mod z), 4096*1+(128*15)+(39 mod z), 
4096*0+(128* 0)+(20 mod z), 4096*0+(128* 2)+( 6 mod z), 4096*0+(128* 5)+(10 mod z), 4096*0+(128* 6)+(29 mod z), 4096*0+(128* 9)+(28 mod z), 4096*0+(128*11)+(14 mod z), 4096*1+(128*13)+(38 mod z), 
4096*0+(128* 2)+(10 mod z), 4096*0+(128* 4)+(28 mod z), 4096*0+(128* 5)+(20 mod z), 4096*0+(128* 8)+( 8 mod z), 4096*0+(128*10)+(36 mod z), 4096*0+(128*12)+( 9 mod z), 4096*0+(128*14)+(21 mod z), 4096*1+(128*15)+(45 mod z), 
4096*0+(128* 0)+(35 mod z), 4096*0+(128* 1)+(25 mod z), 4096*0+(128* 3)+(37 mod z), 4096*0+(128* 5)+(21 mod z), 4096*0+(128* 8)+( 5 mod z), 4096*0+(128*11)+( 0 mod z), 4096*0+(128*13)+( 4 mod z), 4096*1+(128*14)+(20 mod z), 
4096*0+(128* 1)+( 6 mod z), 4096*0+(128* 2)+( 6 mod z), 4096*0+(128* 6)+( 4 mod z), 4096*0+(128* 8)+(14 mod z), 4096*0+(128* 9)+(30 mod z), 4096*0+(128*11)+( 3 mod z), 4096*0+(128*12)+(36 mod z), 4096*1+(128*14)+(14 mod z), 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
4096*0+(128* 0)+( 2*z/96),  4096*0+(128* 2)+(19*z/96),  4096*0+(128* 4)+(47*z/96),  4096*0+(128* 6)+(48*z/96),  4096*0+(128* 8)+(36*z/96),  4096*0+(128*10)+(82*z/96),  4096*0+(128*12)+(47*z/96),  4096*1+(128*14)+(15*z/96),  
4096*0+(128* 1)+(69*z/96),  4096*0+(128* 3)+(88*z/96),  4096*0+(128* 5)+(33*z/96),  4096*0+(128* 7)+( 3*z/96),  4096*0+(128* 9)+(16*z/96),  4096*0+(128*11)+(37*z/96),  4096*0+(128*13)+(40*z/96),  4096*1+(128*15)+(48*z/96),  
4096*0+(128* 0)+(10*z/96),  4096*0+(128* 2)+(86*z/96),  4096*0+(128* 4)+(62*z/96),  4096*0+(128* 6)+(28*z/96),  4096*0+(128* 8)+(85*z/96),  4096*0+(128*10)+(16*z/96),  4096*0+(128*12)+(34*z/96),  4096*1+(128*14)+(73*z/96),  
4096*0+(128* 1)+(28*z/96),  4096*0+(128* 3)+(32*z/96),  4096*0+(128* 5)+(81*z/96),  4096*0+(128* 7)+(27*z/96),  4096*0+(128* 9)+(88*z/96),  4096*0+(128*11)+( 5*z/96),  4096*0+(128*13)+(56*z/96),  4096*1+(128*15)+(37*z/96),  
4096*0+(128* 0)+(23*z/96),  4096*0+(128* 2)+(29*z/96),  4096*0+(128* 4)+(15*z/96),  4096*0+(128* 6)+(30*z/96),  4096*0+(128* 8)+(66*z/96),  4096*0+(128*10)+(24*z/96),  4096*0+(128*12)+(50*z/96),  4096*1+(128*14)+(62*z/96),  
4096*0+(128* 1)+(30*z/96),  4096*0+(128* 3)+(65*z/96),  4096*0+(128* 5)+(54*z/96),  4096*0+(128* 7)+(14*z/96),  4096*0+(128* 9)+( 0*z/96),  4096*0+(128*11)+(30*z/96),  4096*0+(128*13)+(74*z/96),  4096*1+(128*15)+( 0*z/96),  
4096*0+(128* 0)+(32*z/96),  4096*0+(128* 2)+( 0*z/96),  4096*0+(128* 4)+(15*z/96),  4096*0+(128* 6)+(56*z/96),  4096*0+(128* 8)+(85*z/96),  4096*0+(128*10)+( 5*z/96),  4096*0+(128*12)+( 6*z/96),  4096*1+(128*14)+(52*z/96),  
4096*0+(128* 1)+( 0*z/96),  4096*0+(128* 3)+(47*z/96),  4096*0+(128* 5)+(13*z/96),  4096*0+(128* 7)+(61*z/96),  4096*0+(128* 9)+(84*z/96),  4096*0+(128*11)+(55*z/96),  4096*0+(128*13)+(78*z/96),  4096*1+(128*15)+(41*z/96),  
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
4096*0+(128* 0)+( 6*z/96),  4096*0+(128* 1)+(38*z/96),  4096*0+(128* 2)+( 3*z/96),  4096*0+(128* 3)+(93*z/96),  4096*0+(128* 7)+(30*z/96),  4096*0+(128* 8)+(70*z/96),  4096*0+(128*10)+(86*z/96),  4096*0+(128*12)+(37*z/96),  4096*0+(128*13)+(38*z/96),  4096*0+(128*14)+( 4*z/96),  4096*0+(128*15)+(11*z/96),  4096*1+(128*17)+(46*z/96),  
4096*0+(128* 0)+(62*z/96),  4096*0+(128* 1)+(94*z/96),  4096*0+(128* 2)+(19*z/96),  4096*0+(128* 3)+(84*z/96),  4096*0+(128* 5)+(92*z/96),  4096*0+(128* 6)+(78*z/96),  4096*0+(128* 8)+(15*z/96),  4096*0+(128*11)+(92*z/96),  4096*0+(128*13)+(45*z/96),  4096*0+(128*14)+(24*z/96),  4096*0+(128*15)+(32*z/96),  4096*1+(128*16)+(30*z/96),  
4096*0+(128* 0)+(71*z/96),  4096*0+(128* 2)+(55*z/96),  4096*0+(128* 4)+(12*z/96),  4096*0+(128* 5)+(66*z/96),  4096*0+(128* 6)+(45*z/96),  4096*0+(128* 7)+(79*z/96),  4096*0+(128* 9)+(78*z/96),  4096*0+(128*12)+(10*z/96),  4096*0+(128*14)+(22*z/96),  4096*0+(128*15)+(55*z/96),  4096*0+(128*16)+(70*z/96),  4096*1+(128*17)+(82*z/96),  
4096*0+(128* 0)+(38*z/96),  4096*0+(128* 1)+(61*z/96),  4096*0+(128* 3)+(66*z/96),  4096*0+(128* 4)+( 9*z/96),  4096*0+(128* 5)+(73*z/96),  4096*0+(128* 6)+(47*z/96),  4096*0+(128* 7)+(64*z/96),  4096*0+(128* 9)+(39*z/96),  4096*0+(128*10)+(61*z/96),  4096*0+(128*11)+(43*z/96),  4096*0+(128*16)+(95*z/96),  4096*1+(128*17)+(32*z/96),  
4096*0+(128* 4)+(32*z/96),  4096*0+(128* 5)+(52*z/96),  4096*0+(128* 6)+(55*z/96),  4096*0+(128* 7)+(80*z/96),  4096*0+(128* 8)+(95*z/96),  4096*0+(128* 9)+(22*z/96),  4096*0+(128*10)+( 6*z/96),  4096*0+(128*11)+(51*z/96),  4096*0+(128*12)+(24*z/96),  4096*0+(128*13)+(90*z/96),  4096*0+(128*14)+(44*z/96),  4096*1+(128*15)+(20*z/96),  
4096*0+(128* 1)+(63*z/96),  4096*0+(128* 2)+(31*z/96),  4096*0+(128* 3)+(88*z/96),  4096*0+(128* 4)+(20*z/96),  4096*0+(128* 8)+( 6*z/96),  4096*0+(128* 9)+(40*z/96),  4096*0+(128*10)+(56*z/96),  4096*0+(128*11)+(16*z/96),  4096*0+(128*12)+(71*z/96),  4096*0+(128*13)+(53*z/96),  4096*0+(128*16)+(27*z/96),  4096*1+(128*17)+(26*z/96),  
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
4096*0+(128* 1)+(81*z/96),  4096*0+(128* 3)+(28*z/96),  4096*0+(128* 6)+(14*z/96),  4096*0+(128* 7)+(25*z/96),  4096*0+(128* 8)+(17*z/96),  4096*0+(128*11)+(85*z/96),  4096*0+(128*12)+(29*z/96),  4096*0+(128*13)+(52*z/96),  4096*0+(128*14)+(78*z/96),  4096*0+(128*15)+(95*z/96),  4096*0+(128*16)+(22*z/96),  4096*1+(128*17)+(92*z/96),  
4096*0+(128* 0)+(42*z/96),  4096*0+(128* 2)+(14*z/96),  4096*0+(128* 3)+(68*z/96),  4096*0+(128* 4)+(32*z/96),  4096*0+(128* 9)+(70*z/96),  4096*0+(128*10)+(43*z/96),  4096*0+(128*11)+(11*z/96),  4096*0+(128*12)+(36*z/96),  4096*0+(128*13)+(40*z/96),  4096*0+(128*14)+(33*z/96),  4096*0+(128*15)+(57*z/96),  4096*0+(128*16)+(38*z/96),  4096*1+(128*17)+(24*z/96),  
4096*0+(128* 2)+(20*z/96),  4096*0+(128* 5)+(63*z/96),  4096*0+(128* 6)+(39*z/96),  4096*0+(128* 8)+(70*z/96),  4096*0+(128* 9)+(67*z/96),  4096*0+(128*11)+(38*z/96),  4096*0+(128*12)+( 4*z/96),  4096*0+(128*13)+(72*z/96),  4096*0+(128*14)+(47*z/96),  4096*0+(128*15)+(29*z/96),  4096*0+(128*16)+(60*z/96),  4096*1+(128*17)+( 5*z/96),  
4096*0+(128* 0)+(64*z/96),  4096*0+(128* 1)+( 2*z/96),  4096*0+(128* 4)+(63*z/96),  4096*0+(128* 7)+( 3*z/96),  4096*0+(128* 8)+(51*z/96),  4096*0+(128*10)+(81*z/96),  4096*0+(128*11)+(15*z/96),  4096*0+(128*12)+(94*z/96),  4096*0+(128*13)+( 9*z/96),  4096*0+(128*14)+(85*z/96),  4096*0+(128*15)+(36*z/96),  4096*0+(128*16)+(14*z/96),  4096*1+(128*17)+(19*z/96),  
4096*0+(128* 1)+(53*z/96),  4096*0+(128* 2)+(60*z/96),  4096*0+(128* 3)+(80*z/96),  4096*0+(128* 5)+(26*z/96),  4096*0+(128* 6)+(75*z/96),  4096*0+(128*11)+(86*z/96),  4096*0+(128*12)+(77*z/96),  4096*0+(128*13)+( 1*z/96),  4096*0+(128*14)+( 3*z/96),  4096*0+(128*15)+(72*z/96),  4096*0+(128*16)+(60*z/96),  4096*1+(128*17)+(25*z/96),  
4096*0+(128* 0)+(77*z/96),  4096*0+(128* 4)+(15*z/96),  4096*0+(128* 5)+(28*z/96),  4096*0+(128* 7)+(35*z/96),  4096*0+(128* 9)+(72*z/96),  4096*0+(128*10)+(30*z/96),  4096*0+(128*11)+(68*z/96),  4096*0+(128*12)+(85*z/96),  4096*0+(128*13)+(84*z/96),  4096*0+(128*14)+(26*z/96),  4096*0+(128*15)+(64*z/96),  4096*0+(128*16)+(11*z/96),  4096*1+(128*17)+(89*z/96),  
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
4096*0+(128* 0)+( 1*z/96),  4096*0+(128* 1)+(25*z/96),  4096*0+(128* 2)+(55*z/96),  4096*0+(128* 4)+(47*z/96),  4096*0+(128* 5)+( 4*z/96),  4096*0+(128* 7)+(91*z/96),  4096*0+(128* 8)+(84*z/96),  4096*0+(128* 9)+( 8*z/96),  4096*0+(128*10)+(86*z/96),  4096*0+(128*11)+(52*z/96),  4096*0+(128*12)+(82*z/96),  4096*0+(128*13)+(33*z/96),  4096*0+(128*14)+( 5*z/96),  4096*0+(128*15)+( 0*z/96),  4096*0+(128*16)+(36*z/96),  4096*0+(128*17)+(20*z/96),  4096*0+(128*18)+( 4*z/96),  4096*1+(128*19)+(77*z/96),  
4096*0+(128* 1)+( 6*z/96),  4096*0+(128* 3)+(36*z/96),  4096*0+(128* 4)+(40*z/96),  4096*0+(128* 5)+(47*z/96),  4096*0+(128* 6)+(12*z/96),  4096*0+(128* 7)+(79*z/96),  4096*0+(128* 8)+(47*z/96),  4096*0+(128*10)+(41*z/96),  4096*0+(128*11)+(21*z/96),  4096*0+(128*12)+(12*z/96),  4096*0+(128*13)+(71*z/96),  4096*0+(128*14)+(14*z/96),  4096*0+(128*15)+(72*z/96),  4096*0+(128*16)+( 0*z/96),  4096*0+(128*17)+(44*z/96),  4096*0+(128*18)+(49*z/96),  4096*1+(128*19)+( 0*z/96),  
4096*0+(128* 0)+(51*z/96),  4096*0+(128* 1)+(81*z/96),  4096*0+(128* 2)+(83*z/96),  4096*0+(128* 3)+( 4*z/96),  4096*0+(128* 4)+(67*z/96),  4096*0+(128* 6)+(21*z/96),  4096*0+(128* 8)+(31*z/96),  4096*0+(128* 9)+(24*z/96),  4096*0+(128*10)+(91*z/96),  4096*0+(128*11)+(61*z/96),  4096*0+(128*12)+(81*z/96),  4096*0+(128*13)+( 9*z/96),  4096*0+(128*14)+(86*z/96),  4096*0+(128*15)+(78*z/96),  4096*0+(128*16)+(60*z/96),  4096*0+(128*17)+(88*z/96),  4096*0+(128*18)+(67*z/96),  4096*1+(128*19)+(15*z/96),  
4096*0+(128* 0)+(50*z/96),  4096*0+(128* 2)+(50*z/96),  4096*0+(128* 3)+(15*z/96),  4096*0+(128* 5)+(36*z/96),  4096*0+(128* 6)+(13*z/96),  4096*0+(128* 7)+(10*z/96),  4096*0+(128* 8)+(11*z/96),  4096*0+(128* 9)+(20*z/96),  4096*0+(128*10)+(53*z/96),  4096*0+(128*11)+(90*z/96),  4096*0+(128*12)+(29*z/96),  4096*0+(128*13)+(92*z/96),  4096*0+(128*14)+(57*z/96),  4096*0+(128*15)+(30*z/96),  4096*0+(128*16)+(84*z/96),  4096*0+(128*17)+(92*z/96),  4096*0+(128*18)+(11*z/96),  4096*1+(128*19)+(66*z/96),  
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
);
	attribute ROM_STYLE : string;
	attribute ROM_STYLE of EdgeMap	: constant is "Block";
	
	constant nb								: integer := 24;
	
	type INT_TYPE_A is array (0 to 5) of integer;
	constant mb								: INT_TYPE_A := (12, 8, 8, 6, 6, 4);
	constant kb								: INT_TYPE_A := (12,16,16,18,18,20);
	constant hbm_0							: INT_TYPE_A := ( 7*z/96, 1-z*(1/z), 95*z/96, 48*z/96, 0*z/96, 80*z/96);
	constant hbm_x							: INT_TYPE_A := ( 0*z/96, 0-z*(0/z), 0*z/96, 0*z/96, 80*z/96, 0*z/96);
	constant x								: INT_TYPE_A := ( 5, 4, 6, 3, 2, 1);
	constant EdgeCnts						: INT_TYPE_A := ( 51, 63, 64, 72, 75, 71);
	------------------------------------O------------------------------------
	------------------------------------O------------------------------------
	------------------------------------O------------------------------------
	type SLV_TYPE_A is array (31 downto 0) of std_logic_vector(z-1 downto 0);
	signal Memory						: SLV_TYPE_A := (others => (others=> '0'));
	
	signal Memory_WrAddr				: std_logic_vector(4 downto 0) := (others => '0');
	signal Memory_RdAddr				: std_logic_vector(4 downto 0) := (others => '0');
	
	signal Memory_Do					: std_logic_vector(z-1 downto 0) := (others => '0');
	signal Memory_Di					: std_logic_vector(z-1 downto 0) := (others => '0');
	
	signal i_CodeSel					: std_logic_vector(2 downto 0) := (others => '0');
	
	signal ResetState					: integer range 3 downto 0 := 0;
	
	signal rst							: std_logic := '0';
	------------------------------------O------------------------------------
	signal EdgeCntr						: std_logic_vector(6 downto 0) := (others => '0');
	signal EdgeInfo						: std_logic_vector(12 downto 0) := (others => '0');
	
	signal RowSumsWE					: std_logic := '0';
	signal r_RowSumsWE					: std_logic := '0';
	signal rr_RowSumsWE					: std_logic := '0';
	signal rrr_RowSumsWE				: std_logic := '0';
	signal rrrr_RowSumsWE				: std_logic := '0';
	
	signal v0							: std_logic_vector(z-1 downto 0) := (others => '0');
	signal prev_v0						: std_logic_vector(z-1 downto 0) := (others => '0');
	signal P0kb_v0						: std_logic_vector(z-1 downto 0) := (others => '0');
	
	signal Rotation						: std_logic_vector(logZ-1 downto 0) := (others => '0');
	signal r_Rotation					: std_logic_vector(logZ-1 downto 0) := (others => '0');
	signal NewXOR						: std_logic_vector(4 downto 0) := (others => '0');
	------------------------------------O------------------------------------
	signal Durum						: integer range 6 downto 0 := 0;
	------------------------------------O------------------------------------
	signal State						: integer range 3 downto 0 := 0;
	signal i_Po							: std_logic := '0';
	------------------------------------O------------------------------------
	signal BS_Shift						: std_logic_vector(logZ-1 downto 0) := (others => '0');
	signal BS_Di						: std_logic_vector(z-1 downto 0) := (others => '0');
	signal BS_Do						: std_logic_vector(z-1 downto 0) := (others => '0');
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
				
				if CodeSel <= 5 then
					i_CodeSel <= CodeSel;
				else
					i_CodeSel <= "000";
				end if;
				ResetState <= 1;
				rst <= '1';
			else
				rst <= '0';
				case ResetState is
				when 1 =>
					if Memory_WrAddr /= kb(conv_integer(i_CodeSel)) then
						ResetState <= 2;
					else
						Memory_WrAddr <= conv_std_logic_vector(20, 5);
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
						Ready <= '1';
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
			if EdgeCntr < EdgeCnts(conv_integer(i_CodeSel)) then
				EdgeCntr <= EdgeCntr + '1';
				
				NewXOR <= NewXOR(3 downto 0) & '1';
				
				EdgeInfo <= conv_std_logic_vector( EdgeMap(conv_integer(i_CodeSel & EdgeCntr)) , 13 );
			end if;
								-----
								--2--
								-----
			Rotation <= EdgeInfo(logZ-1 downto 0);
			Memory_RdAddr <= EdgeInfo(11 downto 7);
			rrrr_RowSumsWE <= EdgeInfo(12);
								-----
								--3--
								-----
			r_Rotation <= Rotation;
			rrr_RowSumsWE <= rrrr_RowSumsWE;
								-----
								--4--
								-----
			BS_Shift <= r_Rotation;
			BS_Di <= Memory_Do;
			
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
				v0 <= v0 xor BS_Do;
				Memory_Di <= v0 xor BS_Do;
				RowSumsWE <= r_RowSumsWE;
			end if;
			
			
			
			if rst = '1' then
				v0 <= (others => '0');
				RowSumsWE <= '0';
				r_RowSumsWE <= '0';
				rr_RowSumsWE <= '0';
				rrr_RowSumsWE <= '0';
				rrrr_RowSumsWE <= '0';
				
				EdgeCntr <= (others => '0');
				NewXOR <= (others => '0');
			end if;
			------------------------------------O------------------------------------
			-- Calculation of v0
			------------------------------------O------------------------------------
			case Durum is
			when 0 =>
				if NewXOR(4) = '1' and NewXOR(3) = '0' then
					Durum <= 1;
				end if;
			when 1 =>
				BS_Shift <= conv_std_logic_vector( z-hbm_x(conv_integer(i_CodeSel)) , logZ );
				BS_Di <= v0;
				Durum <= 2;
			when 2 =>
				Durum <= 3;
			when 3 =>
				prev_v0 <= v0;
				v0 <= BS_Do;
				Durum <= 4;
			when 4 =>
				BS_Shift <= conv_std_logic_vector( hbm_0(conv_integer(i_CodeSel)) , logZ );
				BS_Di <= v0;
				Durum <= 5;
			when 5 =>
				Durum <= 6;
			when 6 =>
				P0kb_v0 <= BS_Do;
				Durum <= 0;
			when others =>
			end case;
			
			
			if rst = '1' then
				Durum <= 0;
			end if;
			------------------------------------O------------------------------------
			-- calculation of parities
			------------------------------------O------------------------------------
			i_Po <= '0';
			case State is
			when 0 =>
				if Durum = 6 then
					Memory_RdAddr <= conv_std_logic_vector(20,5);
					State <= 1;
				end if;
			when 1 =>
				i_Po <= '1'; --outputing v0
				Do <= v0;
				
				Memory_RdAddr <= Memory_RdAddr + '1';
				State <= 2;
			when 2 =>
				i_Po <= '1';
				Do <= Memory_Do xor P0kb_v0;
				
				Memory_RdAddr <= Memory_RdAddr + 1;
				if Memory_RdAddr = 20+x(conv_integer(i_CodeSel)) then
					State <= 3;
				end if;
			when 3 =>
				i_Po <= '1';
				Do <= Memory_Do xor P0kb_v0 xor prev_v0;
				
				Memory_RdAddr <= Memory_RdAddr + 1;
				if Memory_RdAddr = 20+mb(conv_integer(i_CodeSel))-1 then
					State <= 0;
				end if;
			when others =>
			end case;
			
			
			if rst = '1' then
				State <= 0;
			end if;
		end if;
	end process;
	Po <= i_Po;
	Vo <= i_Po;
	
	Barrel_Shifter : entity work.Barrel_Shifter
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

