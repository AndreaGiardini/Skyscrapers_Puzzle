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

		BUTTON_RIGHT   : in  std_logic;
		BUTTON_LEFT    : in  std_logic;
		BUTTON_DOWN    : in  std_logic;
		BUTTON_UP		: in  std_logic;
		
		CURSOR_POS		: in CURSOR_POS_TYPE;

		-- Connections with Data-Path
		MOVE_RIGHT		: out std_logic;
		MOVE_LEFT      : out std_logic;
		MOVE_DOWN		: out std_logic;
		MOVE_UP			: out std_logic;
		
		-- Connections with View
		REDRAW			: out	std_logic
	);
end entity;

architecture behavioral of Skyscrapers_Puzzle_Controller is
	constant MOVEMENT_SPEED       : integer := 25;
	signal   time_to_next_move    : integer range 0 to MOVEMENT_SPEED-1;
begin

	TimedMove : process(CLOCK, RESET_N)
	begin
		if (RESET_N = '0') then
			time_to_next_move  <= 0;
			MOVE_RIGHT <= '0';
			MOVE_LEFT <= '0';
			MOVE_DOWN <= '0';
			MOVE_UP <= '0';
			REDRAW <= '1';
		elsif rising_edge(CLOCK) then
			MOVE_RIGHT <= '0';
			MOVE_LEFT <= '0';
			MOVE_DOWN <= '0';
			MOVE_UP <= '0';
			REDRAW <= '0';			
			if (TIME_10MS = '1') then
				MOVE_RIGHT <= '0';
				REDRAW <= '0';
				if (time_to_next_move = 0) then
					time_to_next_move  <= MOVEMENT_SPEED - 1;
					if (BUTTON_RIGHT = '1' and cursor_pos(1) < 3) then
						MOVE_RIGHT <= '1';
						REDRAW <= '1';
					elsif (BUTTON_LEFT = '1' and cursor_pos(1) > 0) then
						MOVE_LEFT <= '1';
						REDRAW <= '1';
					elsif (BUTTON_DOWN = '1' and cursor_pos(0) < 3) then
						MOVE_DOWN <= '1';
						REDRAW <= '1';
					elsif (BUTTON_UP = '1' and cursor_pos(0) > 0) then
						MOVE_UP <= '1';
						REDRAW <= '1';
					end if;
				else
					time_to_next_move  <= time_to_next_move - 1;
				end if;
			end if;
		end if;
	end process;

end behavioral;
