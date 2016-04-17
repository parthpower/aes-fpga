library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.aes_types.all;

entity aes_Encrypt_FSM is
	port(
		key_in         : in  matrix(3 downto 0, 3 downto 0);

		data_block_in  : in  matrix(3 downto 0, 3 downto 0);
		data_block_out : out matrix(3 downto 0, 3 downto 0);

		key_load       : in  std_logic;

		start          : in  std_logic;
		done           : out std_logic;

		busy           : out std_logic;

		clk            : in  std_logic;
		rst            : in  std_logic
	);
end entity aes_Encrypt_FSM;

architecture RTL of aes_Encrypt_FSM is
	component aes_KeySchedule_FSM
		port(key_in       : in  matrix(3 downto 0, 3 downto 0);
			 keychain_out : out matrix_128(10 downto 0);
			 start        : in  std_logic;
			 done         : out std_logic;
			 clk          : in  std_logic;
			 rst          : in  std_logic);
	end component aes_KeySchedule_FSM;

	component aes_SubBytes_ShiftRows
		port(data_in  : in  matrix(3 downto 0, 3 downto 0);
			 data_out : out matrix(3 downto 0, 3 downto 0);
			 start    : in  std_logic;
			 done     : out std_logic;
			 clk      : in  std_logic;
			 rst      : in  std_logic);
	end component aes_SubBytes_ShiftRows;

	component aes_MixColumns
		port(data_in  : in  matrix(3 downto 0, 3 downto 0);
			 data_out : out matrix(3 downto 0, 3 downto 0);
			 start    : in  std_logic;
			 done     : out std_logic;
			 clk      : in  std_logic;
			 rst      : in  std_logic);
	end component aes_MixColumns;

	component aes_AddRoundKey
		port(data_in  : in  matrix(3 downto 0, 3 downto 0);
			 key_in   : in  matrix(3 downto 0, 3 downto 0);
			 data_out : out matrix(3 downto 0, 3 downto 0);

			 clk      : in  std_logic;
			 rst      : in  std_logic);
	end component aes_AddRoundKey;

	signal latched_data_in, round_data_out, round_data_in, round_key, latched_key_in : matrix(3 downto 0, 3 downto 0);
	signal ss_data_in, ss_data_out, mc_data_in, mc_data_out                          : matrix(3 downto 0, 3 downto 0);
	signal mc_start, mc_done, ss_done, ss_start                                      : std_logic;
	signal ss_start_tmp                                                              : integer range 0 to 1  := 0;
	signal keychain                                                                  : matrix_128(10 downto 0);
	signal round_counter                                                             : integer range 1 to 10 := 1;
	signal ks_start, ks_done                                                         : std_logic;

	type state is (IDLE, KEYSCHEDULE, INITIAL_ROUND, MAIN_ROUND, ENC_OUTPUT);
	signal current_state : state := IDLE;
begin
	Inst_aes_KeySchedule_FSM : aes_KeySchedule_FSM
		port map(
			key_in       => latched_key_in,
			keychain_out => keychain,
			start        => ks_start,
			done         => ks_done,
			clk          => clk,
			rst          => rst
		);
	Inst_aes_SubBytes_ShiftRows : aes_SubBytes_ShiftRows
		port map(
			data_in  => ss_data_in,
			data_out => ss_data_out,
			done     => ss_done,
			start    => ss_start,
			clk      => clk,
			rst      => rst
		);
	Inst_aes_MixColumns : aes_MixColumns
		port map(
			data_in  => mc_data_in,
			data_out => mc_data_out,
			start    => mc_start,
			done     => mc_done,
			clk      => clk,
			rst      => rst
		);
	--	Inst_aes_AddRoundKey : aes_AddRoundKey
	--		port map(
	--			data_in  => a_data_in,
	--			key_in   => key_in,
	--			data_out => data_out,
	--			clk      => clk,
	--			rst      => rst
	--		);

	state_proc : process(clk) is
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				current_state <= IDLE;
				for i in 0 to 3 loop
					for j in 0 to 3 loop
						round_data_in(i, j)  <= (others => '0');
						round_data_out(i, j) <= (others => '0');
						latched_key_in(i, j) <= (others => '0');
						round_counter        <= 1;
					end loop;
				end loop;
			else
				if (start = '1') then
					latched_data_in <= data_block_in;
					if (key_load = '1') then
						latched_key_in <= key_in;
						current_state  <= KEYSCHEDULE;
					else
						latched_key_in <= latched_key_in;
						current_state  <= INITIAL_ROUND;
					end if;
				else
					latched_key_in <= latched_key_in;
					current_state  <= current_state;
				end if;

				case current_state is
					when IDLE =>
						null;
					when KEYSCHEDULE =>
						if (ks_done = '1') then
							current_state <= INITIAL_ROUND;
							ks_start      <= '0';
						else
							current_state <= current_state;
							ks_start      <= '1';
						end if;

					when INITIAL_ROUND =>
						round_key      <= keychain(0);
						round_data_in  <= round_data_out;
						round_data_out <= latched_data_in XOR round_key;
						current_state  <= MAIN_ROUND;
						done           <= '0';
					when MAIN_ROUND =>
						round_key <= keychain(round_counter);

						if (round_counter = 10) then
							ss_data_in     <= round_data_in;
							round_data_out <= ss_data_in XOR round_data_out;

							if (ss_start_tmp = 0) then
								ss_start     <= '1';
								ss_start_tmp <= 1;
							else
								ss_start <= '0';
							end if;

							if (ss_done = '1') then
								current_state <= ENC_OUTPUT;
								round_counter <= 1;
								ss_start_tmp  <= 0;
							else
								current_state <= current_state;
							end if;
						else
							ss_data_in     <= round_data_in;
							mc_data_in     <= ss_data_out;
							round_data_out <= mc_data_out XOR round_key;

							if (ss_start_tmp = 0) then
								ss_start     <= '1';
								ss_start_tmp <= 1;
							else
								ss_start <= '0';
							end if;

							if (ss_done = '1') then
								mc_start <= '1';
							else
								mc_start <= '0';
							end if;

							if (mc_done = '1') then
								round_counter <= round_counter + 1;
								round_data_in <= round_data_out;
								ss_start_tmp  <= 0;
							end if;
							current_state <= current_state;
						end if;
						done <= '0';

					when ENC_OUTPUT =>
						done           <= '1';
						data_block_out <= round_data_out;
						current_state  <= IDLE;
				end case;
			end if;
		end if;
	end process state_proc;

end architecture RTL;
