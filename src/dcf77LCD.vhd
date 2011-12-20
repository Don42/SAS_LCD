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
			WHEN OTHERS => RETURN x"3F";      -- ?
		END CASE;
	END CharToStd;

	-- Deklaration der Variablen, Konstanten und Signale
	CONSTANT MUXMax     : integer := 3;
	SIGNAL   MUXCounter : integer RANGE 0 TO MUXMax;  							-- LCD enable and LCD data
	
    SIGNAL LCD_String_1 : string(1 TO 20) := "   xxxx-xx-xx  xx   ";			-- String für die erste Zeile des LCDs
	SIGNAL LCD_String_2 : string(1 TO 20) := "   xx:xx:xx UTC+x   ";			-- String für die zweite Zeile des LCDs
  
BEGIN  

	Main : PROCESS(clk1kHz, resn)
		VARIABLE LCD_Addresns : integer RANGE 0 TO 127;							-- Wird bei jedem Zyklus um 1 erhöht
		VARIABLE LCD_Temp     : std_logic_vector(7 DOWNTO 0);

    
	BEGIN
		IF resn = '0' THEN
			LCD_Data     <= (OTHERS => '0');  									-- both digits and all segments on
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

	
	
END synth;
