library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.Skyscrapers_Puzzle_Types.all;

entity Skyscrapers_Puzzle_Datapath is
	port
	(
		CLOCK				: in	std_logic;
		RESET_N			: in	std_logic;
		MOVE_RIGHT		: in std_logic;
		MOVE_LEFT      : in std_logic;
		MOVE_DOWN		: in std_logic;
		MOVE_UP			: in std_logic;
		--MOVE_DIR			: in	std_logic_vector(3 downto 0);
		--NUM_ROWS			: in	integer; -- Number of rows/columns and constraints (n)
		--INPUT_NUMBER	: in	integer; -- Number to input at cursor position
		
		READY				: out	std_logic;
		VICTORY			: out std_logic;
		MATRIX			: out MATRIX_TYPE; -- (rows, columns)
		CONSTRAINTS		: out CONSTRAINTS_TYPE; -- Index 0: LEFT, Index 1: TOP, Index 2: BOTTOM, Index 3: RIGHT
		CURSOR_POS		: out CURSOR_POS_TYPE
	);
end entity;

architecture behavior of Skyscrapers_Puzzle_Datapath is
	signal current_status		: MATRIX_TYPE := (others => (others => 0)); -- Init matrix with 0 values
	signal game_win				: std_logic := '0';
	signal constraint_array		: CONSTRAINTS_TYPE;
	signal cursor_position		: CURSOR_POS_TYPE;
	signal num_rows				: integer := 4;
	
begin
	process(CLOCK, RESET_N, current_status, constraint_array, game_win, cursor_position, num_rows)
	begin
		if (RESET_N='0')
		then
			-- Initializing dummy matrix
			current_status <= (others => (others => 0));
			game_win <= '0';
			constraints <= ((1, 2, 3, 3), (1, 2, 2, 3), (3, 2, 2, 1), (3, 3, 2, 1));
			CURSOR_POS <= (0, 0);
			cursor_position <= (0, 0);
		elsif (rising_edge(CLOCK)) then
			CURSOR_POS <= cursor_position;
			if (MOVE_RIGHT = '1') then
				cursor_position(1) <= cursor_position(1) + 1;
			elsif (MOVE_LEFT = '1') then
				cursor_position(1) <= cursor_position(1) - 1;
			elsif (MOVE_DOWN = '1') then
				cursor_position(0) <= cursor_position(0) + 1;
			elsif (MOVE_UP = '1') then
				cursor_position(0) <= cursor_position(0) - 1;
			end if;
		end if;
	end process;
end behavior;
