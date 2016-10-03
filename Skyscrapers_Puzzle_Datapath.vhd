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
		
		KEYS				: in std_logic_vector(3 downto 0);
		--MOVE_DIR			: in	std_logic_vector(3 downto 0);
		--NUM_ROWS			: in	integer; -- Number of rows/columns and constraints (n)
		--INPUT_NUMBER	: in	integer; -- Number to input at cursor position
		
		READY				: out	std_logic;
		VICTORY			: out std_logic;
		MATRIX			: out MATRIX_TYPE; -- (rows, columns)
		CONSTRAINTS		: out CONSTRAINTS_TYPE; -- Index 0: LEFT, Index 1: TOP, Index 2: BOTTOM, Index 3: RIGHT
		CURSOR_POS		: out CURSOR_POS_TYPE;
		WINNER			: out std_logic
	);
end entity;

architecture behavior of Skyscrapers_Puzzle_Datapath is
	signal constraint_array		: CONSTRAINTS_TYPE := ((1, 2, 3, 3), (1, 2, 2, 3), (3, 2, 2, 1), (3, 3, 2, 1));
	signal matrix_array			: MATRIX_TYPE := ((others=> (others=> 0)));
	signal cursor_position		: CURSOR_POS_TYPE;
	signal num_rows				: integer := 4;
	signal win						: std_logic := '0';
	
begin
	process(CLOCK, RESET_N, constraint_array, cursor_position, num_rows)
		variable max : integer := 0;
		variable top1 : integer := 0;
		variable top2 : integer := 0;
		variable r : integer := 0;
	begin
		CONSTRAINTS <= constraint_array;
		if (RESET_N='0') then
			win <= '0'; WINNER <= '0';
			CURSOR_POS <= (0, 0);
			cursor_position <= (0, 0);
			matrix_array <= ((others=> (others=> 0)));
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
			
			MATRIX <= matrix_array;
			if ( KEYS = "0000" ) then
				matrix_array(cursor_position(1), cursor_position(0)) <= 0;
			elsif ( KEYS = "0001" ) then
				matrix_array(cursor_position(1), cursor_position(0)) <= 1;
			elsif ( KEYS = "0010" ) then
				matrix_array(cursor_position(1), cursor_position(0)) <= 2;
			elsif ( KEYS = "0011" ) then
				matrix_array(cursor_position(1), cursor_position(0)) <= 3;
			elsif ( KEYS = "0100" ) then
				matrix_array(cursor_position(1), cursor_position(0)) <= 4;
			elsif ( KEYS = "0101" ) then
				matrix_array(cursor_position(1), cursor_position(0)) <= 5;
			elsif ( KEYS = "0110" ) then
				matrix_array(cursor_position(1), cursor_position(0)) <= 6;
			elsif ( KEYS = "0111" ) then
				matrix_array(cursor_position(1), cursor_position(0)) <= 7;
			elsif ( KEYS = "1000" ) then
				matrix_array(cursor_position(1), cursor_position(0)) <= 8;
			elsif ( KEYS = "1001" ) then
				matrix_array(cursor_position(1), cursor_position(0)) <= 9;
			end if;
			
			-- check matrix constraints
			WINNER <= win;
			win <= '1';
			for r in 0 to 3 loop
				max := 0;
				top1 := 0;
				top2 := 0;
				
				for c in 0 to 3 loop
					if matrix_array(c,r) > max then
						max :=  matrix_array (c,r);
						top1 := top1 + 1;
					end if;
				end loop;
				
				max := 0;
				for c in 3 downto 0 loop
					if matrix_array(c,r) > max then
						max :=  matrix_array (c,r);
						top2 := top2 + 1;
					end if;
				end loop;
				
				if constraint_array(0,r) /= top1 or constraint_array(3,r) /= top2 then
					win <= '0';
				end if;
			end loop;
			
		end if;
	end process;
end behavior;
