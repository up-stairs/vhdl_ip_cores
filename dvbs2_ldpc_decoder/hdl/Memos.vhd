LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity VNP_INPUT_FIFO is
	generic(
		z			: integer := 48;
		maxLogV		: integer := 4;
		W			: integer := 8
	);
	Port (
		clk			: in  std_logic;
		
		WrEn		: in  std_logic;
		Din			: in  std_logic_vector(W*z-1 downto 0);
		
		RdEn		: in  std_logic;
		Dout		: out std_logic_vector(W*z-1 downto 0)
	);
end VNP_INPUT_FIFO;

architecture Behavioral of VNP_INPUT_FIFO is	
	type fifo_type is array ((2**maxLogV)-1 downto 0) of std_logic_vector(W*z-1 downto 0);
	signal fifo 		: fifo_type  := (others => (others => '0') );
	
	signal WrAddr		: std_logic_vector(maxLogV-1 downto 0) := (others => '0');
	signal RdAddr		: std_logic_vector(maxLogV-1 downto 0) := (others => '0');
begin
	process(clk)
	begin
		if rising_edge(clk) then
			if WrEn = '1' then
				WrAddr <= WrAddr + '1';
				fifo(conv_integer(WrAddr)) <= Din;
			end if;
			if RdEn = '1' then
				RdAddr <= RdAddr + '1';
			end if;
		end if;
	end process;
	Dout <= fifo(conv_integer(RdAddr));
end Behavioral;
-------------------------------------------------------------------------------------
--=================================================================================--
--=================================================================================--
--=================================================================================--
-------------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity LLR_MEM is
	generic(
		z			: integer := 24;
		maxLogE		: integer := 11;
		W			: integer := 8
	);
	Port (
		clk			: in  std_logic;

		WrDis		: in  std_logic;
		WrDisAddr   : in  std_logic_vector(maxLogE-1 downto 0);
		WrEn		: in  std_logic;
		WrAddr      : in  std_logic_vector(maxLogE-1 downto 0);
		Din         : in  std_logic_vector(z*W-1 downto 0);
		
		RdDis		: in  std_logic;
		RdDisAddr   : in  std_logic_vector(maxLogE-1 downto 0);
		RdEn		: in  std_logic;
		RdAddr      : in  std_logic_vector(maxLogE-1 downto 0);
		Dval		: out std_logic;
		Dout		: out std_logic_vector(z*W-1 downto 0)
	);
end LLR_MEM;

architecture Behavioral of LLR_MEM is
	------------------------------------O------------------------------------
	type fifo_type is array (0 to (2**maxLogE)-1) of std_logic_vector(W*z-1 downto 0);
	signal fifo 						: fifo_type  := (others => (others => '0'));
	------------------------------------O------------------------------------
	type ARRAY_TYPE_B is array (0 to z-1) of std_logic_vector(W-1 downto 0);
	signal debug 						: ARRAY_TYPE_B  := (others => (others => '0'));
begin
	-- synthesis translate_off
	process(Din)
	begin
		for i in 0 to z-1 loop
			debug(z-1-i) <= Din(W*(i+1)-1 downto W*i);
		end loop;
	end process;
	-- synthesis translate_on
	process(clk)
	begin
		if rising_edge(clk) then
		    if WrEn = '1' then
				if WrDis = '0' or (WrDis = '1' and WrAddr < WrDisAddr) then -- VNP'den gelen gereksiz yazma isteklerini engellemek icin, 104=128-24
					fifo(conv_integer(WrAddr)) <= Din;
				end if;
		    end if;
		
			Dval <= RdEn;
			Dout <= fifo(conv_integer(RdAddr));
			if RdDis = '1' and RdAddr < RdDisAddr then -- Ilk iterasyonda bellekte onceki pakete ait llr degerleri olacagi icin
				Dout <= (others => '0');
			end if;
		end if;
	end process;
	
end Behavioral;
-------------------------------------------------------------------------------------
--=================================================================================--
--=================================================================================--
--=================================================================================--
-------------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity HD_MEM is
	generic(
		z			: integer := 96;
		maxLogE		: integer := 11
	);
	Port (
		clk			: in  std_logic;

		WrEn		: in  std_logic;
		WrAddr      : in  std_logic_vector(maxLogE-1 downto 0);
		Din         : in  std_logic_vector(z-1 downto 0);

		RdEn		: in  std_logic;
		RdAddr      : in  std_logic_vector(maxLogE-1 downto 0);
		Dval		: out std_logic;
		Dout		: out std_logic_vector(z-1 downto 0)
	);
end HD_MEM;

architecture Behavioral of HD_MEM is
	------------------------------------O------------------------------------
	type fifo_type is array (0 to (2**maxLogE)-1) of std_logic_vector(z-1 downto 0);
	signal fifo 						: fifo_type  := (others => (others => '0'));
	------------------------------------O------------------------------------
begin
	process(clk)
	begin
		if rising_edge(clk) then
		    if WrEn = '1' then
		        fifo(conv_integer(WrAddr)) <= Din;
		    end if;

			Dval <= RdEn;
			Dout <= fifo(conv_integer(RdAddr));
		end if;
	end process;

end Behavioral;