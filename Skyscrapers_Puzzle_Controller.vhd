library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.Skyscrapers_Puzzle_Package.all;
use work.Skyscrapers_Puzzle_Types.all;

entity Skyscrapers_Puzzle_Controller is
	port
	(
		CLOCK				: in  std_logic;
		RESET_N        : in  std_logic;
		TIME_10MS      : in  std_logic;
		
		-- Connections with Datapath
		MATRIX			: in MATRIX_TYPE; -- (rows, columns)
		CONSTRAINTS		: in CONSTRAINTS_TYPE; -- Index 0: LEFT, Index 1: TOP, Index 2: BOTTOM, Index 3: RIGHT
		CURSOR_POS		: in CURSOR_POS_TYPE;
		
		-- Connections with View
		REDRAW			: out	std_logic
	);
end entity;

architecture behavioral of Skyscrapers_Puzzle_Controller is
begin
	process (CLOCK, RESET_N)
	begin
		if (RESET_N = '0') then
			REDRAW          <= '0';
		elsif rising_edge(CLOCK) then
			REDRAW          <= '1';
		end if;
	end process;

end behavioral;
