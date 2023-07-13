--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   13:51:16 02/05/2011
-- Design Name:   
-- Module Name:   C:/Xilinx/xilinx_projects/WiMAX_LDPC/T_LDPC.vhd
-- Project Name:  WiMAX_LDPC
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: Encoder_C_Top
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
 
ENTITY T_LDPC IS
END T_LDPC;
 
ARCHITECTURE behavior OF T_LDPC IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Encoder_C_Top
    PORT(
         clk : IN  std_logic;
         Pi : IN  std_logic;
         Vi : IN  std_logic;
         Di : IN  std_logic_vector(95 downto 0);
         Po : OUT  std_logic;
         Vo : OUT  std_logic;
         Do : OUT  std_logic_vector(95 downto 0)
        );
    END COMPONENT;
    COMPONENT Decoder
    PORT(
         clk : IN  std_logic;
         Pi : IN  std_logic;
         Vi : IN  std_logic;
         Di : IN  std_logic_vector(767 downto 0);
		MaxIter					: in  std_logic_vector(7 downto 0);
         Vo : OUT  std_logic;
         Do : OUT  std_logic_vector(95 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal Pi : std_logic := '0';
   signal Vi : std_logic := '0';
   signal Di : std_logic_vector(95 downto 0) := (others => '0');
   signal DEC_Pi : std_logic := '0';
   signal DEC_Vi : std_logic := '0';
   signal DEC_Di : std_logic_vector(767 downto 0) := (others => '0');

 	--Outputs
   signal Po : std_logic;
   signal Vo : std_logic;
   signal Do : std_logic_vector(95 downto 0);
   signal DEC_Vo : std_logic;
   signal DEC_Do : std_logic_vector(95 downto 0);

	-- Signals
	constant z 		: integer :=96;
	constant kb		: integer :=12;
	constant mb		: integer :=12;
	constant llr	: std_logic_vector(7 downto 0) := "00110000";
	
	signal PRBS_1	: std_logic_vector(14 downto 0) := "101101001011010";
	signal PRBS_2	: std_logic_vector(14 downto 0) := "101010010110101";
	signal PRBS_4	: std_logic_vector(14 downto 0) := "101101000011010";
	signal PRBS_5	: std_logic_vector(14 downto 0) := "110001001011010";
	signal PRBS_6	: std_logic_vector(14 downto 0) := "110101001011010";
	signal PRBS_7	: std_logic_vector(14 downto 0) := "101101000000010";
	signal PRBS_8	: std_logic_vector(14 downto 0) := "101101001011111";

BEGIN
	clk <= not clk after 5 ns;
	
	process(clk)
		variable k	: integer := 0;
		variable Temp : std_logic_vector(z-1 downto 0);
		
		file RESULT_FILE: text open WRITE_MODE is "outfiles/iw.txt";		
		variable traceLine : LINE;
	begin
		if rising_edge(clk) then
			PRBS_1 <= PRBS_1(13 downto 0) & (PRBS_1(14) xor PRBS_1(13) xor '1');
			PRBS_2 <= PRBS_2(13 downto 0) & (PRBS_2(14) xor PRBS_2(13) xor '1');
			PRBS_4 <= PRBS_4(13 downto 0) & (PRBS_4(14) xor PRBS_4(13) xor '1');
			PRBS_5 <= PRBS_5(13 downto 0) & (PRBS_5(14) xor PRBS_5(13) xor '1');
			PRBS_6 <= PRBS_6(13 downto 0) & (PRBS_6(14) xor PRBS_6(13) xor '1');
			PRBS_7 <= PRBS_7(13 downto 0) & (PRBS_7(14) xor PRBS_7(13) xor '1');
			PRBS_8 <= PRBS_8(13 downto 0) & (PRBS_8(14) xor PRBS_8(13) xor '1');
			
			Pi <= '0';
			Vi <= '0';
--			if k mod 200 >= 1 and k mod 200 <= kb then
			if k > 10 and k <= kb+10 then
				Pi <= '1';
				Vi <= '1';
				Di <= PRBS_1 & PRBS_2 & PRBS_4 & PRBS_5 & PRBS_6 & PRBS_7 & PRBS_8(5 downto 0);
				
				Temp := PRBS_1 & PRBS_2 & PRBS_4 & PRBS_5 & PRBS_6 & PRBS_7 & PRBS_8(5 downto 0);
				for k in z-1 downto 0 loop
					if Temp(k) = '0' then
						write(traceLine, 0);
					else
						write(traceLine, 1);
					end if;
					writeLine(RESULT_FILE, traceLine);								
				end loop;
			end if;
			
			if DEC_Vo = '1' then
				k := 0;
			else
				k := k + 1;
			end if;
		end if;
	end process;
	-- Instantiate the Unit Under Test (UUT)
	LDPC_Encoder : Encoder_C_Top PORT MAP (
		clk => clk,
		Pi => Pi,
		Vi => Vi,
		Di => Di,
		Po => Po,
		Vo => Vo,
		Do => Do
	);

	process(clk)
--		file RESULT_FILE: text open WRITE_MODE is "outfiles/encoded.txt";		
		variable traceLine : LINE;
		variable tmp:integer;
		variable tmpstd:std_logic_vector(1 downto 0);
		variable LlrVec			: std_logic_vector(z*8-1 downto 0);
		
		variable State			: integer := 0;
		
		variable PRBS_3			: std_logic_vector(14 downto 0) := "100100100110110";
	begin
		if rising_edge(clk) then
			DEC_Vi <= Vo or Vi;
			
			DEC_Pi <= '0';
			case State is
			when 0 =>
				if Pi = '1' then
					State := 1;
					DEC_Pi <= '1';
				end if;
			when 1 =>
				DEC_Pi <= '1';
				if Pi = '0' then
					State := 2;
				end if;
			when 2 =>
				DEC_Pi <= '1';
				if Po = '1' then
					State := 3;
				end if;
			when 3 =>
				if Po = '1' then
					DEC_Pi <= '1';
				else
					State := 0;
				end if;
			when others =>
			end case;
			
			if Vi = '1' then
				for k in z-1 downto 0 loop
					PRBS_3 := PRBS_3(13 downto 0) & (PRBS_3(14) xor PRBS_3(13) xor '1');
					
					if Di(k) = '0' then
						LlrVec(k*8+7 downto k*8) := +llr + sxt(PRBS_3(6 downto 0),8);
					else
						LlrVec(k*8+7 downto k*8) := -llr + sxt(PRBS_3(6 downto 0),8);
					end if;
				end loop;
			elsif Vo = '1' then
				for k in z-1 downto 0 loop
					PRBS_3 := PRBS_3(13 downto 0) & (PRBS_3(14) xor PRBS_3(13) xor '1');
					
					if Do(k) = '0' then
						LlrVec(k*8+7 downto k*8) := +llr + sxt(PRBS_3(6 downto 0),8);
					else
						LlrVec(k*8+7 downto k*8) := -llr + sxt(PRBS_3(6 downto 0),8);
					end if;
				end loop;
			end if;
			DEC_Di <= LlrVec;
		end if;	
	end process;
	
	process(clk)
		file RESULT_FILE: text open WRITE_MODE is "outfiles/received.txt";		
		variable traceLine : LINE;
		variable tmp:integer;
		variable tmpstd:std_logic_vector(7 downto 0);
	begin
		if rising_edge(clk) then
			if DEC_Vi = '1' then
				for k in z-1 downto 0 loop												
					tmpstd := DEC_Di(k*8+7 downto k*8);
					tmp := conv_integer( tmpstd );
					write(traceLine, tmp );		
					writeLine(RESULT_FILE, traceLine);								
				end loop;
			end if;
		end if;	
	end process;
	
	LDPC_Decoder : Decoder PORT MAP (
		clk => clk,
		MaxIter => X"55",
		Pi => DEC_Pi,
		Vi => DEC_Vi,
		Di => DEC_Di,
		Vo => DEC_Vo,
		Do => DEC_Do
	);

	process(clk)
		file RESULT_FILE: text open WRITE_MODE is "outfiles/decoded.txt";		
		variable traceLine : LINE;
		variable tmp:integer;
		variable tmpstd:std_logic_vector(1 downto 0);
	begin
		if rising_edge(clk) then
			if DEC_Vo = '1' then
				for k in z-1 downto 0 loop												
					tmpstd(1 downto 0):= '0' & DEC_Do(k);
					tmp:=conv_integer(  unsigned( tmpstd)   );
					write(traceLine, tmp );		
					writeLine(RESULT_FILE, traceLine);								
				end loop;
			end if;
		end if;	
	end process;
END;
