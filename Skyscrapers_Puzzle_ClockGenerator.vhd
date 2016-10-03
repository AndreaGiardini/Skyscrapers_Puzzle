library ieee;
use  ieee.std_logic_1164.all;
use  ieee.std_logic_arith.all;
use  ieee.std_logic_unsigned.all;

ENTITY Skyscrapers_Puzzle_ClockGenerator IS
	PORT
	(	
		-- INPUT
		clock 		: IN STD_LOGIC;
		
		-- OUTPUT
		clock_mezzi : OUT STD_LOGIC
	);
END Skyscrapers_Puzzle_ClockGenerator;

ARCHITECTURE Behavioral OF Skyscrapers_Puzzle_ClockGenerator IS
	SIGNAL counter : STD_LOGIC_VECTOR(0 DOWNTO 0);
BEGIN
	PROCESS (clock)
		BEGIN
			IF clock = '0' AND clock'event THEN 
				counter <= counter + 1;
			END IF;
	END PROCESS;
	
	clock_mezzi <= counter(0);
END Behavioral;