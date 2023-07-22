--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   08:22:55 09/14/2011
-- Design Name:   
-- Module Name:   H:/Issel/YNHK/WiMAX_LDPC/WiMAX_LDPC_DECODER/T_CNP.vhd
-- Project Name:  WiMAX_LDPC
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: CNP
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
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY T_CNP IS
END T_CNP;
 
ARCHITECTURE behavior OF T_CNP IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT CNP
    PORT(
         clk : IN  std_logic;
         Restart : IN  std_logic;
         LLRn : IN  std_logic;
         LLRi : IN  std_logic_vector(143 downto 0);
         HDi : IN  std_logic_vector(23 downto 0);
         PARv : OUT  std_logic;
         PARo : OUT  std_logic_vector(23 downto 0);
         LLRv : OUT  std_logic;
         LLRo : OUT  std_logic_vector(143 downto 0)
        );
    END COMPONENT;
    
	constant z	: integer := 24;
	constant W	: integer := 6;

	type ARRAY_TYPE_B is array (0 to 23) of std_logic_vector(5 downto 0);
	signal tLLRi						: ARRAY_TYPE_B := (others => ("011111"));
	signal tLLRo						: ARRAY_TYPE_B := (others => ("000000"));
   --Inputs
   signal clk : std_logic := '0';
   signal Restart : std_logic := '0';
   signal LLRn : std_logic := '0';
   signal LLRi : std_logic_vector(143 downto 0) := (others => '0');
   signal HDi : std_logic_vector(23 downto 0) := (others => '0');

 	--Outputs
   signal PARv : std_logic;
   signal PARo : std_logic_vector(23 downto 0);
   signal LLRv : std_logic;
   signal LLRo : std_logic_vector(143 downto 0);
BEGIN
	clk <= not clk after 5 ns;
	-- synthesis translate_off
	process(clk)
	begin
		for i in 0 to 24-1 loop
			LLRi(6*(i+1)-1 downto 6*i) <= tLLRi(i);
		end loop;
	end process;
	-- synthesis translate_on
	-- Instantiate the Unit Under Test (UUT)
   uut: CNP PORT MAP (
          clk => clk,
          Restart => Restart,
          LLRn => LLRn,
          LLRi => LLRi,
          HDi => HDi,
          PARv => PARv,
          PARo => PARo,
          LLRv => LLRv,
          LLRo => LLRo
        );
	-- synthesis translate_off
	process(clk)
	begin
		for i in 0 to z-1 loop
			tLLRo(i) <= LLRo(W*(i+1)-1 downto W*i);
		end loop;
	end process;
	-- synthesis translate_on
		
	process
	begin
		wait for 10 ns;
		Restart <= '1';
		wait for 10 ns;
		Restart <= '0';
		wait;
	end process;

END;
