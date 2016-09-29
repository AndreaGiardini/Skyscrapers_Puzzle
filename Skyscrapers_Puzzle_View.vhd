library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.Skyscrapers_Puzzle_Types.all;
use work.Skyscrapers_Puzzle_Package.all;
use work.Skyscrapers_Puzzle_Sprites.all;
use work.vga_package.all;

entity Skyscrapers_Puzzle_View is
	port
	(
		CLOCK				: in	std_logic;
		RESET_N			: in	std_logic;
		
		MATRIX			: in MATRIX_TYPE; -- (rows, columns)
		CONSTRAINTS		: in CONSTRAINTS_TYPE; -- Index 0: LEFT, Index 1: TOP, Index 2: BOTTOM, Index 3: RIGHT
		CURSOR_POS		: in CURSOR_POS_TYPE;
		
		REDRAW			: in	std_logic;
		
		FB_READY			: in	std_logic;
		FB_CLEAR			: out	std_logic;
		FB_DRAW_RECT	: out std_logic;
		FB_DRAW_LINE	: out std_logic;
		FB_FILL_RECT 	: out std_logic;
		FB_FLIP 			: out std_logic;
		FB_COLOR 		: out color_type;
		FB_X0 			: out xy_coord_type;
		FB_Y0 			: out xy_coord_type;
		FB_X1 			: out xy_coord_type;
		FB_Y1 			: out xy_coord_type;
		
		QUERY_CELL 		: out block_pos_type;
		CELL_CONTENT 	: in board_cell_type
	);
end entity;

architecture behavioral of Skyscrapers_Puzzle_View is
	constant LEFT_MARGIN		: integer := 70;
	constant TOP_MARGIN		: integer := 60;
	constant BLOCK_SIZE		: integer := 90;
	constant BLOCK_SPACING	: integer := 5;
	
	type state_type is (IDLE, WAIT_FOR_READY, DRAWING);
	type substate_type is (CLEAR_SCENE, DRAW_BOARD_OUTLINE, DRAW_BOARD_BLOCKS, DRAW_BOARD_CONSTRAINTS, FLIP_FRAMEBUFFER);
	signal state 			: state_type;
	signal substate 		: substate_type;
	signal query_cell_r 	: block_pos_type;
	
begin

	QUERY_CELL <= query_cell_r;
	
	process(CLOCK, RESET_N)
		variable sprite_index, pixel_x, pixel_y, pixel_x_start_pos, pixel_y_start_pos : integer := 0;
		variable init_constraints, constraints_r, constraints_c : std_logic := '0';
	begin
	
		if (RESET_N = '0')
		then
			state <= IDLE;
			substate <= CLEAR_SCENE;
			FB_CLEAR <= '0';
			FB_DRAW_RECT <= '0';
			FB_DRAW_LINE <= '0';
			FB_FILL_RECT <= '0';
			FB_FLIP <= '0';
			query_cell_r.col <= 0;
			query_cell_r.row <= 0;
		elsif (rising_edge(CLOCK))
		then
			FB_CLEAR <= '0';
			FB_DRAW_RECT <= '0';
			FB_DRAW_LINE <= '0';
			FB_FILL_RECT <= '0';
			FB_FLIP <= '0';
			case (state) is
				when IDLE =>
					if (REDRAW = '1')
					then
						state <= DRAWING;
						substate <= CLEAR_SCENE;
					end if;
				when WAIT_FOR_READY =>
					if (FB_READY = '1')
					then
						state <= DRAWING;
					end if;
				when DRAWING =>
					state <= WAIT_FOR_READY;
					case (substate) is
						when CLEAR_SCENE =>
							FB_COLOR <= COLOR_BLACK;
							FB_CLEAR <= '1';
							substate <= DRAW_BOARD_OUTLINE;
						when DRAW_BOARD_OUTLINE =>
							FB_COLOR <= COLOR_WHITE;
							FB_X0 <= LEFT_MARGIN;
							FB_Y0 <= TOP_MARGIN;
							FB_X1 <= LEFT_MARGIN + (BOARD_COLUMNS * BLOCK_SIZE);
							FB_Y1 <= TOP_MARGIN + (BOARD_ROWS * BLOCK_SIZE);
							FB_DRAW_RECT <= '1';
							substate <= DRAW_BOARD_BLOCKS;
						when DRAW_BOARD_BLOCKS =>
							FB_X0        <= LEFT_MARGIN + (query_cell_r.col * BLOCK_SIZE) + BLOCK_SPACING;
							FB_Y0        <= TOP_MARGIN  + (query_cell_r.row * BLOCK_SIZE) + BLOCK_SPACING;
							FB_X1        <= LEFT_MARGIN + (query_cell_r.col * BLOCK_SIZE) + BLOCK_SIZE - BLOCK_SPACING;
							FB_Y1        <= TOP_MARGIN  + (query_cell_r.row * BLOCK_SIZE) + BLOCK_SIZE - BLOCK_SPACING;
							if (CURSOR_POS(0) = query_cell_r.row and CURSOR_POS(1) = query_cell_r.col)
							then
								FB_COLOR 	 <= COLOR_RED;
								FB_FILL_RECT <= '1';
							else
								FB_COLOR		 <= COLOR_WHITE;
								FB_DRAW_RECT <= '1';
							end if;
							if (query_cell_r.col /= BOARD_COLUMNS-1) then
								query_cell_r.col <= query_cell_r.col + 1;
							else
								query_cell_r .col <= 0;
								if (query_cell_r.row /= BOARD_ROWS-1) then
									query_cell_r.row <= query_cell_r.row + 1;
								else
									query_cell_r.row <= 0;
									substate  <= DRAW_BOARD_CONSTRAINTS;
								end if;
							end if;
						when DRAW_BOARD_CONSTRAINTS =>
						
                     if (init_constraints = '0') then                           
                         pixel_x_start_pos := LEFT_MARGIN / 4;
                         pixel_y_start_pos := TOP_MARGIN / 12;
                         pixel_x := pixel_x_start_pos;                   
                         pixel_y := pixel_y_start_pos;
								 init_constraints := '1';
                     end if;
						
							if (((pixel_x - pixel_x_start_pos) /= SPRITE_SIZE) and ((pixel_y - pixel_y_start_pos) /= SPRITE_SIZE)) then
                        FB_COLOR 	 <= nine_sprite(sprite_index);     
                        FB_X0        <= pixel_x;                    
                        FB_Y0        <= pixel_y;                    
                        FB_X1        <= pixel_x+1;                  
                        FB_Y1        <= pixel_y+1;                  
                        FB_FILL_RECT <= '1';                        
                        sprite_index := sprite_index + 1;           
                                                                                  
                        pixel_x := pixel_x + 1;                     
                        if ((pixel_x - pixel_x_start_pos) = SPRITE_SIZE) then 
                            pixel_x := pixel_x_start_pos;           
                            pixel_y := pixel_y + 1;                 
                        end if;
							else
								substate  <= FLIP_FRAMEBUFFER;
								init_constraints := '0';
								sprite_index := 0;
							end if;
						when FLIP_FRAMEBUFFER =>
							FB_FLIP <= '1';
							state <= IDLE;
					end case;
			end case;
		end if;
	end process;
end behavioral;