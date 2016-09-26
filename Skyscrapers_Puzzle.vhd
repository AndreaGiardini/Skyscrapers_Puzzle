library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity Skyscrapers_Puzzle is

        port
        (
                CLOCK_50            : in  std_logic; -- system clock
                KEY                 : in  std_logic_vector(3 downto 0); -- four buttons
					 HEX0						: out std_logic_vector(6 downto 0); -- Seven segments display
					 HEX1						: out std_logic_vector(6 downto 0); -- Seven segments display
					 HEX2						: out std_logic_vector(6 downto 0); -- Seven segments display
					 HEX3						: out std_logic_vector(6 downto 0);	-- Seven segments display
                SW                  : in  std_logic_vector(9 downto 0); -- Switch
					 
                VGA_R               : out std_logic_vector(3 downto 0);
                VGA_G               : out std_logic_vector(3 downto 0);
                VGA_B               : out std_logic_vector(3 downto 0);
                VGA_HS              : out std_logic;
                VGA_VS              : out std_logic;
                
                SRAM_ADDR           : out   std_logic_vector(17 downto 0);
                SRAM_DQ             : inout std_logic_vector(15 downto 0);
                SRAM_CE_N           : out   std_logic;
                SRAM_OE_N           : out   std_logic;
                SRAM_WE_N           : out   std_logic;
                SRAM_UB_N           : out   std_logic;
                SRAM_LB_N           : out   std_logic
        );

end;



architecture RTL of Skyscrapers_Puzzle is

begin

end architecture;