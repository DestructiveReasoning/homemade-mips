library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY alu_tb IS
END alu_tb;

ARCHITECTURE test of alu_tb IS
	COMPONENT ALU IS
		PORT(
			a: IN std_logic_vector(31 downto 0);
			b: IN std_logic_vector(31 downto 0);
			funct: IN std_logic_vector(4 downto 0);
			clock: IN std_logic;
			output: OUT std_logic_vector(31 downto 0)
		);
	END COMPONENT;

	SIGNAL a: std_logic_vector(31 downto 0) := (others => '0');
	SIGNAL b: std_logic_vector(31 downto 0) := (others => '0');
	SIGNAL funct: std_logic_vector(4 downto 0) := (others => '0');
	SIGNAL clock: std_logic := '0';
	SIGNAL output: std_logic_vector(31 downto 0);
	SIGNAL finished: std_logic := '0';

BEGIN
	calculator: alu
	PORT MAP (
		a => a,
		b => b,
		funct => funct,
		clock => clock,
		output => output
	);

	clock <= '0' WHEN finished = '1' ELSE not clock after 0.5 ns;

	test: process
	BEGIN
		WAIT FOR 1 ns;
		ASSERT output = X"00000000" REPORT "Initialization error!" SEVERITY ERROR;
		a <= std_logic_vector(to_signed(14, 32));
		b <= std_logic_vector(to_signed(50, 32));
		WAIT FOR 1 ns;
		ASSERT output = X"00000040" REPORT "Addition error!" SEVERITY ERROR;
		funct <= "00001";
		WAIT FOR 1 ns;
		ASSERT output = std_logic_vector(to_signed(-36,32)) REPORT "Subtraction error!" SEVERITY ERROR;
		funct <= "00000";
		b <= std_logic_vector(to_signed(-50,32));
		WAIT FOR 1 ns;
		ASSERT output = std_logic_vector(to_signed(-36,32)) REPORT "Addition with negative input error!" SEVERITY ERROR;
		funct <= "00001";
		WAIT FOR 1 ns;
		ASSERT output = X"00000040" REPORT "Subtracting negatives error!" SEVERITY ERROR;
		funct <= "00010";
		a <= std_logic_vector(to_signed(-3, 32));
		b <= std_logic_vector(to_signed(-5, 32));
		WAIT FOR 1 ns;
		ASSERT output = X"0000000F" REPORT "Multiplying two negatives error!" SEVERITY ERROR;
		funct <= "01001";
		WAIT FOR 1 ns;
		ASSERT output = X"0000000F" REPORT "mflo error!" SEVERITY ERROR;
		funct <= "01000";
		WAIT FOR 1 ns;
		ASSERT output = X"00000000" REPORT "mfhi corrupted!" SEVERITY ERROR;
		funct <= "00010";
		a <= X"08000000";
		b <= X"00000080";
		WAIT FOR 1 ns;
		ASSERT output = X"00000000" REPORT "Large number multiplication issue!" SEVERITY ERROR;
		funct <= "01000";
		WAIT FOR 1 ns;
		ASSERT output = X"00000004" REPORT "Large number mfhi issue!" SEVERITY ERROR;
		funct <= "00011";
		a <= X"00000040"; -- 64
		b <= X"00000020"; -- 32
		WAIT FOR 1 ns;
		ASSERT output = X"00000002" REPORT "Division error!" SEVERITY ERROR;
		funct <= "01000";
		WAIT FOR 1 ns;
		ASSERT output = X"00000000" REPORT "Whole number modulo error!" SEVERITY ERROR;
		funct <= "00011";
		b <= X"0000000A";
		WAIT FOR 1 ns;
		ASSERT output = X"00000006" REPORT "Fractional division error!" SEVERITY ERROR;
		funct <= "01000";
		WAIT FOR 1 ns;
		ASSERT output = X"00000004" REPORT "Fractional division modulo error!" SEVERITY ERROR;
		WAIT FOR 1 ns;
		finished <= '1';
		WAIT;
	END process;
END test;
