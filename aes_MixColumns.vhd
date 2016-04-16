library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.aes_types.all;

entity aes_MixColumns is
	port(
		data_in  : in  matrix(3 downto 0, 3 downto 0);
		data_out : out matrix(3 downto 0, 3 downto 0);

		start    : in  std_logic;
		done     : out std_logic;

		clk      : in  std_logic;
		rst      : in  std_logic
	);
end entity aes_MixColumns;

architecture RTL of aes_MixColumns is
begin
	process(clk)
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				for i in 0 to 3 loop
					for j in 0 to 3 loop
						data_out(i, j) <= (others => '0');
					end loop;
				end loop;
			else
				for i in 0 to 3 loop
					for j in 0 to 3 loop
						data_out(j, i) <= column_modulo_mul(column_rotate(matrix2column(data_in, i), j));
					end loop;
				end loop;

			end if;
		end if;

	end process;

end architecture RTL;