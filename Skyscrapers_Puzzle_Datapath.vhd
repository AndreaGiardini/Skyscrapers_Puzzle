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
		CLEAN				: in std_logic;
		
		KEYS				: in std_logic_vector(3 downto 0);
		
		MATRIX			: out MATRIX_TYPE; -- (rows, columns)
		CONSTRAINTS		: out CONSTRAINTS_TYPE; -- Index 0: LEFT, Index 1: TOP, Index 2: BOTTOM, Index 3: RIGHT
		SOLUTIONS		: out SOLUTIONS_TYPE;
		CURSOR_POS		: out CURSOR_POS_TYPE;
		WINNER			: out std_logic
	);
end entity;

architecture behavior of Skyscrapers_Puzzle_Datapath is
 	-- Sample puzzles
 	constant schemas				: SCHEMAS_TYPE := (
 		((3, 1, 2, 4), (2, 2, 1, 3), (3, 2, 2, 1), (2, 2, 2, 1)),	-- OK
 		((4, 2, 2, 1), (4, 2, 2, 1), (1, 2, 3, 3), (1, 2, 3, 3)),   -- OK
 		((2, 2, 1, 3), (3, 1, 2, 4), (2, 2, 2, 1), (3, 2, 2, 1)),	-- OK
 		((4, 3, 1, 2), (3, 3, 2, 1), (2, 1, 3, 3), (1, 2, 2, 2)),	-- OK
 		((2, 2, 3, 1), (3, 1, 2, 2), (1, 3, 2, 2), (3, 2, 1, 2))		-- OK
 	);
	
	signal matrix_array			: MATRIX_TYPE := ((others=> (others=> 0)));
	signal solutions_array		: SOLUTIONS_TYPE := ((others => (others => (others => '1'))));
	signal cursor_position		: CURSOR_POS_TYPE;
	signal num_rows				: integer range 0 to 4 := 4;
	signal win						: std_logic := '0';
	
	-- Returns the number of possible values in a given cell
	function possible_values (
		row		: integer range 0 to 3;
		column	: integer range 0 to 3
	) return integer is
	variable total : integer range 0 to 4:= 0;
	begin
		for n in 0 to 3 loop
			if (solutions_array(row, column, n)='1') then
				total := total +1;
			end if;
		end loop;
		return total;
	end;
	
	-- Adds a possible solution to all cells in a given row
	procedure add_solution_to_row (
		row		: integer range 0 to 3;
		number	: integer range 0 to 4
	) is
	begin
		for c in 0 to 3 loop
			solutions_array(row, c, number-1) <= '1';
		end loop;
	end;

	-- Adds a possible solution to all cells in a given column
	procedure add_solution_to_column (
		column	: integer range 0 to 3;
		number	: integer range 0 to 4
	) is
	begin
		for r in 0 to 3 loop
			solutions_array(r, column, number-1) <= '1';
		end loop;
	end;

	-- Removes a possible solution from a given cell
	procedure remove_solution_from_cell (
		row		: integer range 0 to 3;
		column	: integer range 0 to 3;
		number	: integer range 0 to 4 := 0
	) is
	begin
		if (number > 0) then
			solutions_array(row, column, number-1) <= '0';
		end if;
	end;
	
	-- Inserts a value in a given cell (removing all other 
	-- possible values so that only one is left)
	procedure insert_value (
		row		: integer range 0 to 3;
		column	: integer range 0 to 3;
		number	: integer range 0 to 4
	) is
	begin
		if (number /= 0) then
			-- Removes number from the column
			for c in 0 to 3 loop
				if (c /= column) then
					solutions_array(row, c, number-1) <= '0';
				end if;
			end loop;
			
			-- Removes number from the row
			for r in 0 to 3 loop
				if (r /= row) then
					solutions_array(r, column, number-1) <= '0';
				end if;
			end loop;
			
			-- Removes other numbers from the cell
			for n in 0 to 3 loop
				if (n = number - 1) then
					solutions_array(row, column, n) <= '1';
				else
					solutions_array(row, column, n) <= '0';
				end if;
			end loop;	
--			matrix_array(row, column) <= number;
		else -- Resets the cell
--			add_solution_to_row(row, matrix_array(row, column));
--			add_solution_to_column(column, matrix_array(row, column));
--			matrix_array(row, column) <= number;
			-- Adds number to the column
			for c in 0 to 3 loop
				if (c /= column) then
					solutions_array(row, c, matrix_array(row, column)-1) <= '1';
				end if;
			end loop;
			
			-- Adds number to the row
			for r in 0 to 3 loop
				if (r /= row) then
					solutions_array(r, column, matrix_array(row, column)-1) <= '1';
				end if;
			end loop;
			
			-- Adds other numbers to the cell
			for n in 0 to 3 loop
				solutions_array(row, column, n) <= '1';
			end loop;	
		end if;
		matrix_array(row, column) <= number;
		SOLUTIONS <= solutions_array;
	end;
	
	-- Checks if a specific constraint is satisfied
	function check_constraint (
		constraint	: integer range 1 to 4;
		values		: LINE_TYPE
	) return std_logic is
	variable max	: integer range 0 to 4 := 0;
	variable top	: integer range 0 to 4 := 0;
	begin
		for i in 0 to 3 loop
			if (values(i) > max) then
				max := values(i);
				top := top + 1;
			end if;
			if (values(i) = 4) then
				exit;
			end if;
		end loop;
		if (top = constraint) then
			return '1';
		else
			return '0';
		end if;
	end;
	
	-- Counts empty cells in a line before the highest building
	function count_empty_cells_before_max (
		values		: LINE_TYPE
	) return integer is
	variable count	: integer range 0 to 4 := 0;
	begin
		for i in 0 to 3 loop
			if (values(i) = 4) then
				exit;
			elsif (values(i) = 0) then
				count := count +1;
			end if;
		end loop;
		return count;
	end;
	
	-- Counts empty cells in a line
	function count_empty_cells (
		values		: LINE_TYPE
	) return integer is
	variable count	: integer range 0 to 4 := 0;
	begin
		for i in 0 to 3 loop
			if (values(i) = 0) then
				count := count +1;
			end if;
		end loop;
		return count;
	end;
		
begin

	process(CLOCK, RESET_N, SOLVE, cursor_position, matrix_array, solutions_array)
		variable max : integer range 0 to 4 := 0;
		variable top : integer range 0 to 4 := 0;
		variable top1 : integer range 0 to 4 := 0;
		variable top2 : integer range 0 to 4 := 0;
		variable r : integer range 0 to 4 := 0;
		variable solution		: integer range 0 to 4 := 0;
		variable sol_count	: integer range 0 to 4 := 0;
		variable position		: integer range 0 to 4:= 0;
		variable pos_count	: integer range 0 to 4 := 0;
		variable reverse		: integer range 0 to 1 := 0;
		variable maxindex		: integer range 0 to 4 := 0;
		variable zeroindex	: integer range -1 to 4 := 0;
		variable zeroindex1	: integer range -1 to 4 := 0;
		variable number		: integer range 0 to 4 := 0;
		variable innerMax		: integer range 0 to 4 := 0;
		variable innerTop		: integer range 0 to 4 := 0;
		variable checkRes		: std_logic := '0';
		variable added_value	: std_logic := '0';
		variable	tmpLine		: LINE_TYPE := (others => 0);
		variable schemaNumber: integer range 0 to 9 := 0;
	begin
 			
		CONSTRAINTS <= schemas(schemaNumber);
		if (RESET_N='0') then
			win <= '0'; WINNER <= '0';
			CURSOR_POS <= (0, 0);
			cursor_position <= (0, 0);
			solutions_array <= ((others => (others => (others => '1'))));
			matrix_array <= ((others=> (others=> 0)));
			SOLUTIONS <= solutions_array;
			MATRIX <= matrix_array;
			added_value := '0';
			if (schemaNumber = 4) then
 				schemaNumber := 0;
 			else
 				schemaNumber := schemaNumber + 1;
 			end if;
		elsif (rising_edge(CLOCK)) then
			CURSOR_POS <= cursor_position;
			
			if (CLEAN = '1') then
				matrix_array		<= ((others=> (others=> 0)));
				MATRIX				<= ((others=> (others=> 0)));
				solutions_array	<= ((others => (others => (others => '1'))));
				SOLUTIONS 			<= ((others => (others => (others => '1'))));
			end if;
			
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
				added_value := '0';
			
				-- Rule: If the constraint is four, the line contains all numbers in ascending order
				for r in 0 to 3 loop
					if (schemas(schemaNumber)(0, r) = 4 AND matrix_array(0, r) = 0) then
						insert_value(0, r, 1);
						insert_value(1, r, 2);
						insert_value(2, r, 3);
						insert_value(3, r, 4);
						added_value := '1';
						exit;
					end if;
					if (schemas(schemaNumber)(3, r) = 4 AND matrix_array(3, r) = 0) then
						insert_value(3, r, 1);
						insert_value(2, r, 2);
						insert_value(1, r, 3);
						insert_value(0, r, 4);
						added_value := '1';
						exit;
					end if;
				end loop;
				if (added_value = '0') then
					for c in 0 to 3 loop
						if (schemas(schemaNumber)(1, c) = 4 AND matrix_array(c, 0) = 0) then
							insert_value(c, 0, 1);
							insert_value(c, 1, 2);
							insert_value(c, 2, 3);
							insert_value(c, 3, 4);
							added_value := '1';
							exit;
						end if;
						if (schemas(schemaNumber)(2, c) = 4 AND matrix_array(c, 3) = 0) then
							insert_value(c, 3, 1);
							insert_value(c, 2, 2);
							insert_value(c, 1, 3);
							insert_value(c, 0, 4);
							added_value := '1';
							exit;
						end if;
					end loop;
				end if;
			
				-- Rule: If the constraint is one, the first element is four
				if (added_value = '0') then
					for r in 0 to 3 loop
						if (schemas(schemaNumber)(0, r) = 1 AND matrix_array(0, r) = 0) then
							insert_value(0, r, 4);
							added_value := '1';
							exit;
						end if;
						if (schemas(schemaNumber)(3, r) = 1 AND matrix_array(3, r) = 0) then
							insert_value(3, r, 4);
							added_value := '1';
							exit;
						end if;
					end loop;
				end if;
				if (added_value = '0') then
					for c in 0 to 3 loop
						if (schemas(schemaNumber)(1, c) = 1 AND matrix_array(c, 0) = 0) then
							insert_value(c, 0, 4);
							added_value := '1';
							exit;
						end if;
						if (schemas(schemaNumber)(2, c) = 1 AND matrix_array(c, 3) = 0) then
							insert_value(c, 3, 4);
							added_value := '1';
							exit;
						end if;
					end loop;
				end if;
				
				-- Loops on all rows to remove unfeasible values
				for r in 0 to 3 loop
					-- Rule: If the constraint is two, the second element cannot be three
					if (schemas(schemaNumber)(0, r) = 2) then
						remove_solution_from_cell(1, r, 3);
					end if;
					if (schemas(schemaNumber)(3, r) = 2) then
						remove_solution_from_cell(2, r, 3);
					end if;
					
					-- Rule: Any constraint indicates the first valid position for number four in the line
					if (schemas(schemaNumber)(0,r) > 1) then
						for c in 0 to 3 loop
 							if (c > schemas(schemaNumber)(0, r)-2) then
 								exit;
 							end if;
							remove_solution_from_cell(c, r, 4);
						end loop;
					end if;
					if (schemas(schemaNumber)(3,r) > 1) then
						for c in 3 downto 0 loop
 							if (c < 5-schemas(schemaNumber)(3,r)) then
 								exit;
 							end if;
							remove_solution_from_cell(c, r, 4);
						end loop;
					end if;
				end loop;
				
				-- Loops on all columns to remove unfeasible values
				for c in 0 to 3 loop
					-- Rule: If the constraint is two, the second element cannot be three
					if (schemas(schemaNumber)(1, c) = 2) then
						remove_solution_from_cell(c, 1, 3);
					end if;
					if (schemas(schemaNumber)(2, c) = 2) then
						remove_solution_from_cell(c, 2, 3);
					end if;
					
					-- Rule: Any constraint indicates the first valid position for number four in the line
					if (schemas(schemaNumber)(1,c) > 1) then
						for r in 0 to 3 loop
 							if (r > schemas(schemaNumber)(1,c) - 2) then
 								exit;
 							end if;
							remove_solution_from_cell(c, r, 4);
						end loop;
					end if;
					if (schemas(schemaNumber)(2,c) > 1) then
						for r in 3 downto 0 loop
							if (r < 5-schemas(schemaNumber)(2,c)) then
 								exit;
 							end if;
							remove_solution_from_cell(c, r, 4);
						end loop;
					end if;
				end loop;
				
				-- Rule: Check if there is only one possible position for any value
				for r in 0 to 3 loop
					for n in 0 to 3 loop
						position := 0;
						pos_count := 0;
						for c in 0 to 3 loop
							if (solutions_array(c, r, n) = '1') then
								position := c;
								pos_count := pos_count +1;
							end if;
						end loop;
						if (pos_count = 1) then
							for s in 0 to 3 loop
								if (s /= n) then
									remove_solution_from_cell(position, r, s+1);
								end if;
							end loop;
							insert_value(position, r, n+1);
						end if;
					end loop;
				end loop;
				for c in 0 to 3 loop
					for n in 0 to 3 loop
						position := 0;
						pos_count := 0;
						for r in 0 to 3 loop
							if (solutions_array(c, r, n) = '1') then
								position := r;
								pos_count := pos_count +1;
							end if;
						end loop;
						if (pos_count = 1) then
							for s in 0 to 3 loop
								if (s /= n) then
									remove_solution_from_cell(c, position, s+1);
								end if;
							end loop;
							insert_value(c, position, n+1);
						end if;
					end loop;
				end loop;
				
				
				-- "Intuitive" rule
				-- ROWS
				for r in 0 to 3 loop
					-- FROM LEFT
					tmpLine := (matrix_array(0, r), matrix_array(1, r), matrix_array(2, r), matrix_array(3, r));
					if ( count_empty_cells_before_max(tmpLine) = 1 ) then	-- Number of empty cells
						zeroindex := -1;
						for c in 0 to 3 loop	-- Finding empty cell
							if (tmpLine(c) = 0) then
								zeroindex := c;
								exit;
							end if;
						end loop;
						for n in 0 to 3 loop
							if (solutions_array(zeroindex, r, n) = '1') then
								tmpLine(zeroindex) := n+1;
								if (check_constraint(schemas(schemaNumber)(0, r), tmpLine) = '0') then
									remove_solution_from_cell(zeroindex, r, n+1);
								end if;
							end if;
						end loop;
					elsif ( count_empty_cells_before_max(tmpLine) = 2 AND count_empty_cells(tmpLine) = 2 ) then	-- Number of empty cells
						zeroindex := -1;
						zeroindex1 := -1;
						for c in 0 to 3 loop -- Finding empty cell
							if ( tmpLine(c) = 0 ) then
								if ( zeroindex < 0 ) then
									zeroindex := c;
								else
									zeroindex1 := c;
									exit;
								end if;
							end if;
						end loop;
						for n in 0 to 3 loop
							if (solutions_array(zeroindex, r, n) = '1') then
								tmpLine(zeroindex) := n+1;
								for n2 in 0 to 3 loop
									if (solutions_array(zeroindex1, r, n2) = '1' AND n2 /= n) then
										tmpLine(zeroindex1) := n2+1;
										if (check_constraint(schemas(schemaNumber)(0, r), tmpLine) = '0') then
											remove_solution_from_cell(zeroindex, r, n+1);
											remove_solution_from_cell(zeroindex1, r, n2+1);
										end if;
									end if;
								end loop;
							end if;
						end loop;
					end if;
					-- FROM RIGHT
					tmpLine := (matrix_array(3, r), matrix_array(2, r), matrix_array(1, r), matrix_array(0, r));
					if ( count_empty_cells_before_max(tmpLine) = 1 ) then	-- Number of empty cells
						zeroindex := -1;
						for c in 0 to 3 loop	-- Finding empty cell
							if ( tmpLine(c) = 0) then
								zeroindex := c;
								exit;
							end if;
						end loop;
						for n in 0 to 3 loop
							if (solutions_array(3-zeroindex, r, n) = '1') then
								tmpLine(zeroindex) := n+1;
								if (check_constraint(schemas(schemaNumber)(3, r), tmpLine) = '0') then
									remove_solution_from_cell(3-zeroindex, r, n+1);
								end if;
							end if;
						end loop;
					elsif ( count_empty_cells_before_max(tmpLine) = 2 AND count_empty_cells(tmpLine) = 2 ) then	-- Number of empty cells
						zeroindex := -1;
						zeroindex1 := -1;
						for c in 0 to 3 loop -- Finding empty cell
							if ( tmpLine(c) = 0 ) then
								if ( zeroindex < 0 ) then
									zeroindex := c;
								else
									zeroindex1 := c;
									exit;
								end if;
							end if;
						end loop;
						for n in 0 to 3 loop
							if (solutions_array(3-zeroindex, r, n) = '1') then
								tmpLine(zeroindex) := n+1;
								for n2 in 0 to 3 loop
									if (solutions_array(3-zeroindex1, r, n2) = '1' AND n2 /= n) then
										tmpLine(zeroindex1) := n2+1;
										if (check_constraint(schemas(schemaNumber)(3, r), tmpLine) = '0') then
											remove_solution_from_cell(3-zeroindex, r, n+1);
											remove_solution_from_cell(3-zeroindex1, r, n2+1);
										end if;
									end if;
								end loop;
							end if;
						end loop;
					end if;
				end loop;
				-- COLUMNS
				for c in 0 to 3 loop
					-- FROM TOP
					tmpLine := (matrix_array(c, 0), matrix_array(c, 1), matrix_array(c, 2), matrix_array(c, 3));
					if ( count_empty_cells_before_max(tmpLine) = 1 ) then	-- Number of empty cells
						zeroindex := -1;
						for r in 0 to 3 loop	-- Finding empty cell
							if (tmpLine(r) = 0) then
								zeroindex := r;
								exit;
							end if;
						end loop;
						for n in 0 to 3 loop
							if (solutions_array(c, zeroindex, n) = '1') then
								tmpLine(zeroindex) := n+1;
								if (check_constraint(schemas(schemaNumber)(1, c), tmpLine) = '0') then
									remove_solution_from_cell(c, zeroindex, n+1);
								end if;
							end if;
						end loop;
					elsif ( count_empty_cells_before_max(tmpLine) = 2 AND count_empty_cells(tmpLine) = 2 ) then	-- Number of empty cells
						zeroindex := -1;
						zeroindex1 := -1;
						for r in 0 to 3 loop -- Finding empty cell
							if ( tmpLine(r) = 0 ) then
								if ( zeroindex < 0 ) then
									zeroindex := r;
								else
									zeroindex1 := r;
									exit;
								end if;
							end if;
						end loop;
						for n in 0 to 3 loop
							if (solutions_array(c, zeroindex, n) = '1') then
								tmpLine(zeroindex) := n+1;
								for n2 in 0 to 3 loop
									if (solutions_array(c, zeroindex1, n2) = '1' AND n2 /= n) then
										tmpLine(zeroindex1) := n2+1;
										if (check_constraint(schemas(schemaNumber)(1, c), tmpLine) = '0') then
											remove_solution_from_cell(c, zeroindex, n+1);
											remove_solution_from_cell(c, zeroindex1, n2+1);
										end if;
									end if;
								end loop;
							end if;
						end loop;
					end if;
					-- FROM BOTTOM
					tmpLine := (matrix_array(c, 3), matrix_array(c, 2), matrix_array(c, 1), matrix_array(c, 0));
					if ( count_empty_cells_before_max(tmpLine) = 1 ) then	-- Number of empty cells
						zeroindex := -1;
						for r in 0 to 3 loop	-- Finding empty cell
							if (tmpLine(r) = 0) then
								zeroindex := r;
								exit;
							end if;
						end loop;
						for n in 0 to 3 loop
							if (solutions_array(c, 3-zeroindex, n) = '1') then
								tmpLine(zeroindex) := n+1;
								if (check_constraint(schemas(schemaNumber)(2, c), tmpLine) = '0') then
									remove_solution_from_cell(c, 3-zeroindex, n+1);
								end if;
							end if;
						end loop;
					elsif ( count_empty_cells_before_max(tmpLine) = 2 AND count_empty_cells(tmpLine) = 2 ) then	-- Number of empty cells
						zeroindex := -1;
						zeroindex1 := -1;
						for r in 0 to 3 loop -- Finding empty cell
							if ( tmpLine(r) = 0 ) then
								if ( zeroindex < 0 ) then
									zeroindex := r;
								else
									zeroindex1 := r;
									exit;
								end if;
							end if;
						end loop;
						for n in 0 to 3 loop
							if (solutions_array(c, 3-zeroindex, n) = '1') then
								tmpLine(zeroindex) := n+1;
								for n2 in 0 to 3 loop
									if (solutions_array(c, 3-zeroindex1, n2) = '1' AND n2 /= n) then
										tmpLine(zeroindex1) := n2+1;
										if (check_constraint(schemas(schemaNumber)(2, c), tmpLine) = '0') then
											remove_solution_from_cell(c, 3-zeroindex, n+1);
											remove_solution_from_cell(c, 3-zeroindex1, n2+1);
										end if;
									end if;
								end loop;
							end if;
						end loop;
					end if;
				end loop;
				
				-- Insert values for cells with only one possible solution
				for r in 0 to 3 loop
					for c in 0 to 3 loop
						solution := 0;
						sol_count := 0;
						for s in 0 to 3 loop
							if (solutions_array(c, r, s) = '1') then
								solution := s + 1;
								sol_count := sol_count + 1;
							end if;
						end loop;
						if (sol_count = 1) then
							insert_value(c, r, solution);
						end if;
					end loop;
				end loop;

				SOLUTIONS <= solutions_array;
			end if;
			
			
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
				
				if schemas(schemaNumber)(0,r) /= top1 or schemas(schemaNumber)(3,r) /= top2 then
					win <= '0';
				end if;
			end loop;
			
			
			MATRIX <= matrix_array;
			
		end if;
	end process;

end behavior;
