library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

package Skyscrapers_Puzzle_Types is
	type SOLUTIONS_TYPE		is array(0 to 3, 0 to 3, 0 to 3) of std_logic;	-- Possible solutions
	type LINE_TYPE				is array(0 to 3) of integer range 0 to 4;
--	type CELL_SOLUTIONS		is array(integer range<>) of integer;
--	type SOLUTIONS_TYPE		is array(3 downto 0, 3 downto 0) of CELL_SOLUTIONS;
	type MATRIX_TYPE			is array(0 to 3, 0 to 3) of integer range 0 to 4; -- (rows, columns)
	type CONSTRAINTS_TYPE	is array(0 to 3, 0 to 3) of integer range 0 to 4; -- Index 0: LEFT, Index 1: TOP, Index 2: BOTTOM, Index 3: RIGHT
	type SCHEMAS_TYPE			is array(0 to 4) of CONSTRAINTS_TYPE;
	type CURSOR_POS_TYPE		is array(1 downto 0) of integer range 0 to 3;					-- (rows, columns)
	
	constant  SPRITE_SIZE    : integer        := 45;
end package;
