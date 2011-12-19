-------------------------------------------------------------------------------
-- Title      : SAS dcf77 LCD Testbench
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tb_dcf77LCD.vhd
-- Author     : Marco Kaulea
-- Created    : 2011-12-18
-- Last update: 2011-12-18
-------------------------------------------------------------------------------
-- Description: Simulate dcf77 receiver to test LCD Outputs 
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_dcf77LCD is
end tb_dcf77LCD;


architecture testbench of tb_dcf77LCD is

  -- Define constants: duration of clk period
  constant clk_period_c : time    := 1 ms;

  
  -- Component declaration 
  component dcf77LCD 
    port 
    (
      clk1kHz   : in  std_logic;
      resn      : in  std_logic;
      MESZ      : in  std_logic;      
      s         : in  std_logic_vector(7 downto 0);
      mi        : in  std_logic_vector(6 downto 0);
      h         : in  std_logic_vector(5 downto 0);
      d         : in  std_logic_vector(5 downto 0);
      dn        : in  std_logic_vector(2 downto 0);
      mo        : in  std_logic_vector(4 downto 0);
      y         : in  std_logic_vector(7 downto 0);

    
      --Outputs
      LCD_DATA  : out std_logic_vector(7 downto 0);
      LCD_ENABLE: out std_logic;
      LCD_REGSEL: out std_logic;
      LCD_RW    : out std_logic
    );
  end component;

  
  -- Define the needed signals
  signal sig_clk    : std_logic := '0';
  signal sig_rst_n  : std_logic := '0';
  signal sig_mesz   : std_logic := '0';

  signal sig_second : std_logic_vector(7 downto 0) := "00000000";
  signal sig_minute : std_logic_vector(6 downto 0) := "0000000";
  signal sig_hour   : std_logic_vector(5 downto 0) := "000000";
  signal sig_day    : std_logic_vector(5 downto 0) := "000000";
  signal sig_weekday: std_logic_vector(2 downto 0) := "000";
  signal sig_month  : std_logic_vector(4 downto 0) := "00000";
  signal sig_year   : std_logic_vector(7 downto 0) := "00000000";

  signal sig_lcd_data       : std_logic_vector(7 downto 0);
  signal sig_lcd_enable     : std_logic;
  signal sig_lcd_regsel     : std_logic;
  signal sig_lcd_rw         : std_logic;


  
begin  -- testbench

  -- Instantiate  and connect the ports to testbench's signals
  lcd  : dcf77LCD
    port map 
    (
        clk1kHz => sig_clk,
        resn    => sig_rst_n,
        MESZ    => sig_mesz,
        
        s   => sig_second,
        mi  => sig_minute,
        h   => sig_hour,
        d   => sig_day,
        dn  => sig_weekday,
        mo  => sig_month,
        y   => sig_year,

        LCD_DATA    => sig_lcd_data,
        LCD_ENABLE  => sig_lcd_enable,
        LCD_REGSEL  => sig_lcd_regsel,
        LCD_RW      => sig_lcd_rw
    );

  -- Reset 
  sig_rst_n <= '1' after clk_period_c*2;

  -- purpose: Generate clock signal
  -- type   : combinational
  -- inputs : clk  (this is a special case for test purposes!)
  -- outputs: clk  (this is a special case for test purposes!)
  clk_gen : process (sig_clk)
  begin  -- process clk_gen
    sig_clk <= not sig_clk after clk_period_c/2;
  end process clk_gen;



  -- purpose: Generate all possible inputs values and check the result
  -- type   : sequential
  -- inputs : clk, rst_n
  -- outputs: term1_r, term2_r  
  input_gen : process (sig_clk, sig_rst_n)
  begin  -- process input_gen_output_check
    if sig_rst_n = '0' then                 -- asynchronous reset (active low)

      sig_second    <= (others => '0');
      sig_minute    <= (others => '0');
      sig_hour      <= (others => '0');
      sig_day       <= (others => '0');
      sig_weekday   <= (others => '0');
      sig_month     <= (others => '0');
      sig_year      <= (others => '0');
      
    end if;
  end process input_gen;



end testbench;