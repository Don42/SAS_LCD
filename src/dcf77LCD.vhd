LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
--USE ieee.std_logic_unsigned.ALL;


ENTITY dcf77LCD IS
  PORT (
    resn    : IN std_logic;
    clk1kHz : IN std_logic;
    MESZ    : IN std_logic;                     -- MEZ/MESZ 0/1
    s       : IN std_logic_vector(7 DOWNTO 0);  -- Sekunde
    mi      : IN std_logic_vector(6 DOWNTO 0);  -- Minute
    h       : IN std_logic_vector(5 DOWNTO 0);  -- Stunde
    d       : IN std_logic_vector(5 DOWNTO 0);  -- Kalendertag
    dn      : IN std_logic_vector(2 DOWNTO 0);  -- Wochentag
    mo      : IN std_logic_vector(4 DOWNTO 0);  -- Monat
    y       : IN std_logic_vector(7 DOWNTO 0);  -- Jahr

    LCD_DATA   : OUT std_logic_vector(7 DOWNTO 0);
    LCD_ENABLE : OUT std_logic;
    LCD_REGSEL : OUT std_logic;
    LCD_RW     : OUT std_logic
    );
END dcf77LCD;



ARCHITECTURE synth OF dcf77LCD IS

  FUNCTION CharToStd (Char : character) RETURN std_logic_vector IS
  BEGIN
    CASE Char IS
      WHEN ' ' => RETURN x"20";         -- space
      WHEN '-' => RETURN x"2D";
      WHEN 'A' => RETURN x"41";
      WHEN 'L' => RETURN x"4C";
      WHEN 'S' => RETURN x"53";
      WHEN 'a' => RETURN x"61";
      WHEN 'b' => RETURN x"62";
      WHEN 'o' => RETURN x"6F";
      WHEN 'r' => RETURN x"72";

      WHEN OTHERS => RETURN x"3F";      -- ?
    END CASE;
  END CharToStd;

  CONSTANT MUXMax     : integer := 3;
  SIGNAL   MUXCounter : integer RANGE 0 TO MUXMax;  -- LCD enable and LCD data

  CONSTANT LCD_String : string(1 TO 20) := "-----SAS-Labor------";
  
BEGIN  -- synth

  Main : PROCESS(clk1kHz, resn)
    VARIABLE LCD_Addresns : integer RANGE 0 TO 127;
    VARIABLE LCD_Temp     : std_logic_vector(7 DOWNTO 0);
    VARIABLE dayN         : string(1 TO 2);
    
  BEGIN
    IF resn = '0' THEN
      LCD_Data     <= (OTHERS => '0');  -- both digits and all segments on
      LCD_REGSEL   <= '0';
      LCD_RW       <= '0';
      LCD_Addresns := 0;
      LCD_ENABLE   <= '0';
    ELSIF rising_edge(clk1kHz) THEN
      IF MUXCounter = 0 THEN
        LCD_RW <= '0';
      ELSIF MUXCounter = 1 THEN
        LCD_ENABLE <= '1';
      ELSIF MUXCounter = 2 THEN
        CASE LCD_Addresns IS
          -- init LCD
          WHEN 0 => LCD_REGSEL <= '0';  -- register select
                    LCD_Temp := x"3C";  -- 8bit, 2 lines
          WHEN 1 => LCD_Temp   := x"0D";      -- display on, cursor blink
          WHEN 2 => LCD_Temp   := x"06";      -- inc addresns, cursor shift
          WHEN 3 => LCD_Temp   := x"01";      -- clear display
          WHEN 4 => LCD_REGSEL <= '0';  -- register select
                    LCD_Temp := x"80";  -- 1st display line
                    -- show text on LCD
          WHEN 5 TO 24 => LCD_REGSEL <= '1';  -- data select
                          LCD_Temp := CharToStd(LCD_String(LCD_Addresns -4));  -- LCDs text data

          WHEN 25 => LCD_REGSEL <= '0';  -- register select
                     LCD_Temp := x"C0";  -- 2nd display line                                                 
                     -- show date Seconds
          WHEN 26 => LCD_REGSEL <= '1';  -- data select
                     LCD_Temp := "0000" & s(7 DOWNTO 4) OR x"30";      --1.Sek
          WHEN 27     => LCD_Temp := "0000" & s(3 DOWNTO 0) OR x"30";  --2.Sek
          WHEN OTHERS => LCD_RW   <= '1';  -- switch to read to keep display quiet
                         LCD_Addresns := 3;  -- Write again 1st Line,
        END CASE;
        LCD_Data <= LCD_Temp;           -- temp data to LCDs

        LCD_Addresns := LCD_Addresns +1;  -- next LCD characters
      ELSIF MUXCounter = 3 THEN
        LCD_ENABLE <= '0';
      END IF;

    END IF;  -- clk
  END PROCESS;

  enable_count : PROCESS (clk1kHz, resn)
  BEGIN  -- PROCESS enable_count
    IF resn = '0' THEN
      MUXCounter <= 0;
    ELSIF rising_edge(clk1kHz) THEN
      MUXCounter <= (MUXCounter +1) MOD (MUXMax +1);
    END IF;
  END PROCESS enable_count;

  Decode : PROCESS(clk1kHz)
    VARIABLE second : integer RANGE 0 to 59;
    VARIABLE minute : integer RANGE 0 to 59;
    VARIABLE hour   : integer RANGE 0 to 23;
    VARIABLE day    : integer RANGE 1 to 31;
    VARIABLE weekday: integer RANGE 1 to 7;
    VARIABLE month  : integer RANGE 1 to 12;
    VARIABLE year   : integer RANGE 0 to 99;

  BEGIN
    IF(rising_edge(clk1kHz)) THEN
        
    END IF;
  END PROCESS;

END synth;
