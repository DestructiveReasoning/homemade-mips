library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY cpu_tb IS
END cpu_tb;

ARCHITECTURE mips OF CPU_TB IS
    COMPONENT if_stage is
        PORT (
            new_addr:   IN STD_LOGIC_VECTOR(31 downto 0);   -- incoming pc address
            pc_en:      IN STD_LOGIC;                       -- enable line to increment pc (low when stalling)
            clock:      IN STD_LOGIC;
            q_new_addr: OUT STD_LOGIC_VECTOR(31 downto 0);  -- outputs pc + 4
            q_instr:    OUT STD_LOGIC_VECTOR(31 downto 0)   -- outputs instruction fetched from memory
        );
    END COMPONENT;

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

    COMPONENT pipe_reg is
        PORT (
            clock: IN STD_LOGIC;
            reset: IN STD_LOGIC;
            instr, newpc, data_a, data_b, imm                               : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            memread, memwrite, alusrc, pcsrc, regwrite, regdst, memtoreg    : IN STD_LOGIC;
            q_instr, q_newpc, q_data_a, q_data_b, q_imm                     : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            q_memread, q_memwrite, q_alusrc, q_pcsrc, q_regwrite, q_regdst, q_memtoreg  : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT ALU IS
        PORT(
            clock   : IN std_logic;
            a       : IN std_logic_vector(31 downto 0);
            b       : IN std_logic_vector(31 downto 0);
            funct   : IN std_logic_vector(4 downto 0); -- we are supposed to support 27 instructions
            output  : OUT std_logic_vector(31 downto 0)
        );
    END COMPONENT;

    -- Control signals will be encoded into 7 bit vectors here for concision
    -- The constants below allow for easy access of the various control signals
    CONSTANT memread: integer := 6;
    CONSTANT memwrite: integer := 5;
    CONSTANT alusrc: integer := 4;
    CONSTANT pcsrc: integer := 3;
    CONSTANT regwrite: integer := 2;
    CONSTANT regdst: integer := 1;
    CONSTANT memtoreg: integer := 0;

    SIGNAL clock: STD_LOGIC := '0';
    SIGNAL if_instr_in,if_newpc_in,if_instr_out,if_newpc_out: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

    SIGNAL the_new_addr: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

    SIGNAL id_instr_in,id_newpc_in,id_instr_out,id_newpc_out: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL id_dataa_in,id_datab_in,id_dataa_out,id_datab_out: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL id_imm_in, id_imm_out: STD_LOGIC_VECTOR(31 downto 0);
    SIGNAL id_ctrlsigs_in, id_ctrlsigs_out: STD_LOGIC_VECTOR(6 downto 0);

    SIGNAL ex_instr_out,ex_newpc_out: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL ex_dataa_in,ex_datab_in,ex_dataa_out,ex_datab_out: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL ex_imm_out: STD_LOGIC_VECTOR(31 downto 0);
    SIGNAL ex_ctrlsigs_out: STD_LOGIC_VECTOR(6 downto 0);
    SIGNAL ex_alures: STD_LOGIC_VECTOR(31 downto 0);
BEGIN
    fetch: if_stage
    PORT MAP (
        the_new_addr,
        '0', --TODO STALLING
        clock,
        if_instr_in,
        if_newpc_in
    );

    if_id: pipe_reg
    PORT MAP (
        clock,
        '0',
        if_instr_in,
        if_newpc_in,
        (others => '0'),
        (others => '0'),
        (others => '0'),
        '0', '0', '0', '0', '0', '0', '0',
        if_instr_out,
        if_newpc_out,
        open,
        open,
        open,
        open, open, open, open, open, open, open
    );

    decode: id_stage
    PORT MAP (
        if_newpc_out, if_instr_out,
        clock,
        '0', --TODO get write_en signal from WB stage
        (others => '0'), --TODO get write data from WB stage
        (others => '0'), --TODO get destination register from WB stage
        id_instr_in, id_newpc_in, id_dataa_in, id_datab_in, id_imm_in,
        id_ctrlsigs_in(memread), id_ctrlsigs_in(memwrite), id_ctrlsigs_in(alusrc),
        id_ctrlsigs_in(pcsrc), id_ctrlsigs_in(regwrite), id_ctrlsigs_in(regdst), id_ctrlsigs_in(memtoreg),
        the_new_addr
    );

    id_ex: pipe_reg
    PORT MAP (
        clock,
        '0',
        id_instr_in, id_newpc_in, id_dataa_in, id_datab_in, id_imm_in,
        id_ctrlsigs_in(memread), id_ctrlsigs_in(memwrite), id_ctrlsigs_in(alusrc),
        id_ctrlsigs_in(pcsrc), id_ctrlsigs_in(regwrite), id_ctrlsigs_in(regdst), id_ctrlsigs_in(memtoreg),
        id_instr_out, id_newpc_out, id_dataa_out, id_datab_out, id_imm_out,
        id_ctrlsigs_out(memread), id_ctrlsigs_out(memwrite), id_ctrlsigs_out(alusrc),
        id_ctrlsigs_out(pcsrc), id_ctrlsigs_out(regwrite), id_ctrlsigs_out(regdst), id_ctrlsigs_out(memtoreg)
    );

    arithmetic: alu
    PORT MAP (
        clock,
        id_dataa_out, --TODO implement forwarding
        id_datab_out, --TODO implement forwarding
        id_instr_out(30 downto 26),
        ex_alures
    );

    ex_mem: pipe_reg
    PORT MAP (
        clock,
        '0', --TODO hazard detection implementation?
        id_instr_out, id_newpc_out, ex_alures, id_datab_out, id_imm_out,
        id_ctrlsigs_out(memread), id_ctrlsigs_out(memwrite), id_ctrlsigs_out(alusrc),
        id_ctrlsigs_out(pcsrc), id_ctrlsigs_out(regwrite), id_ctrlsigs_out(regdst), id_ctrlsigs_out(memtoreg),
        ex_instr_out, ex_newpc_out, ex_alures, ex_datab_out, ex_imm_out,
        ex_ctrlsigs_out(memread), ex_ctrlsigs_out(memwrite), ex_ctrlsigs_out(alusrc),
        ex_ctrlsigs_out(pcsrc), ex_ctrlsigs_out(regwrite), ex_ctrlsigs_out(regdst), ex_ctrlsigs_out(memtoreg)
    );

    execute: process(id_dataa_out, id_datab_out, id_imm_out, id_ctrlsigs_out)
    BEGIN
        --TODO forwarding stuff here?
    END PROCESS;
END mips;
