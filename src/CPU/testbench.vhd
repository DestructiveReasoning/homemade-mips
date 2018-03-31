library ieee;
use ieee.std_logic_1164.all;

entity testbench is
end testbench;

-- Working features
-- Forwarding 
--     mem -> ex
--     wb  -> ex
--     wb  -> mem
-- Hazard detectoin
--     the stall signal is active low
--     meaning when it goes low the stall is activated
--     stall signal goes low when consumer comes after lw

-- Test instructions present in program.txt
-- add $8, $0, $0 #r8 will be our stack pointer
-- addi $1, $0, 5 #r1 will be the argument to fibonacci
-- addi $2, $1, 7
-- sw $1, 0($8)
-- lw $3, 0($8)
-- e: add $4, $3, $2
-- add $0, $0, $0
-- add $0, $0, $0
-- add $0, $0, $0
-- add $0, $0, $0
-- add $0, $0, $0
-- j e

-- compiled instructions
-- 00000000000000000100000000100000
-- 00100000000000010000000000000101
-- 00100000001000100000000000000111
-- 10101101000000010000000000000000
-- 10001101000000110000000000000000
-- 00000000011000100010000000100000
-- 00000000000000000000000000100000
-- 00000000000000000000000000100000
-- 00000000000000000000000000100000
-- 00000000000000000000000000100000
-- 00000000000000000000000000100000

-- The add $0, $0, $0 is a nop

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
		WAIT FOR 0.4 ns;
		reset <= '0';
		WAIT;
	END process;
END test;
