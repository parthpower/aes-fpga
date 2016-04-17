library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.aes_types.all;

entity aes_KeySchedule_FSM is
	port(
		key_in       : in  matrix(3 downto 0, 3 downto 0);
		keychain_out : out matrix_128(10 downto 0);

		start        : in  std_logic;
		done         : out std_logic;

		clk          : in  std_logic;
		rst          : in  std_logic
	);
end entity aes_KeySchedule_FSM;

architecture RTL of aes_KeySchedule_FSM is
	component aes_KeySchedule is
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
	end component;
	type state is (IDLE, PROCESSING);
	signal current_state : state := IDLE;

	signal latched_key_in : matrix(3 downto 0, 3 downto 0);
	signal round_counter  : integer range 1 to 10 := 1;

	signal ks_en, ks_done, ks_start    : std_logic;
	signal Rcon_round                  : std_logic_vector(7 downto 0);
	signal round_key_in, round_key_out : matrix(3 downto 0, 3 downto 0);

begin
	KeySchedule_Module : aes_KeySchedule
		port map(
			key_in  => round_key_in,
			rcon    => Rcon_round,
			key_out => round_key_out,
			en      => ks_en,
			start   => ks_start,
			clk     => clk,
			done    => ks_done,
			rst     => rst
		);
	process(clk)
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				current_state <= IDLE;
				for l in 0 to 10 loop
					for i in 0 to 3 loop
						for j in 0 to 3 loop
							keychain_out(l)(i, j) <= (others => '0');
						end loop;
					end loop;
				end loop;
			else
				Rcon_round <= Rcon_const(round_counter - 1);
				if (ks_done = '1') then
					keychain_out(round_counter) <= round_key_out;
					round_key_in                <= round_key_out;
				end if;

				case current_state is
					when IDLE =>
						if (start = '1') then
							current_state  <= PROCESSING;
							latched_key_in <= key_in;
							done           <= '0';

							keychain_out(0) <= key_in;
							round_key_in    <= latched_key_in;

							ks_start <= '1';
							ks_en    <= '1';
						else
							current_state <= IDLE;
							ks_start      <= '0';
							ks_en         <= '0';
						end if;
					when PROCESSING =>
						if (round_counter = 10) then
							if (ks_done = '1') then
								done          <= '1';
								current_state <= IDLE;
								round_counter <= 1;
							end if;
						else
							if (ks_done = '1') then
								round_counter <= round_counter + 1;
							end if;
							current_state <= PROCESSING;
						end if;
				end case;
			end if;
		end if;
	end process;
end architecture RTL;
