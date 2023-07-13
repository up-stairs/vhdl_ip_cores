--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:51:48 08/26/2011
-- Design Name:   
-- Module Name:   H:/Issel/YNHK/WiMAX_LDPC/WiMAX_LDPC_DECODER/T_VNP_Top.vhd
-- Project Name:  WiMAX_LDPC
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: VNP_Top
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
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY T_VNP_Top IS
END T_VNP_Top;
 
ARCHITECTURE behavior OF T_VNP_Top IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
    

   --Inputs
   signal clk : std_logic := '0';
   signal Start : std_logic := '0';
   signal LM_Dv : std_logic := '0';
   signal LM_Do : std_logic_vector(15 downto 0) := (others => '0');

 	--Outputs
   signal LM_RdEn : std_logic;
   signal LM_RdAddr : std_logic_vector(6 downto 0);
   signal Finished : std_logic;
   signal LM_WrEn : std_logic;
   signal LM_WrAddr : std_logic_vector(6 downto 0);
   signal LM_Di : std_logic_vector(15 downto 0);
   signal HDM_Di : std_logic_vector(1 downto 0);
   signal ROTo : std_logic_vector(6 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
	clk <= not clk after 500 ps;
	
	process(clk)
		variable k		: integer := 0;
	begin
		if rising_edge(clk) then
			k := k + 1;
			
			Start <= '0';
			if k = 10 then
				Start <= '1';
			end if;
			LM_Dv <= LM_RdEn;
		end if;
	end process;
	-- Instantiate the Unit Under Test (UUT)
   uut: entity work.VNP_Top PORT MAP (
          clk => clk,
          Start => Start,
          LM_RdEn => LM_RdEn,
          LM_RdAddr => LM_RdAddr,
          LM_Dv => LM_Dv,
          LM_Do => LM_Do,
          Finished => Finished,
          LM_WrEn => LM_WrEn,
          LM_WrAddr => LM_WrAddr,
          LM_Di => LM_Di,
          HDM_Di => HDM_Di,
          ROTo => ROTo
        );
END;
