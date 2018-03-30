library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity id_tb IS
END id_tb;

ARCHITECTURE tst of id_tb IS
	COMPONENT id_stage IS
		PORT (
			newpc, instr: IN STD_LOGIC_VECTOR(31 downto 0);
			clock: IN STD_LOGIC;
			s_write_en: IN STD_LOGIC;
			s_write_data: IN STD_LOGIC_VECTOR(31 downto 0);
			s_rd: IN STD_LOGIC_VECTOR(4 downto 0);
			q_instr, q_newpc, q_data_a, q_data_b, q_imm: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			q_memread, q_memwrite, q_alusrc, q_pcsrc, q_regwrite, q_regdst, q_memtoreg: OUT STD_LOGIC;
			q_new_addr: OUT STD_LOGIC_VECTOR(31 downto 0)
		);
	END COMPONENT;

	SIGNAL clock: std_logic := '1';
	SIGNAL finished: std_logic := '0';
	SIGNAL newpc: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
	SIGNAL instr: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
	SIGNAL write_en: STD_LOGIC := '0';
	SIGNAL write_data: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
	SIGNAL rd: STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
	SIGNAL q_instr, q_data_a, q_data_b, q_imm: STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');
	SIGNAL q_memread, q_memwrite, q_alusrc, q_pcsrc, q_regwrite, q_regdst, q_memtoreg: STD_LOGIC := '0';
	SIGNAL q_new_addr: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
	CONSTANT period: time := 1 ns;
BEGIN
	clock <= '0' WHEN finished = '1' ELSE NOT clock after period/2;

	stage: id_stage
	PORT MAP (
		newpc, instr,
		clock,
		write_en,
		write_data,
		rd,
		q_instr, open, q_data_a, q_data_b, q_imm,
		q_memread, q_memwrite, q_alusrc, q_pcsrc, q_regwrite, q_regdst, q_memtoreg,
		q_new_addr
	);

	test: process
	BEGIN
		write_en <= '1';
		write_data <= X"DEADBEEF";
		rd <= "01010";
		WAIT FOR period;
		write_data <= X"BADFACE0";
		rd <= "10101";
		WAIT FOR period;
		write_data <= X"FFEEDDCC";
		rd <= "10111";
		WAIT FOR period;
--		write_en <= '0';
--		instr <= b"000000_01010_10101_1111100000100000";
		instr <= b"001000_10101_01010_0000000000000001";
		WAIT FOR 1*period;
		ASSERT q_new_addr = X"00000000" REPORT "INVALID PC RETURNED" SEVERITY ERROR;
		ASSERT q_data_a = X"DEADBEEF" REPORT "BAD DATA IN (A)" & integer'image(to_integer(unsigned(q_data_a))) SEVERITY ERROR;
		ASSERT q_data_b = X"BADFACE0" REPORT "BAD DATA IN (B)" SEVERITY ERROR;
		ASSERT q_memread = '0' REPORT "READS MEMORY FOR NO REASON" SEVERITY ERROR;
		ASSERT q_memwrite = '0' REPORT "WRITES MEMORY FOR NO REASON" SEVERITY ERROR;
		ASSERT q_alusrc = '1' REPORT "USES IMM FOR NO REASON" SEVERITY ERROR;
		ASSERT q_regwrite = '1' REPORT "R TYPE NOT WRITING TO REGISTER" SEVERITY ERROR;
		ASSERT q_regdst = '1' REPORT "R TYPE WRITES TO RT" SEVERITY ERROR;
		ASSERT q_memtoreg = '0' REPORT "R TYPE WRITING MEMORY CONTENTS" SEVERITY ERROR;
		WAIT FOR 10*period;
		finished <= '1';
		WAIT;
	END process;
END tst;
