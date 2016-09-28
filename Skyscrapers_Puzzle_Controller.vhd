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

		-- Connections with View
		REDRAW			: out	std_logic
	);
end entity;

architecture behavioral of Skyscrapers_Puzzle_Controller is
	constant MOVEMENT_SPEED       : integer := 25;
	signal   time_to_next_move    : integer range 0 to MOVEMENT_SPEED-1;
	signal   move_time            : std_logic;
begin

	TimedMove : process(CLOCK, RESET_N)
	begin
		if (RESET_N = '0') then
			time_to_next_move  <= 0;
			move_time          <= '0';
		elsif rising_edge(CLOCK) then
			move_time <= '0';
			
			if (TIME_10MS = '1') then
				if (time_to_next_move = 0) then
					time_to_next_move  <= MOVEMENT_SPEED - 1;
					move_time          <= '1';
				else
					time_to_next_move  <= time_to_next_move - 1;
				end if;
			end if;
		end if;
	end process;

	process (CLOCK, RESET_N)
	begin
		if (RESET_N = '0') then
			REDRAW          <= '0';
		elsif rising_edge(CLOCK) then
			if (time_to_next_move = 0)
			then
				REDRAW			<= '1';
			else
				REDRAW			<= '0';
			end if;
		end if;
	end process;

end behavioral;
