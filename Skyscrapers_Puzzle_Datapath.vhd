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
		SOLVE				: in	std_logic;
		
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
	signal constraint_array		: CONSTRAINTS_TYPE := ((1, 3, 3, 2), (1, 4, 2, 3), (2, 1, 2, 2), (3, 2, 1, 3));
	--signal constraint_array		: CONSTRAINTS_TYPE := ((2, 3, 1, 2), (2, 1, 4, 2), (2, 3, 1, 3), (2, 1, 3, 2));
	--signal constraint_array		: CONSTRAINTS_TYPE := ((1, 2, 3, 3), (1, 2, 2, 3), (3, 2, 2, 1), (3, 3, 2, 1));
	signal matrix_array			: MATRIX_TYPE := ((others=> (others=> 0)));
	signal solutions				: SOLUTIONS_TYPE := ((others => (others => (others => '1'))));
	signal cursor_position		: CURSOR_POS_TYPE;
	signal num_rows				: integer := 4;
	signal win						: std_logic := '0';
	
	function possible_values (
		row		: integer;
		column	: integer
	) return integer is
	variable total : integer := 0;
	begin
		for n in 0 to 3 loop
			if (solutions(row, column, n)='1') then
				total := total +1;
			end if;
		end loop;
		return total;
	end;
	
	procedure remove_solution_from_row (
		row		: integer;
		number	: integer
	) is
	begin
		for c in 0 to 3 loop
			solutions(row, c, number-1) <= '0';
		end loop;
	end;

	procedure remove_solution_from_column (
		column	: integer;
		number	: integer
	) is
	begin
		for r in 0 to 3 loop
			solutions(r, column, number-1) <= '0';
		end loop;
	end;

	procedure add_solution_to_row (
		row		: integer;
		number	: integer
	) is
	begin
		for c in 0 to 3 loop
			solutions(row, c, number-1) <= '1';
		end loop;
	end;

	procedure add_solution_to_column (
		column	: integer;
		number	: integer
	) is
	begin
		for r in 0 to 3 loop
			solutions(r, column, number-1) <= '1';
		end loop;
	end;

	procedure remove_solution_from_cell (
		row		: integer;
		column	: integer;
		number	: integer
	) is
	begin
		solutions(row, column, number-1) <= '0';
	end;
	
	procedure insert_value (
		row		: integer;
		column	: integer;
		number	: integer
	) is
	begin
		if (number /= 0) then
			remove_solution_from_row(row, number);
			remove_solution_from_column(column, number);
			for n in 0 to 3 loop
				if (n = number - 1) then
					solutions(row, column, n) <= '1';
				else
					
					solutions(row, column, n) <= '0';
				end if;
			end loop;
		else
			add_solution_to_row(row, matrix_array(row, column));
			add_solution_to_column(column, matrix_array(row, column));
		end if;
	end;
		
begin

	process(CLOCK, RESET_N, SOLVE, cursor_position)
		variable max : integer := 0;
		variable top1 : integer := 0;
		variable top2 : integer := 0;
		variable r : integer := 0;
		variable solution		: integer := 0;
		variable sol_count	: integer := 0;
		variable position		: integer := 0;
		variable pos_count	: integer := 0;
		variable reverse		: integer := 0;
		variable maxindex		: integer := 0;
		variable number		: integer := 0;
		variable innerMax		: integer := 0;
		variable innerTop1	: integer := 0;
	begin
		CONSTRAINTS <= constraint_array;
		if (RESET_N='0') then
			win <= '0'; WINNER <= '0';
			CURSOR_POS <= (0, 0);
			cursor_position <= (0, 0);
			solutions <= ((others => (others => (others => '1'))));
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
			
			if ( KEYS = "0000" ) then
				insert_value(cursor_position(1), cursor_position(0), 0);
			elsif ( KEYS = "0001" ) then
				insert_value(cursor_position(1), cursor_position(0), 1);
			elsif ( KEYS = "0010" ) then
				insert_value(cursor_position(1), cursor_position(0), 2);
			elsif ( KEYS = "0011" ) then
				insert_value(cursor_position(1), cursor_position(0), 3);
			elsif ( KEYS = "0100" ) then
				insert_value(cursor_position(1), cursor_position(0), 4);
			end if;
			
			if (SOLVE = '1') then
			
				-- Rule: constraint = 4
				for r in 0 to 3 loop
					if (constraint_array(0, r) = 4) then
						insert_value(0, r, 1);
						insert_value(1, r, 2);
						insert_value(2, r, 3);
						insert_value(3, r, 4);
					end if;
					if (constraint_array(3, r) = 4) then
						insert_value(3, r, 1);
						insert_value(2, r, 2);
						insert_value(1, r, 3);
						insert_value(0, r, 4);
					end if;
				end loop;
				for c in 0 to 3 loop
					if (constraint_array(1, c) = 4) then
						insert_value(c, 0, 1);
						insert_value(c, 1, 2);
						insert_value(c, 2, 3);
						insert_value(c, 3, 4);
					end if;
					if (constraint_array(2, c) = 4) then
						insert_value(c, 3, 1);
						insert_value(c, 2, 2);
						insert_value(c, 1, 3);
						insert_value(c, 0, 4);
					end if;
				end loop;
			
				-- Rule: constraint = 1
				for r in 0 to 3 loop
					if (constraint_array(0, r) = 1) then
						insert_value(0, r, 4);
					end if;
					if (constraint_array(3, r) = 1) then
						insert_value(3, r, 4);
					end if;
				end loop;
				for c in 0 to 3 loop
					if (constraint_array(1, c) = 1) then
						insert_value(c, 0, 4);
					end if;
					if (constraint_array(2, c) = 1) then
						insert_value(c, 3, 4);
					end if;
				end loop;
				
				-- Rule: constraint = 2
				for r in 0 to 3 loop
					if (constraint_array(0, r) = 2) then
						remove_solution_from_cell(1, r, 3);
					end if;
					if (constraint_array(3, r) = 2) then
						remove_solution_from_cell(2, r, 3);
					end if;
				end loop;
				for c in 0 to 3 loop
					if (constraint_array(1, c) = 2) then
						remove_solution_from_cell(c, 1, 3);
					end if;
					if (constraint_array(2, c) = 2) then
						remove_solution_from_cell(c, 2, 3);
					end if;
				end loop;
				
				-- Rule: constraint sum = 5
--				for r in 0 to 3 loop
--					if (constraint_array(0, r) + constraint_array(3, r) = 5) then
--						insert_value(constraint_array(0, r)-1, r, 4);
--					end if;
--				end loop;
--				for c in 0 to 3 loop
--					if (constraint_array(1, c) + constraint_array(2, c) = 5) then
--						insert_value(c, constraint_array(1, c)-1, 4);
--					end if;
--				end loop;

				-- Rule: constraint = first valid position for 4
				for r in 0 to 3 loop
					-- constraint_array(0,r)
					if (constraint_array(0,r) > 1) then
						for c in 0 to constraint_array(0,r)-2 loop
							remove_solution_from_cell(c, r, 4);
						end loop;
					end if;
					-- constraint_array(3,r)
					if (constraint_array(3,r) > 1) then
						for c in 3 to 5-constraint_array(3,r) loop
							remove_solution_from_cell(c, r, 4);
						end loop;
					end if;
				end loop;
				for c in 0 to 3 loop
					-- constraint_array(1,c)
					if (constraint_array(1,c) > 1) then
						for r in 0 to constraint_array(1,c)-2 loop
							remove_solution_from_cell(c, r, 4);
						end loop;
					end if;
					-- constraint_array(2,c)
					if (constraint_array(2,c) > 1) then
						for r in 3 to 5-constraint_array(2,c) loop
							remove_solution_from_cell(c, r, 4);
						end loop;
					end if;
				end loop;
			end if;
			
			-- Rule: check only possible position for value
			for r in 0 to 3 loop
				for n in 0 to 3 loop
					position := 0;
					pos_count := 0;
					for c in 0 to 3 loop
						if (solutions(c, r, n) = '1') then
							position := c;
							pos_count := pos_count +1;
						end if;
					end loop;
					if (pos_count = 1) then
						insert_value(position, r, n+1);
					end if;
				end loop;
			end loop;
			for c in 0 to 3 loop
				for n in 0 to 3 loop
					position := 0;
					pos_count := 0;
					for r in 0 to 3 loop
						if (solutions(c, r, n) = '1') then
							position := r;
							pos_count := pos_count +1;
						end if;
					end loop;
					if (pos_count = 1) then
						insert_value(c, position, n+1);
					end if;
				end loop;
			end loop;
			
			-- "Intuitive" rule: check if possible value breaks constraint
			for r in 0 to 3 loop
				reverse := 0;
				maxindex := 0;
				for c in 0 to 3 loop
					if (matrix_array(c,r)=4) then
						maxindex := c;
					end if;
				end loop;
				max := 0;
				top1 := 0;
				top2 := 0;
				for c in 0 to 3 loop	-- Column loop
					if (c < maxindex) then	-- Loop until index of element 4
						if (possible_values(c, r) = 1) then		-- Usual check for maximum value when there is only one possible value
							if (matrix_array(c, r) > max) then
								max := matrix_array(c, r);
								top1 := top1 + 1;
							end if;
						else	-- Multiple solutions are possible
							for n in 0 to 3 loop	-- Loop on all possible solutions
								innerMax := max;
								innerTop1 := top1;
								if (solutions(c,r,n) = '1') then	-- Proceed only if n is a possible solution
									if (n+1 > innerMax) then
										innerMax := n+1;
										innerTop1 := innerTop1+1;
									end if;
									for c2 in c+1 to 3 loop	-- Loop on the remaining columns
										if (c2 <= maxindex) then
											if (matrix_array(c2, r) > innerMax) then
												innerMax := matrix_array(c2, r);
												innerTop1 := innerTop1+1;
											end if;
										end if;
									end loop;
									if (constraint_array(0,r) /= innerTop1) then
										remove_solution_from_cell(c, r, n+1);
									end if;
								end if;
							end loop;
							exit;
						end if;
					end if;
				end loop;
			end loop;
			
			-- check matrix constraints
			WINNER <= win;
			win <= '1';
			for r in 0 to 3 loop
				for c in 0 to 3 loop
					if (matrix_array(c, r) = 0) then
						win <= '0';
					end if;
				end loop;
			end loop;
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
			
			for r in 0 to 3 loop
				for c in 0 to 3 loop
					solution := 0;
					sol_count := 0;
					for s in 0 to 3 loop
						if (solutions(c, r, s) = '1') then
							solution := s + 1;
							sol_count := sol_count + 1;
						end if;
					end loop;
					if (sol_count = 1) then
						remove_solution_from_row(c, solution);
						remove_solution_from_column(r, solution);
						matrix_array(c, r) <= solution;
					end if;
				end loop;
			end loop;
			MATRIX <= matrix_array;
			
		end if;
	end process;
	
--	process(CLOCK, RESET_N, SOLVE)
--	begin
--		if (rising_edge(CLOCK) and SOLVE = '1') then
--			-- Regola constraint = 1
--			for r in 0 to 3 loop
--				if (constraint_array(0,r) = 1) then
--					--solutions(0,r,(3<=1, others<=0));
--					--solutions(0,r) <= (3 => '1', others => '0');
--					--solutions := (0 => (r => (3 => '1', others => '0')));
--					--matrix_array(r, 0) <= 4;
--					solutions(0, r, 0) <= '0';
--					solutions(0, r, 1) <= '0';
--					solutions(0, r, 2) <= '0';
--					solutions(0, r, 3) <= '1';
--				end if;
--			end loop;
--		end if;
--	end process;
	
--	editMatrix: process(RESET_N, solutions)
--		variable solution		: integer := 0;
--		variable sol_count	: integer := 0;
--	begin
--		if (RESET_N='0') then
--			matrix_array <= ((others=> (others=> 0)));
--		end if;
--		-- Add known results to matrix
--		for r in 0 to 3 loop
--			for c in 0 to 3 loop
--				solution := 0;
--				sol_count := 0;
--				for s in 0 to 3 loop
--					if (solutions(c, r, s) = '1') then
--						solution := s + 1;
--						sol_count := sol_count + 1;
--					end if;
--				end loop;
--				if (sol_count = 1) then
--					matrix_array(c, r) <= solution;
--				end if;
--			end loop;
--		end loop;
--		MATRIX <= matrix_array;
--	end process;
end behavior;
