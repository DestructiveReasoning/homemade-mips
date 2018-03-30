library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY if_stage_tb IS
END if_stage_tb;

ARCHITECTURE test of if_stage_tb IS
    COMPONENT if_stage IS
        PORT(
            new_addr:   IN STD_LOGIC_VECTOR(31 downto 0);   
            pc_en:      IN STD_LOGIC;
            clock:      IN STD_LOGIC;
            q_new_addr: OUT STD_LOGIC_VECTOR(31 downto 0);
            q_instr:    OUT STD_LOGIC_VECTOR(31 downto 0)
        );
    END COMPONENT;

    SIGNAL new_addr: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL pc_en: STD_LOGIC := '0';
    SIGNAL clock: STD_LOGIC := '0';
    SIGNAL q_new_addr: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL q_instr: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL finished: std_logic := '0';
    CONSTANT clock_period : time := 1 ns;

BEGIN
    fetch: if_stage
    PORT MAP (
        new_addr    => new_addr,
        pc_en       => pc_en,
        clock       => clock,
        q_new_addr  => q_new_addr,
        q_instr     => q_instr
    );

    clock <= '0' WHEN finished = '1' ELSE not clock after 0.5 ns;

    test: process
    BEGIN
        --WAIT FOR 1 ns;
        --ASSERT q_instr = x"0000_0000" REPORT "Initialization Error!" SEVERITY ERROR;
        --ASSERT q_new_addr = x"0000_0000" REPORT "Initialization Error!" SEVERITY ERROR;
        ASSERT new_addr = x"0000_0000" REPORT "Initialization error!" SEVERITY ERROR;
        REPORT "Reading first instruction from memory";
        new_addr <= x"0000_0000";
        pc_en <= '1';
        WAIT FOR 2 * clock_period;
        ASSERT q_instr = "00100000000010110000011111010000" REPORT "Wrong instruction!" SEVERITY ERROR;
        ASSERT q_new_addr = x"0000_0004" REPORT "Wrong new address!" SEVERITY ERROR;
        

        REPORT "Reading instruction of next pc from memory";
        new_addr <= q_new_addr;
        pc_en <= '1';
        WAIT FOR 2 * clock_period;
        ASSERT q_instr = "00000000001000100001100000100100" REPORT "Wrong instruction!" SEVERITY ERROR;
        ASSERT q_new_addr = x"0000_0008" REPORT "Wrong new address!" SEVERITY ERROR;

        finished <= '1';
        WAIT;
    END process;
END test;
