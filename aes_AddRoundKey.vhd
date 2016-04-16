library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.aes_types.all;

entity aes_AddRoundKey is
	port(
		data_in  : in  matrix(3 downto 0, 3 downto 0);
		key_in   : in  matrix(3 downto 0, 3 downto 0);
		data_out : out matrix(3 downto 0, 3 downto 0);

		start    : in  std_logic;
		done     : out std_logic;

		clk      : in  std_logic;
		rst      : in  std_logic
	);
end entity aes_AddRoundKey;

architecture RTL of aes_AddRoundKey is
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
				data_out <= data_in XOR key_in;
			end if;
		end if;
	end process;
end architecture RTL;
