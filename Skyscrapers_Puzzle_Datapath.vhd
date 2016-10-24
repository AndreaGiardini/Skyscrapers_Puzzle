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
		SOLUTIONS		: out SOLUTIONS_TYPE;
		CURSOR_POS		: out CURSOR_POS_TYPE;
		WINNER			: out std_logic
	);
end entity;

architecture behavior of Skyscrapers_Puzzle_Datapath is
	-- TEST FROM LEFT
	--signal constraint_array		: CONSTRAINTS_TYPE := ((1, 3, 3, 2), (1, 4, 2, 3), (2, 1, 2, 2), (3, 2, 1, 3));
	
	-- TEST FROM RIGHT
	--signal constraint_array		: CONSTRAINTS_TYPE := ((3, 2, 1, 3), (3, 2, 4, 1), (2, 2, 1, 2), (1, 3, 3, 2));
	
	-- TEST FROM TOP
	--signal constraint_array		: CONSTRAINTS_TYPE := ((2, 1, 2, 2), (2, 3, 3, 1), (3, 1, 2, 3), (1, 4, 2, 3));
	
	-- TEST FROM BOTTOM
	--signal constraint_array		: CONSTRAINTS_TYPE := ((3, 2, 4, 1), (3, 2, 1, 3), (1, 3, 3, 2), (2, 2, 1, 2));
	
	-- TEST 2 FREE FROM LEFT
	--signal constraint_array		: CONSTRAINTS_TYPE := ((2, 3, 1, 3), (2, 1, 3, 2), (2, 3, 1, 2), (2, 1, 4, 2));
	
	-- TEST 2 FREE FROM RIGHT
	--signal constraint_array		: CONSTRAINTS_TYPE := ((2, 1, 4, 2), (2, 3, 1, 2), (2, 1, 3, 2), (2, 3, 1, 3));
	
	-- TEST 2 FREE FROM TOP
	--signal constraint_array		: CONSTRAINTS_TYPE := ((2, 3, 1, 2), (3, 1, 3, 2), (2, 4, 1, 2), (2, 1, 3, 2));
	
	-- TEST 2 FREE FROM BOTTOM
	signal constraint_array		: CONSTRAINTS_TYPE := ((2, 1, 3, 2), (2, 4, 1, 2), (3, 1, 3, 2), (2, 3, 1, 2));
	
	--signal constraint_array		: CONSTRAINTS_TYPE := ((2, 1, 3, 2), (2, 1, 4, 2), (2, 3, 1, 3), (2, 3, 1, 2));
	--signal constraint_array		: CONSTRAINTS_TYPE := ((1, 2, 3, 3), (1, 2, 2, 3), (3, 2, 2, 1), (3, 3, 2, 1));
	signal matrix_array			: MATRIX_TYPE := ((others=> (others=> 0)));
	signal solutions_array		: SOLUTIONS_TYPE := ((others => (others => (others => '1'))));
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
			if (solutions_array(row, column, n)='1') then
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
			solutions_array(row, c, number-1) <= '0';
		end loop;
	end;

	procedure remove_solution_from_column (
		column	: integer;
		number	: integer
	) is
	begin
		for r in 0 to 3 loop
			solutions_array(r, column, number-1) <= '0';
		end loop;
	end;

	procedure add_solution_to_row (
		row		: integer;
		number	: integer
	) is
	begin
		for c in 0 to 3 loop
			solutions_array(row, c, number-1) <= '1';
		end loop;
	end;

	procedure add_solution_to_column (
		column	: integer;
		number	: integer
	) is
	begin
		for r in 0 to 3 loop
			solutions_array(r, column, number-1) <= '1';
		end loop;
	end;

	procedure remove_solution_from_cell (
		row		: integer;
		column	: integer;
		number	: integer := 0
	) is
	begin
		if (number > 0) then
			solutions_array(row, column, number-1) <= '0';
		end if;
	end;
	
	procedure insert_value (
		row		: integer;
		column	: integer;
		number	: integer
	) is
	begin
		if (number /= 0) then
			for c in 0 to 3 loop
				if (c /= column) then
					solutions_array(row, c, number-1) <= '0';
				end if;
			end loop;
			
			for r in 0 to 3 loop
				if (r /= row) then
					solutions_array(r, column, number-1) <= '0';
				end if;
			end loop;
			
			for n in 0 to 3 loop
				if (n = number - 1) then
					solutions_array(row, column, n) <= '1';
				else
					solutions_array(row, column, n) <= '0';
				end if;
			end loop;
			
			matrix_array(row, column) <= number;
		else
			add_solution_to_row(row, matrix_array(row, column));
			add_solution_to_column(column, matrix_array(row, column));
		end if;
		
		SOLUTIONS <= solutions_array;
	end;
	
	function check_constraint (
		constraint	: integer;
		values		: ROW_TYPE
	) return std_logic is
	variable max	: integer := 0;
	variable top	: integer := 0;
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
	
	function count_empty_cells_before_max (
		values		: ROW_TYPE
	) return integer is
	variable count	: integer := 0;
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
	
	function count_empty_cells (
		values		: ROW_TYPE
	) return integer is
	variable count	: integer := 0;
	begin
		for i in 0 to 3 loop
			if (values(i) = 0) then
				count := count +1;
			end if;
		end loop;
		return count;
	end;
		
begin

	process(CLOCK, RESET_N, SOLVE, cursor_position)
		variable max : integer := 0;
		variable top : integer := 0;
		variable top1 : integer := 0;
		variable top2 : integer := 0;
		variable r : integer := 0;
		variable solution		: integer := 0;
		variable sol_count	: integer := 0;
		variable position		: integer := 0;
		variable pos_count	: integer := 0;
		variable reverse		: integer := 0;
		variable maxindex		: integer := 0;
		variable zeroindex	: integer := 0;
		variable zeroindex1	: integer := 0;
		variable number		: integer := 0;
		variable innerMax		: integer := 0;
		variable innerTop		: integer := 0;
		variable checkRes		: std_logic := '0';
		variable added_value	: std_logic := '0';
		variable	tmpRow		: ROW_TYPE := (others => 0);
	begin
		CONSTRAINTS <= constraint_array;
		if (RESET_N='0') then
			win <= '0'; WINNER <= '0';
			CURSOR_POS <= (0, 0);
			cursor_position <= (0, 0);
			solutions_array <= ((others => (others => (others => '1'))));
			matrix_array <= ((others=> (others=> 0)));
			SOLUTIONS <= solutions_array;
			MATRIX <= matrix_array;
			added_value := '0';
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
				added_value := '0';
			
				-- Rule: constraint = 4
				for r in 0 to 3 loop
					if (constraint_array(0, r) = 4 AND matrix_array(0, r) = 0) then
						insert_value(0, r, 1);
						insert_value(1, r, 2);
						insert_value(2, r, 3);
						insert_value(3, r, 4);
						added_value := '1';
						exit;
					end if;
					if (constraint_array(3, r) = 4 AND matrix_array(3, r) = 0) then
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
						if (constraint_array(1, c) = 4 AND matrix_array(c, 0) = 0) then
							insert_value(c, 0, 1);
							insert_value(c, 1, 2);
							insert_value(c, 2, 3);
							insert_value(c, 3, 4);
							added_value := '1';
							exit;
						end if;
						if (constraint_array(2, c) = 4 AND matrix_array(c, 3) = 0) then
							insert_value(c, 3, 1);
							insert_value(c, 2, 2);
							insert_value(c, 1, 3);
							insert_value(c, 0, 4);
							added_value := '1';
							exit;
						end if;
					end loop;
				end if;
			
				-- Rule: constraint = 1
				if (added_value = '0') then
					for r in 0 to 3 loop
						if (constraint_array(0, r) = 1 AND matrix_array(0, r) = 0) then
							insert_value(0, r, 4);
							added_value := '1';
							exit;
						end if;
						if (constraint_array(3, r) = 1 AND matrix_array(3, r) = 0) then
							insert_value(3, r, 4);
							added_value := '1';
							exit;
						end if;
					end loop;
				end if;
				if (added_value = '0') then
					for c in 0 to 3 loop
						if (constraint_array(1, c) = 1 AND matrix_array(c, 0) = 0) then
							insert_value(c, 0, 4);
							added_value := '1';
							exit;
						end if;
						if (constraint_array(2, c) = 1 AND matrix_array(c, 3) = 0) then
							insert_value(c, 3, 4);
							added_value := '1';
							exit;
						end if;
					end loop;
				end if;
				
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
				
				-- Rule: check only possible position for value
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
					tmpRow := (matrix_array(0, r), matrix_array(1, r), matrix_array(2, r), matrix_array(3, r));
					if ( count_empty_cells_before_max(tmpRow) = 1 ) then	-- Number of empty cells
						zeroindex := 0;
						for c in 0 to 3 loop	-- Finding empty cell
							if (matrix_array(c, r) = 0) then
								zeroindex := c;
								exit;
							end if;
						end loop;
						for n in 0 to 3 loop
							if (solutions_array(zeroindex, r, n) = '1') then
								tmpRow(zeroindex) := n+1;
								if (check_constraint(constraint_array(0, r), tmpRow) = '0') then
									remove_solution_from_cell(zeroindex, r, n+1);
								end if;
							end if;
						end loop;
					elsif ( count_empty_cells_before_max(tmpRow) = 2 AND count_empty_cells(tmpRow) = 2 ) then	-- Number of empty cells
						zeroindex := -1;
						zeroindex1 := -1;
						for c in 0 to 3 loop -- Finding empty cell
							if ( matrix_array(c, r) = 0 ) then
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
								tmpRow(zeroindex) := n+1;
								for n2 in 0 to 3 loop
									if (solutions_array(zeroindex1, r, n2) = '1' AND n2 /= n) then
										tmpRow(zeroindex1) := n2+1;
										if (check_constraint(constraint_array(0, r), tmpRow) = '0') then
											remove_solution_from_cell(zeroindex, r, n+1);
											remove_solution_from_cell(zeroindex1, r, n2+1);
										end if;
									end if;
								end loop;
							end if;
						end loop;
					end if;
					-- FROM RIGHT
					tmpRow := (matrix_array(3, r), matrix_array(2, r), matrix_array(1, r), matrix_array(0, r));
					if ( count_empty_cells_before_max(tmpRow) = 1 ) then	-- Number of empty cells
						zeroindex := 0;
						for c in 0 to 3 loop	-- Finding empty cell
							if (matrix_array(c, r) = 0) then
								zeroindex := c;
								exit;
							end if;
						end loop;
						for n in 0 to 3 loop
							if (solutions_array(3-zeroindex, r, n) = '1') then
								tmpRow(zeroindex) := n+1;
								if (check_constraint(constraint_array(3, r), tmpRow) = '0') then
									remove_solution_from_cell(3-zeroindex, r, n+1);
								end if;
							end if;
						end loop;
					elsif ( count_empty_cells_before_max(tmpRow) = 2 AND count_empty_cells(tmpRow) = 2 ) then	-- Number of empty cells
						zeroindex := -1;
						zeroindex1 := -1;
						for c in 0 to 3 loop -- Finding empty cell
							if ( matrix_array(c, r) = 0 ) then
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
								tmpRow(zeroindex) := n+1;
								for n2 in 0 to 3 loop
									if (solutions_array(3-zeroindex1, r, n2) = '1' AND n2 /= n) then
										tmpRow(zeroindex1) := n2+1;
										if (check_constraint(constraint_array(3, r), tmpRow) = '0') then
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
					tmpRow := (matrix_array(c, 0), matrix_array(c, 1), matrix_array(c, 2), matrix_array(c, 3));
					if ( count_empty_cells_before_max(tmpRow) = 1 ) then	-- Number of empty cells
						zeroindex := 0;
						for r in 0 to 3 loop	-- Finding empty cell
							if (matrix_array(c, r) = 0) then
								zeroindex := r;
								exit;
							end if;
						end loop;
						for n in 0 to 3 loop
							if (solutions_array(c, zeroindex, n) = '1') then
								tmpRow(zeroindex) := n+1;
								if (check_constraint(constraint_array(1, c), tmpRow) = '0') then
									remove_solution_from_cell(c, zeroindex, n+1);
								end if;
							end if;
						end loop;
					elsif ( count_empty_cells_before_max(tmpRow) = 2 AND count_empty_cells(tmpRow) = 2 ) then	-- Number of empty cells
						zeroindex := -1;
						zeroindex1 := -1;
						for r in 0 to 3 loop -- Finding empty cell
							if ( matrix_array(c, r) = 0 ) then
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
								tmpRow(zeroindex) := n+1;
								for n2 in 0 to 3 loop
									if (solutions_array(c, zeroindex1, n2) = '1' AND n2 /= n) then
										tmpRow(zeroindex1) := n2+1;
										if (check_constraint(constraint_array(1, c), tmpRow) = '0') then
											remove_solution_from_cell(c, zeroindex, n+1);
											remove_solution_from_cell(c, zeroindex1, n2+1);
										end if;
									end if;
								end loop;
							end if;
						end loop;
					end if;
					-- FROM BOTTOM
					tmpRow := (matrix_array(c, 3), matrix_array(c, 2), matrix_array(c, 1), matrix_array(c, 0));
					if ( count_empty_cells_before_max(tmpRow) = 1 ) then	-- Number of empty cells
						zeroindex := 0;
						for r in 0 to 3 loop	-- Finding empty cell
							if (matrix_array(c, r) = 0) then
								zeroindex := r;
								exit;
							end if;
						end loop;
						for n in 0 to 3 loop
							if (solutions_array(c, 3-zeroindex, n) = '1') then
								tmpRow(zeroindex) := n+1;
								if (check_constraint(constraint_array(2, c), tmpRow) = '0') then
									remove_solution_from_cell(c, 3-zeroindex, n+1);
								end if;
							end if;
						end loop;
					elsif ( count_empty_cells_before_max(tmpRow) = 2 AND count_empty_cells(tmpRow) = 2 ) then	-- Number of empty cells
						zeroindex := -1;
						zeroindex1 := -1;
						for r in 0 to 3 loop -- Finding empty cell
							if ( matrix_array(c, r) = 0 ) then
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
								tmpRow(zeroindex) := n+1;
								for n2 in 0 to 3 loop
									if (solutions_array(c, 3-zeroindex1, n2) = '1' AND n2 /= n) then
										tmpRow(zeroindex1) := n2+1;
										if (check_constraint(constraint_array(2, c), tmpRow) = '0') then
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
				
				if constraint_array(0,r) /= top1 or constraint_array(3,r) /= top2 then
					win <= '0';
				end if;
			end loop;
			
			
			MATRIX <= matrix_array;
			
		end if;
	end process;

end behavior;
