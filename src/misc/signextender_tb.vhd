library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY signextender_tb IS
END signextender_tb;

ARCHITECTURE test OF signextender_tb IS
	COMPONENT signextender IS
		GENERIC (
			in_width: integer;
			out_width: integer
		);
		PORT (
			imm: IN std_logic_vector(in_width - 1 downto 0);
			zero_extend: IN std_logic;
			extended: OUT std_logic_vector(out_width - 1 downto 0)
		);
	END COMPONENT;

	SIGNAL imm: std_logic_vector(4 downto 0) := (others => '0');
	SIGNAL zero_extend: std_logic := '1';
	SIGNAL extended: std_logic_vector(9 downto 0);
BEGIN
	s: signextender GENERIC MAP(in_width => 5, out_width => 10)
	PORT MAP (
		imm => imm,
		zero_extend => zero_extend,
		extended => extended
	);
	stest: process
	BEGIN
		WAIT FOR 1 ns;
		ASSERT extended = "0000000000" REPORT "Initialization failure!" SEVERITY ERROR;
		imm <= "11010";
		WAIT FOR 1 ns;
		ASSERT extended = "0000011010" REPORT "Zero-extension failure!" SEVERITY ERROR;
		zero_extend <= '0';
		WAIT FOR 1 ns;
		ASSERT extended = "1111111010" REPORT "Sign-extension with negative failure!" SEVERITY ERROR;
		imm <= "01010";
		WAIT FOR 1 ns;
		ASSERT extended = "0000001010" REPORT "Sign-extension with positive failure!" SEVERITY ERROR;
		WAIT FOR 1 ns;
		WAIT;
	END process;
END test;
