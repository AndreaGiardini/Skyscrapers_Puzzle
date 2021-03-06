library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.Skyscrapers_Puzzle_Package.all;
use work.Skyscrapers_Puzzle_Types.all;

entity Skyscrapers_Puzzle_Controller is
	port
	(
		CLOCK				: in std_logic;
		keyboardData	: in std_logic_vector (7 downto 0);
		RESET_N        : in std_logic;
		TIME_10MS      : in std_logic;
		
		CURSOR_POS		: in CURSOR_POS_TYPE;

		-- Connections with Data-Path
		MOVE_RIGHT		: out std_logic;
		MOVE_LEFT      : out std_logic;
		MOVE_DOWN		: out std_logic;
		MOVE_UP			: out std_logic;
		NUMBER			: out std_logic_vector (3 downto 0);
		SOLVE				: out std_logic;
		CLEAN				: out std_logic
	);
end entity;

architecture behavioral of Skyscrapers_Puzzle_Controller is
	constant MOVEMENT_SPEED    : integer := 15;
	signal   time_to_next_move : integer range 0 to MOVEMENT_SPEED-1;
	
	constant keyRIGHT	: std_logic_vector(7 downto 0):=X"74";
	constant keyLEFT	: std_logic_vector(7 downto 0):=X"6B";
	constant keyUP 	: std_logic_vector(7 downto 0):=X"75";
	constant keyDOWN 	: std_logic_vector(7 downto 0):=X"72";
	constant key0		: std_logic_vector(7 downto 0):=X"45";
	constant key1  	: std_logic_vector(7 downto 0):=X"16";
	constant key2		: std_logic_vector(7 downto 0):=X"1E";
	constant key3		: std_logic_vector(7 downto 0):=X"26";
	constant key4		: std_logic_vector(7 downto 0):=X"25";
	constant keyENTER	: std_logic_vector(7 downto 0):=X"5A";
	constant keySPACE	: std_logic_vector(7 downto 0):=X"29";
begin

	MainProcess : process
	begin
		wait until rising_edge(CLOCK);
		MOVE_RIGHT <= '0';
		MOVE_LEFT  <= '0';
		MOVE_DOWN  <= '0';
		MOVE_UP 	  <= '0';
		NUMBER 	  <= "1111";
		SOLVE		  <= '0';
		CLEAN		  <= '0';
		if (TIME_10MS = '1') then
			time_to_next_move  <= time_to_next_move - 1;
		end if;
		if (RESET_N = '0') then
			time_to_next_move	<= 0;
		end if;
		if (time_to_next_move = 0) then
			time_to_next_move  <= MOVEMENT_SPEED - 1;
			case keyboardData is
				when KEYRIGHT => if ( cursor_pos(1) < 3 ) then MOVE_RIGHT <= '1'; end if;
				when KEYLEFT  => if ( cursor_pos(1) > 0 ) then MOVE_LEFT <= '1'; end if;
				when KEYUP    => if ( cursor_pos(0) > 0 ) then MOVE_UP <= '1'; end if;
				when KEYDOWN  => if ( cursor_pos(0) < 3 ) then MOVE_DOWN <= '1'; end if;
				when KEY0 	  => NUMBER <= "0000";
				when KEY1     => NUMBER <= "0001";
				when KEY2 	  => NUMBER <= "0010";
				when KEY3     => NUMBER <= "0011";
				when KEY4     => NUMBER <= "0100";
				when KEYENTER => SOLVE  <= '1';
				when KEYSPACE => CLEAN	<= '1';
				when others => -- do nothing
					MOVE_RIGHT <= '0';
					MOVE_LEFT  <= '0';
					MOVE_DOWN  <= '0';
					MOVE_UP    <= '0';
					NUMBER 	  <= "1111";
					SOLVE		  <= '0';
					CLEAN		  <= '0';
			end case;
		end if;
	end process;

end behavioral;