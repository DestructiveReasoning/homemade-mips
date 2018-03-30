library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mem_tb IS
END mem_tb;

ARCHITECTURE tst of mem_tb IS
	COMPONENT mem_stage is
		PORT (
			clock:      IN STD_LOGIC;
			addr:       IN STD_LOGIC_VECTOR(31 downto 0);
			read,write: IN STD_LOGIC;
			write_data: IN STD_LOGIC_VECTOR(31 downto 0);
			output:     OUT STD_LOGIC_VECTOR(31 downto 0)
		);
	END COMPONENT;

	SIGNAL clock: std_logic := '0';
	CONSTANT period: time := 1 ns;
	SIGNAL addr: std_logic_vector(31 downto 0) := (others => '0');
	SIGNAL read,write: std_logic := '0';
	SIGNAL write_Data: std_logic_vector(31 downto 0) := (others => '0');
	SIGNAL output: std_logic_vector(31 downto 0);
	SIGNAL finished: std_logic := '0';
BEGIN
	stage: mem_stage
	PORT MAP (
		clock => clock,
		addr => addr,
		read => read,
		write => write,
		write_data => write_data,
		output => output
	);
	clock <= '0' when finished = '1' else not clock after period/2;

	test: process
	BEGIN
		write_data <= X"DEADBEEF";
		write <= '1';
		WAIT FOR period;
		addr <= X"00000001";
		write <= '0';
		read <= '1';
		WAIT FOR period;
		ASSERT output = X"DEADBEEF" REPORT "MISREAD DATA!" SEVERITY ERROR;
		WAIT FOR 10*period;
		finished <= '1';
		WAIT;
	END process;
END tst;
