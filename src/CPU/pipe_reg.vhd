library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

---------------------------------------------
-- REGISTER STRUCTURE
-- INSTR	32 bits
-- PC+4		32 bits
-- MemRead	1 bit
-- MemWrite	1 bit
-- ALUSrc	1 bit
-- PCSrc	1 bit
-- RegWrite	1 bit
-- RegDst	1 bit
-- MemToReg	1 bit
-- DataA	32 bits
-- DataB	32 bits
---------------------------------------------

-- Keep full instr in all pipeline regs
-- Additionally store all control signals and data

entity pipe_reg is
	PORT (
		clock: IN STD_LOGIC;
		reset: IN STD_LOGIC;
		instr, newpc, data_a, data_b, imm								: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		memread, memwrite, alusrc, pcsrc, regwrite, regdst, memtoreg	: IN STD_LOGIC;
		q_instr, q_newpc, q_data_a, q_data_b, q_imm						: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		q_memread, q_memwrite, q_alusrc, q_pcsrc, q_regwrite, q_regdst, q_memtoreg	: OUT STD_LOGIC
	);
END pipe_reg;

ARCHITECTURE reg of pipe_reg IS
BEGIN
	process(clock, reset)
	BEGIN
		if(reset = '1') then
			q_instr <= (others => '0');
			q_newpc <= (others => '0');
			q_data_a <= (others => '0');
			q_data_b <= (others => '0');
			q_imm <= (others => '0');
			q_memread <= '0';
			q_memwrite <= '0';
			q_alusrc <= '0';
			q_pcsrc <= '0';
			q_regwrite <= '0';
			q_regdst <= '0';
			q_memtoreg <= '0';
		ELSIF(rising_edge(clock)) THEN
			q_instr <= instr; 
			q_newpc <= newpc;
			q_data_a <= data_a; 
			q_data_b <= data_b; 
			q_imm <= imm; 
			q_memread <= memread; 
			q_memwrite <= memwrite; 
			q_alusrc <= alusrc; 
			q_pcsrc <= pcsrc; 
			q_regwrite <= regwrite; 
			q_regdst <= regdst; 
			q_memtoreg <= memtoreg; 
		END IF;
	END PROCESS;
END reg;
