library ieee;
use ieee.std_logic_1164.all;

entity testbench is
end testbench;

ARCHITECTURE test of testbench IS
	COMPONENT cpu_tb IS
		PORT (
			clock: IN STD_LOGIC;
			reset: IN STD_LOGIC
		);
	END COMPONENT;

  signal clock, reset : STD_LOGIC;
BEGIN

cpu : cpu_tb
port map(clock, reset);
	test: process
	BEGIN
		reset <= '1';
		WAIT FOR 1 ns;
		reset <= '0';
		WAIT;
	END process;
END test;
