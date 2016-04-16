library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.aes_types.all;

entity aes_KeySchedule is
	port(
		key_in  : in  matrix(3 downto 0, 3 downto 0);
		key_out : out matrix(3 downto 0, 3 downto 0);
		Rcon    : in  std_logic_vector(7 downto 0);
		en      : in  std_logic;
		start   : in  std_logic;
		done    : out std_logic;

		clk     : in  std_logic;
		rst     : in  std_logic
	);
end entity aes_KeySchedule;

architecture RTL of aes_KeySchedule is
	type state is (IDLE, COL0, COL1, COL2, COL3);
	signal latched_key_in                                         : matrix(3 downto 0, 3 downto 0);
	signal temp_column0, temp_column1, temp_column2, temp_column3 : generic_memory(3 downto 0) := (others => (others => '0'));
	signal current_state, next_state                              : state                      := IDLE;
begin
	process(clk)
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				current_state <= IDLE;
				next_state    <= IDLE;
				for i in 0 to 3 loop
					for j in 0 to 3 loop
						key_out(i, j) <= (others => '0');
					end loop;
				end loop;
			else
				key_out <= column2matrix(temp_column0, temp_column1, temp_column2, temp_column3);
				if (en = '1') then
					current_state <= next_state;
				else
					current_state <= current_state;
				end if;

				case current_state is
					when IDLE =>
						if (start = '1') then
							latched_key_in <= key_in;
							next_state     <= COL0;
						else
							next_state <= IDLE;
						end if;
						done <= '0';
					when COL0 =>
						for I in temp_column0'range loop
							if (I = 0) then
								temp_column0(I) <= Sbox(to_integer(unsigned(column_rotate(matrix2column(latched_key_in, 3), 1)(I)))) XOR matrix2column(latched_key_in, 0)(I) XOR Rcon;
							else
								temp_column0(I) <= Sbox(to_integer(unsigned(column_rotate(matrix2column(latched_key_in, 3), 1)(I)))) XOR matrix2column(latched_key_in, 0)(I);
							end if;
						end loop;
						done       <= '0';
						next_state <= COL1;
					when COL1 =>
						temp_column1 <= temp_column0 XOR matrix2column(latched_key_in, 1);
						done         <= '0';
						next_state   <= COL2;
					when COL2 =>
						temp_column2 <= temp_column1 XOR matrix2column(latched_key_in, 2);
						done         <= '0';
						next_state   <= COL3;
					when COL3 =>
						temp_column3 <= temp_column2 XOR matrix2column(latched_key_in, 3);
						done         <= '1';
						next_state   <= IDLE;
				end case;
			end if;
		end if;
	end process;
end architecture RTL;
