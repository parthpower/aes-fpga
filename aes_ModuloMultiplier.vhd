library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.aes_types.all;

entity aes_ModuloMultiplier is
	port(
		data_in  : in  generic_memory(3 downto 0);
		data_out : out generic_memory(3 downto 0);

		clk      : in  std_logic;
		rst      : in  std_logic
	);
end entity aes_ModuloMultiplier;

architecture RTL of aes_ModuloMultiplier is
begin
	process(clk)
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				data_out <= (others => (others => '0'));
			else
				if (data_in(0)(7) = '1' XOR data_in(1)(7) = '1') then
					data_out(0) <= data_in(0)(6 downto 0) & '0' XOR data_in(1)(6 downto 0) & '0' XOR data_in(1) XOR data_in(2) XOR data_in(3) XOR x"1B";
				else
					data_out(0) <= data_in(0)(6 downto 0) & '0' XOR data_in(1)(6 downto 0) & '0' XOR data_in(1) XOR data_in(2) XOR data_in(3);
				end if;

				if (data_in(1)(7) = '1' XOR data_in(2)(7) = '1') then
					data_out(1) <= data_in(1)(6 downto 0) & '0' XOR data_in(2)(6 downto 0) & '0' XOR data_in(2) XOR data_in(3) XOR data_in(0) XOR x"1B";
				else
					data_out(1) <= data_in(1)(6 downto 0) & '0' XOR data_in(2)(6 downto 0) & '0' XOR data_in(2) XOR data_in(3) XOR data_in(0);
				end if;

				if (data_in(2)(7) = '1' XOR data_in(3)(7) = '1') then
					data_out(2) <= data_in(2)(6 downto 0) & '0' XOR data_in(3)(6 downto 0) & '0' XOR data_in(3) XOR data_in(0) XOR data_in(1) XOR x"1B";
				else
					data_out(2) <= data_in(2)(6 downto 0) & '0' XOR data_in(3)(6 downto 0) & '0' XOR data_in(3) XOR data_in(0) XOR data_in(1);
				end if;

				if (data_in(3)(7) = '1' XOR data_in(0)(7) = '1') then
					data_out(3) <= data_in(3)(6 downto 0) & '0' XOR data_in(0)(6 downto 0) & '0' XOR data_in(0) XOR data_in(1) XOR data_in(2) XOR x"1B";
				else
					data_out(3) <= data_in(3)(6 downto 0) & '0' XOR data_in(0)(6 downto 0) & '0' XOR data_in(0) XOR data_in(1) XOR data_in(2);
				end if;
			end if;
		end if;
	end process;
end architecture RTL;
