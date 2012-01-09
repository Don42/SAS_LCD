LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
--USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;

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
		LCD_RW     : OUT std_logic);
END dcf77LCD;


ARCHITECTURE synth OF dcf77LCD IS

    -- Wandelt Char in Hex um.
	FUNCTION CharToStd (Char : character) RETURN std_logic_vector IS
	BEGIN
		CASE Char IS
			WHEN ' ' => RETURN x"20";
			WHEN '0' => RETURN x"30";
			WHEN '1' => RETURN x"31";
			WHEN '2' => RETURN x"32";
			WHEN '3' => RETURN x"33";
			WHEN '4' => RETURN x"34";
			WHEN '5' => RETURN x"35";
			WHEN '6' => RETURN x"36";
			WHEN '7' => RETURN x"37";
			WHEN '8' => RETURN x"38";
			WHEN '9' => RETURN x"39";
			WHEN ':' => RETURN x"3A";
			WHEN '-' => RETURN x"2D";
			WHEN 'M' => RETURN x"4D";
			WHEN 'o' => RETURN x"6F";
			WHEN 'T' => RETURN x"54";
			WHEN 'u' => RETURN x"75";
			WHEN 'W' => RETURN x"57";
			WHEN 'e' => RETURN x"65";
			WHEN 'h' => RETURN x"68";
			WHEN 'F' => RETURN x"46";
			WHEN 'r' => RETURN x"72";
			WHEN 'S' => RETURN x"53";
			WHEN 'a' => RETURN x"61";
			WHEN 'x' => RETURN x"78";
			WHEN 'U' => RETURN x"55";
			WHEN 'C' => RETURN x"43";
			WHEN '+' => RETURN x"2B";
			WHEN OTHERS => RETURN x"3F";      -- ?
		END CASE;
	END CharToStd;

     --INT must be <=9
    FUNCTION chr(int: integer) return character is
      variable c: character;
      BEGIN
        CASE int IS
            WHEN  0 => c := '0';
            WHEN  1 => c := '1';
            WHEN  2 => c := '2';
            WHEN  3 => c := '3';
            WHEN  4 => c := '4';
            WHEN  5 => c := '5';
            WHEN  6 => c := '6';
            WHEN  7 => c := '7';
            WHEN  8 => c := '8';
            WHEN  9 => c := '9';
            WHEN  others => c:= '0';
        END CASE;
      RETURN c;
    END chr;

    FUNCTION DCF77ToString (letter : std_logic_vector) RETURN string IS
        VARIABLE count : integer RANGE 0 TO 99 := 0;
        VARIABLE length: integer RANGE 0 to 7 := 0;
    BEGIN
      length := letter'length-1;
        IF length >=1 THEN
          IF(letter(0) ='1') THEN
            count := count + 1;
          END IF;
        END IF;

        IF length >=2 THEN
          IF(letter(1) ='1') THEN
            count := count + 2;
          END IF;
        END IF;

        IF length >=3 THEN
            IF(letter(2) ='1') THEN
                count := count + 4;
            END IF;
        END IF;

        IF length >=4 THEN
            IF(letter(3) ='1') THEN
                count := count + 8;
            END IF;
        END IF;

        IF length >=5 THEN
            IF(letter(4) ='1') THEN
                count := count + 10;
            END IF;
        END IF;

        IF length >=6 THEN
            IF(letter(5) ='1') THEN
                count := count + 20;
            END IF;
        END IF;

        IF length >=7 THEN
            IF(letter(6) ='1') THEN
                count := count + 40;
            END IF;
        END IF;

        IF length >=8 THEN
            IF(letter(7) ='1') THEN
                count := count + 40;
            END IF;
        END IF;

        IF (count>=10) THEN
            RETURN chr(count/10) & chr(count mod 10);
        ELSE
            RETURN '0' & chr(count);
        END IF;
    END DCF77ToString;



	-- Deklaration der Variablen, Konstanten und Signale
	CONSTANT MUXMax     : integer := 3;
	SIGNAL   MUXCounter : integer RANGE 0 TO MUXMax;  					-- LCD enable and LCD data

    SIGNAL LCD_String_1 : string(1 TO 20) := "   20xx-xx-xx  xx   ";	-- String für die erste Zeile des LCDs
	SIGNAL LCD_String_2 : string(1 TO 20) := "   xx:xx:xx UTC+x   ";	-- String für die zweite Zeile des LCDs

BEGIN

	Main : PROCESS(clk1kHz, resn)
		VARIABLE LCD_Addresns : integer RANGE 0 TO 127;					-- Wird bei jedem Zyklus um 1 erhöht
		VARIABLE LCD_Temp     : std_logic_vector(7 DOWNTO 0);


	BEGIN
		IF resn = '0' THEN
			LCD_Data     <= (OTHERS => '0');  							-- both digits and all segments on
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
					-- Initialisierung des LCD
					WHEN 0 => LCD_REGSEL <= '0'; 								-- register select
						LCD_Temp := x"3C";										-- 8bit, 2 lines
					WHEN 1 => LCD_Temp   := x"0D";  							-- display on, cursor blink
					WHEN 2 => LCD_Temp   := x"06";  							-- inc addresns, cursor shift
					WHEN 3 => LCD_Temp   := x"01";  							-- clear display
					WHEN 4 => LCD_REGSEL <= '0';  								-- register select
						LCD_Temp := x"80";  									-- Wähle erste Zeile des Displays

                    -- Schreibe die erste Zeile
					WHEN 5 TO 24 => LCD_REGSEL <= '1'; 							-- data select
                         LCD_Temp := CharToStd(LCD_String_1(LCD_Addresns - 4)); -- Schreibe erste Zeile

					-- Schalte um auf zweite Zeile
					WHEN 25 => LCD_REGSEL <= '0';  								-- register select
						LCD_Temp := x"C0";  									-- Auswahl der zweiten Zeile

                    -- Schreibe die zweite Zeile
					WHEN 26 TO 45 => LCD_REGSEL <= '1'; 						-- data select
                         LCD_Temp := CharToStd(LCD_String_2(LCD_Addresns - 25));-- Schreibe zweite Zeile

					WHEN OTHERS => LCD_RW <= '1';								-- switch to read to keep display quiet
                         LCD_Addresns := 3;  									-- Write again 1st Line
				END CASE;

				LCD_Data <= LCD_Temp;           								-- temp data to LCDs
				LCD_Addresns := LCD_Addresns + 1;  								-- next LCD characters
			ELSIF MUXCounter = 3 THEN
				LCD_ENABLE <= '0';
			END IF;
		END IF;
	END PROCESS;


	-- Zählt den MUXCounter zyklisch von 0 bis MUXMax (Konstante)
	enable_count : PROCESS (clk1kHz, resn)
	BEGIN  																		-- PROCESS enable_count
		IF resn = '0' THEN
			MUXCounter <= 0;
		ELSIF rising_edge(clk1kHz) THEN
		MUXCounter <= (MUXCounter +1) MOD (MUXMax +1);
		END IF;
	END PROCESS enable_count;

    Decode_Second   : PROCESS (s)
	BEGIN
        LCD_String_2(10) <=     chr(to_integer( unsigned(s(7 DOWNTO 4))));
        LCD_String_2(11) <=     chr(to_integer( unsigned(s(3 DOWNTO 0))));
    END PROCESS;

    Decode_Minute   : PROCESS (mi)
    BEGIN
		LCD_String_2(7 TO 8) <= DCF77ToString(mi);
    END PROCESS;


    Decode_Hour     : PROCESS (h)
    BEGIN
		LCD_String_2(4 TO 5) <= DCF77ToString(h);
    END PROCESS;

    Decode_Offset   : PROCESS (MESZ)
    BEGIN
		IF(MESZ = '0') THEN
			LCD_String_2(17) <= '1';
		ELSE
			LCD_String_2(17) <= '2';
		END IF;
    END PROCESS;

    Decode_Day      : PROCESS (d)
    BEGIN
        LCD_String_1(12 to 13) <= DCF77ToString(d);
    END PROCESS;

    Decode_Weekday  : PROCESS (dn)
    BEGIN
        CASE dn IS
            --Monday
            WHEN "001" => LCD_String_1(16 to 17) <= "Mo";
            --Tuesday
            WHEN "010" => LCD_String_1(16 to 17) <= "Tu";
            --Wednesday
            WHEN "011" => LCD_String_1(16 to 17) <= "We";
            --Thursday
            WHEN "100" => LCD_String_1(16 to 17) <= "Th";
            --Friday
            WHEN "101" => LCD_String_1(16 to 17) <= "Fr";
            --Saturday
            WHEN "110" => LCD_String_1(16 to 17) <= "Sa";
            --Sunday
            WHEN "111" => LCD_String_1(16 to 17) <= "Su";
            --Error
            WHEN OTHERS => LCD_String_1(16 to 17) <= "??";
        END CASE;
    END PROCESS;

    Decode_Month    : PROCESS (mo)
    BEGIN
        LCD_String_1(9 to 10) <= DCF77ToString(mo);

    END PROCESS;

    Decode_Year     : PROCESS (y)
    BEGIN
        LCD_String_1(6 to 7) <= DCF77ToString(y);
    END PROCESS;

END synth;
