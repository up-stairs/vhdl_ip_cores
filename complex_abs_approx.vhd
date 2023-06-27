-- The code uses basic arithmetic operations and comparisons to approximate the complex absolute value 
-- without directly using square root or square operations. 
-- The approximation involves finding the maximum and minimum absolute values, applying specific weights, 
-- and summing them to obtain the final approximation.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity complex_abs_approx is
  generic (
    C_DATA_WIDTH    : natural := 16;  -- Width of input and output data
    C_USER_WIDTH    : natural := 16
  );
  port (
    clock         : in std_logic;
    reset         : in std_logic;
    clock_en      : in std_logic;
    in_valid      : in std_logic;
    in_user       : in std_logic_vector(C_USER_WIDTH-1 downto 0);
    in_real       : in signed(C_DATA_WIDTH-1 downto 0);  -- Real part of the complex number
    in_imag       : in signed(C_DATA_WIDTH-1 downto 0);  -- Imaginary part of the complex number
    out_valid     : out std_logic;
    out_user      : out std_logic_vector(C_USER_WIDTH-1 downto 0);
    out_abs       : out unsigned(C_DATA_WIDTH downto 0)  -- Approximated complex absolute value
  );
end entity complex_abs_approx;

architecture rtl of complex_abs_approx is
  signal abs_real       : unsigned(C_DATA_WIDTH-1 downto 0);  -- Rounded absolute value of the real part
  signal abs_imag       : unsigned(C_DATA_WIDTH-1 downto 0);  -- Rounded absolute value of the imaginary part
  signal max_x      : unsigned(C_DATA_WIDTH-1 downto 0);  -- Maximum absolute value
  signal min_x      : unsigned(C_DATA_WIDTH-1 downto 0);  -- Minimum absolute value
  signal cabs_temp1 : unsigned(C_DATA_WIDTH downto 0);    -- Temporary value 1 of the approximated complex absolute value
  signal cabs_temp2 : unsigned(C_DATA_WIDTH downto 0);    -- Temporary value 2 of the approximated complex absolute value
  signal cabs_temp3 : unsigned(C_DATA_WIDTH downto 0);    -- Temporary value 3 of the approximated complex absolute value
  signal cabs_sel   : std_logic_vector(1 downto 0);       -- Selection signal for determining the output
  
  signal in_valid_r1 : std_logic;
  signal in_valid_r2 : std_logic;
  signal in_valid_r3 : std_logic;
  signal in_user_r1 : std_logic_vector(C_USER_WIDTH-1 downto 0);
  signal in_user_r2 : std_logic_vector(C_USER_WIDTH-1 downto 0);
  signal in_user_r3 : std_logic_vector(C_USER_WIDTH-1 downto 0);
begin

  -- Register input signals
  process(clock, reset)
  begin
    if reset = '1' then
      in_valid_r1     <= '0';
      in_valid_r2     <= '0';
      in_valid_r3     <= '0';
      out_valid       <= '0';
    elsif rising_edge(clock) then
      in_valid_r1     <= '0';
      if (clock_en = '1') then
        in_valid_r1     <= in_valid;
        in_valid_r2     <= in_valid_r1;
        in_valid_r3     <= in_valid_r2;
        out_valid       <= in_valid_r3;
      end if;
    end if;
  end process;

  -- Register user input signal
  process(clock)
  begin
    if rising_edge(clock) then
      if (clock_en = '1') then
        in_user_r1    <= in_user;
        in_user_r2    <= in_user_r1;
        in_user_r3    <= in_user_r2;
        out_user      <= in_user_r3;
      end if;
    end if;
  end process;
  
  process(clock, reset)
  begin
    if reset = '1' then
      abs_real <= (others => '0');
      abs_imag <= (others => '0');
      max_x <= (others => '0');
      min_x <= (others => '0');
    elsif rising_edge(clock) then
      if (clock_en = '1') then
        abs_real <= unsigned(abs(in_real));  -- Absolute value of the real part
        abs_imag <= unsigned(abs(in_imag));  -- Absolute value of the imaginary part
        
        if (abs_real > abs_imag) then
          max_x <= abs_real;  -- Use abs_real as the maximum absolute value
          min_x <= abs_imag;
        else
          max_x <= abs_imag;  -- Use abs_imag as the maximum absolute value
          min_x <= abs_real;
        end if;
      end if;
    end if;
  end process;
  
  process(clock)
  begin
    if rising_edge(clock) then
      if (clock_en = '1') then
        -- cabs_temp1 <= (max_x * 255) / 256 + (min_x * 4) / 32;
        cabs_temp1 <= (resize(max_x, C_DATA_WIDTH+1) - max_x/256) + (min_x/4 - min_x/8);
        -- cabs_temp2 <= (max_x * 241) / 256 + (min_x * 11) / 32;
        cabs_temp2 <= (resize(max_x, C_DATA_WIDTH+1) - max_x/16 + max_x/256) + (min_x/4 + min_x/8 - min_x/32);
        -- cabs_temp3 <= (max_x * 208) / 256 + (min_x * 19) / 32;
        cabs_temp3 <= (resize(max_x, C_DATA_WIDTH+1) - max_x/8 - max_x/16) + (min_x/2 + min_x/8 - min_x/32);
      
        if (max_x / 4 > min_x) then
          cabs_sel <= "00";
        elsif (max_x / 2 > min_x) then
          cabs_sel <= "01";
        else
          cabs_sel <= "10";
        end if;
      end if;
    end if;
  end process;
  
  process(clock)
  begin
    if rising_edge(clock) then
      if (clock_en = '1') then
        case cabs_sel is
          when "00" =>
            out_abs <= cabs_temp1;
          when "01" =>
            out_abs <= cabs_temp2;
          when others =>
            out_abs <= cabs_temp3;
        end case;
      end if;
    end if;
  end process;

end architecture rtl;
