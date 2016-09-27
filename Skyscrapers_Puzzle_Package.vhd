library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

package Skyscrapers_Puzzle_Package is
	constant MAX_X				: positive := 512;
	constant MAX_Y				: positive := 480;
	constant BOARD_COLUMNS	: positive := 4;
	constant BOARD_ROWS		: positive := 4;

	type block_pos_type is record
		col		: integer range 0 to (BOARD_COLUMNS-1);
		row		: integer range 0 to (BOARD_ROWS-1);
	end record;
	
	type board_cell_type is record
		number	: integer;
	end record;
end package;