library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

package test_pkg is

  type t_integer_vector is array (integer range <>) of integer;
  type t_real_vector is array (integer range <>) of real;
  shared variable DEFAULT_SEEDs       : t_integer_vector(0 to 1) := (26513879, 20136548);

  impure function randn_boxm(
    var   : real := 1.0;
    mean  : real := 0.0) 
    return t_real_vector;
    
  impure function randn(
    var   : real := 0.0;
    N     : integer := 100) 
    return real;
    
  impure function randi(
    min                                     : integer := 0;
    max                                     : integer := 1) return integer;
    
  impure function randslv(
    min                                     : integer := 0;
    max                                     : integer := 1;
    size                                    : natural := 32) return std_logic_vector;
    
  impure function randr(
    min                                     : real := 0.0;
    max                                     : real := 1.0) return real;
    
  procedure echo (arg : in string := ""; constant newline : boolean := true);
  
  function asd (arg : string := ""; num_digits : natural) return string;
    
end package test_pkg;

-- Package Body Section
package body test_pkg is

  ------------------------------------------------------------------------------
  impure function randn_boxm(
    var   : real := 1.0;
    mean  : real := 0.0) 
    return t_real_vector is
    
    variable S                        : real := 1.0;
    variable V1                       : real := 0.0;
    variable V2                       : real := 0.0;
    variable U1                       : real := 0.0;
    variable U2                       : real := 0.0;
    variable return_val               : t_real_vector(0 to 1);
  begin
    -- sum of uniform numbers converge to gaussian
    while (S >= 1.0) loop
      UNIFORM(
        DEFAULT_SEEDs(0),
        DEFAULT_SEEDs(1),
        U1);
      UNIFORM(
        DEFAULT_SEEDs(0),
        DEFAULT_SEEDs(1),
        U2);
        
      V1 := 2.0 * U1 - 1.0;
      V2 := 2.0 * U2 - 1.0;
      
      S := V1 * V1 + V2 * V2;
    end loop;
    
    return_val(0) := mean + sqrt(var) * sqrt(-2 * log(S) / S) * V1;
    return_val(1) := mean + sqrt(var) * sqrt(-2 * log(S) / S) * V2;

    return return_val;
  end function;
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  impure function randn(
    var   : real := 0.0;
    N     : integer := 100) 
    return real is
    
    variable rand_num                       : real := 0.0;
    variable rand_numn                      : real := 0.0;
  begin
    -- sum of uniform numbers converge to gaussian
    for i in 0 to N-1 loop
      UNIFORM(
        DEFAULT_SEEDs(0),
        DEFAULT_SEEDs(1),
        rand_num);
      
      rand_numn := rand_numn + rand_num / N;
    end loop;

    return (rand_numn - 0.5) * sqrt(12.0) * sqrt(var);
  end function;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  impure function randi(
    min                                     : integer := 0;
    max                                     : integer := 1) return integer is

    variable pow                            : real := real(max - min);
    variable rand_num                       : real := 0.0;
  begin
    UNIFORM(
      DEFAULT_SEEDs(0),
      DEFAULT_SEEDs(1),
      rand_num);

    return integer(round((rand_num*pow)+real(min)));
  end function;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  impure function randslv(
    min                                     : integer := 0;
    max                                     : integer := 1;
    size                                    : natural := 32) return std_logic_vector is

  begin
    return std_logic_vector( to_signed(randi(min, max), size));
  end function;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  impure function randr(
    min                                     : real := 0.0;
    max                                     : real := 1.0) return real is

    variable pow                            : real := real(max - min);
    variable rand_num                       : real := 0.0;
  begin
    UNIFORM(
      DEFAULT_SEEDs(0),
      DEFAULT_SEEDs(1),
      rand_num);

    return (rand_num*pow)+min;
  end function;
  ------------------------------------------------------------------------------
  
  ------------------------------------------------------------------------------
  procedure echo (arg : in string := ""; constant newline : boolean := true) is
  begin
    if (newline) then
      std.textio.write(std.textio.output, arg & LF);
    else
      std.textio.write(std.textio.output, arg);
    end if;
  end procedure;
  ------------------------------------------------------------------------------
  
  ------------------------------------------------------------------------------
  function asd (arg : string := ""; num_digits : natural) return string is
    variable str_len : natural := arg'length;
    variable result : string(1 to num_digits);
  begin
    for i in 1 to num_digits loop
      result(i) := arg(i);
    end loop;
    return result;
  end function;
  ------------------------------------------------------------------------------
  
end package body test_pkg;