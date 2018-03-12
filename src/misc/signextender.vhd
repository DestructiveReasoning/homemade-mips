library ieee;
use ieee.std_logic_1164.all;

ENTITY signextender IS
	GENERIC (
		in_width	: integer := 16;
		out_width	: integer := 32
	);
	PORT (
		imm			: IN std_logic_vector(in_width - 1 downto 0);
		zero_extend	: IN std_logic;
		extended	: OUT std_logic_vector(out_width - 1 downto 0)
	);
END signextender;

ARCHITECTURE ext of signextender IS
BEGIN
	extended(in_width - 1 downto 0) <= imm;
	extended(out_width - 1 downto in_width) <= (others => '0') when zero_extend = '1' else (others => imm(in_width - 1));
END ext;
