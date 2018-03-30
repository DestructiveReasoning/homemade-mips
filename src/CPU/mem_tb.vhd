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
BEGIN
END tst;
