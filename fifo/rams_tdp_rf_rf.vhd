-- Dual-Port Block RAM with Two Write Ports
-- Correct Modelization with a Shared Variable
-- File: rams_tdp_rf_rf.vhd

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity rams_tdp_rf_rf is
  generic (
    G_DIO_WID     : natural := 16;
    G_RAM_SIZE    : natural := 1024
  );
  port(
    clka  : in  std_logic;
    clkb  : in  std_logic;
    ena   : in  std_logic;
    enb   : in  std_logic;
    wea   : in  std_logic;
    web   : in  std_logic;
    addra : in  std_logic_vector(natural(log2(real(G_RAM_SIZE-1))+1.0)-1 downto 0);
    addrb : in  std_logic_vector(natural(log2(real(G_RAM_SIZE-1))+1.0)-1 downto 0);
    dia   : in  std_logic_vector(G_DIO_WID-1 downto 0);
    dib   : in  std_logic_vector(G_DIO_WID-1 downto 0);
    doa   : out std_logic_vector(G_DIO_WID-1 downto 0);
    dob   : out std_logic_vector(G_DIO_WID-1 downto 0)
  );
end rams_tdp_rf_rf;

architecture syn of rams_tdp_rf_rf is
 type ram_type is array (G_RAM_SIZE-1 downto 0) of std_logic_vector(G_DIO_WID-1 downto 0);
 shared variable RAM : ram_type;
begin
 process(CLKA)
 begin
  if CLKA'event and CLKA = '1' then
   if ENA = '1' then
    DOA <= RAM(to_integer(unsigned(ADDRA)));
    if WEA = '1' then
     RAM(to_integer(unsigned(ADDRA))) := DIA;
    end if;
   end if;
  end if;
 end process;

 process(CLKB)
 begin
  if CLKB'event and CLKB = '1' then
   if ENB = '1' then
    DOB <= RAM(to_integer(unsigned(ADDRB)));
    if WEB = '1' then
     RAM(to_integer(unsigned(ADDRB))) := DIB;
    end if;
   end if;
  end if;
 end process;

end syn;
