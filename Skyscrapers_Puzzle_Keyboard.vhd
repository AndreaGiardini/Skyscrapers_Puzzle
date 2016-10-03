library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Skyscrapers_Puzzle_Keyboard is
    Port 
		( 	
			-- INPUT
			clk 				: in STD_LOGIC;
			keyboardClock 	: in STD_LOGIC;
			keyboardData 	: in STD_LOGIC;
			
			-- OUTPUT
			keyCode			: out STD_LOGIC_VECTOR(7 downto 0)
		);
end Skyscrapers_Puzzle_Keyboard;

architecture Behavioral of Skyscrapers_Puzzle_Keyboard is
	signal bitCount 		: INTEGER range 0 to 100 := 0;
	signal scanCodeReady 	: STD_LOGIC := '0';
	signal scanCode 		: STD_LOGIC_VECTOR(7 downto 0);
	signal breakReceived 	: STD_LOGIC_VECTOR(1 downto 0) := "00";
	
	-- Breakcode viene generato quando viene rilasciato il dito dal tasto della tastiera
	constant breakCode 		: STD_LOGIC_VECTOR(7 downto 0) := X"F0";
	constant arrowCode 		: STD_LOGIC_VECTOR(7 downto 0) := X"E0";
begin

	Keyboard : process(keyboardClock)
	begin
		if falling_edge(keyboardClock) 
		then
			if (bitCount = 0 and keyboardData = '0')
			then
				scanCodeReady <= '0';
				bitCount <= bitCount + 1;
			elsif bitCount > 0 and bitCount < 9 
			then
			-- si shifta di un bit lo scancode da sinistra
				scancode <= keyboardData & scancode(7 downto 1);
				bitCount <= bitCount + 1;
			-- bit di parit�
			elsif (bitCount = 9)
			then
				bitCount <= bitCount + 1;
			-- fine messaggio
			elsif (bitCount = 10) 
			then
				scanCodeReady <= '1';
				bitCount <= 0;
			end if;
		end if;		
	end process Keyboard;
	
	sendData : process(scanCodeReady, scanCode)
	begin
		if (scanCodeReady'event and scanCodeReady = '1')
		then
			if (scanCode /= breakCode and scanCode /= arrowCode )then
				keyCode <= scanCode;
			end if;
			
--			case breakReceived is
--			when "00" => 
--				if (scanCode = breakCode)
--				then
--					breakReceived <= "01";
--				end if;
--				keyCode <= scanCode;
--			when "01" =>
--				breakReceived <= "10";
--				keyCode <= breakCode;
--			when "10" =>
--				if ( scanCode = arrowCode) then
--					breakReceived <= "00";
--				else
--					breakReceived <= "01";
--					keyCode <= scanCode;
--				end if;
--			when others => 
--				keyCode <= scanCode;
--			end case;
		end if;
	end process sendData;

end Behavioral;
