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

    COMPONENT mem_stage is
        PORT (
            clock:      IN STD_LOGIC;
            addr:       IN STD_LOGIC_VECTOR(31 downto 0);
            read,write: IN STD_LOGIC;
            write_data: IN STD_LOGIC_VECTOR(31 downto 0);
            output:     OUT STD_LOGIC_VECTOR(31 downto 0)
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
    SIGNAL stall: STD_LOGIC := '0';

    SIGNAL if_instr_in,if_newpc_in,if_instr_out,if_newpc_out: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

    SIGNAL the_new_addr: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

    SIGNAL id_instr_in,id_newpc_in,id_instr_out,id_newpc_out: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL id_dataa_in,id_datab_in,id_dataa_out,id_datab_out: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL id_imm_in, id_imm_out: STD_LOGIC_VECTOR(31 downto 0);
    SIGNAL id_ctrlsigs_in, id_ctrlsigs_out: STD_LOGIC_VECTOR(6 downto 0);

    SIGNAL ex_instr_in, ex_instr_out,ex_newpc_out: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL ex_dataa_in,ex_datab_in,ex_dataa_out,ex_datab_out: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL ex_imm_out: STD_LOGIC_VECTOR(31 downto 0);
    SIGNAL ex_ctrlsigs_out: STD_LOGIC_VECTOR(6 downto 0);
    SIGNAL ex_alures: STD_LOGIC_VECTOR(31 downto 0);

    SIGNAL mem_instr_out,mem_newpc_out: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL mem_dataa_in, mem_datab_in: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL mem_dataa_out, mem_datab_out: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL mem_imm_out: STD_LOGIC_VECTOR(31 downto 0);
    SIGNAL mem_ctrlsigs_in, mem_ctrlsigs_out: STD_LOGIC_VECTOR(6 downto 0);

    SIGNAL wb_data: STD_LOGIC_VECTOR(31 downto 0);

BEGIN
    -- STALLING LOGIC
    -- This may need some work
    -- For the subset of MIPS that this CPU implements, the only instruction that causes a stall is lw
    -- When stall is HIGH, PC isn't incremented (last instr repeats) and ex/mem pipeline register clears
    hazard_detection: process (id_ctrlsigs_out, id_instr_out, if_instr_out)
        VARIABLE id_rt: STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
        VARIABLE if_rs, if_rt: STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
    BEGIN
        stall <= '0';
        id_rt := id_instr_out(20 downto 16);
        if_rt := id_instr_out(20 downto 16);
        if_rs := id_instr_out(25 downto 21);
        -- no need to stall if the user tries loading to $r0 for some reason
        if(id_ctrlsigs_out(memread) = '1' and (not id_rt = "00000")) then
            -- if decoded instruction is lw,
            -- and the target register for lw is a register that will be consumed in the instr in IF, 
            -- then stall
            if((id_rt = if_rs) or (id_rt = if_rt)) then
                stall <= '1';
            end if;
        end if;
    END PROCESS;

    fetch: if_stage
    PORT MAP (
        the_new_addr,   -- new pc fed back by ID (in case of a branch, for example)
        stall,          -- when stall is high, the pc won't be modified
        clock,
        if_instr_in,    -- instruction fetched from memory
        if_newpc_in     -- PC + 4
    );

    if_id: pipe_reg
    PORT MAP (
        clock,
        '0',                                -- the IF/ID reg is never reset
        if_instr_in,                        -- pull instr from IF stage
        if_newpc_in,                        -- propagate PC+4 for next addr calculation
        (others => '0'),                    -- data not decoded yet
        (others => '0'),                    -- data not decoded yet
        (others => '0'),                    -- data not decoded yet
        '0', '0', '0', '0', '0', '0', '0',  -- control signals not decoded yet
        if_instr_out,                       -- propagate the instr to next stage
        if_newpc_out,                       -- propagate PC+4 (I guess this isn't necessary)
        -- data, imm, and control signals aren't decoded yet so there's no output from these sections
        open,
        open,
        open,
        open, open, open, open, open, open, open
    );

    decode: id_stage
    PORT MAP (
        if_newpc_out, if_instr_out,
        clock,
        mem_ctrlsigs_out(regwrite),
        wb_data,
        mem_instr_out(15 downto 11),
        id_instr_in, id_newpc_in, id_dataa_in, id_datab_in, id_imm_in,
        id_ctrlsigs_in(memread), id_ctrlsigs_in(memwrite), id_ctrlsigs_in(alusrc),
        id_ctrlsigs_in(pcsrc), id_ctrlsigs_in(regwrite), id_ctrlsigs_in(regdst), id_ctrlsigs_in(memtoreg),
        the_new_addr
    );

    id_ex: pipe_reg
    PORT MAP (
        clock,
        '0', -- the ID/EX register is never reset
        -- pull all pipeline register contents from the decoding from the ID stage
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
        id_instr_out(30 downto 26), -- alu function encoding section of instr
        ex_alures
    );

    ex_mem: pipe_reg
    PORT MAP (
        clock,
        stall, --TODO definitely need to double-check the stalling logic
        -- place ALU output in data A section
        ex_instr_in, id_newpc_out, ex_alures, id_datab_out, id_imm_out,
        id_ctrlsigs_out(memread), id_ctrlsigs_out(memwrite), id_ctrlsigs_out(alusrc),
        id_ctrlsigs_out(pcsrc), id_ctrlsigs_out(regwrite), id_ctrlsigs_out(regdst), id_ctrlsigs_out(memtoreg),
        ex_instr_out, ex_newpc_out, ex_dataa_out, ex_datab_out, ex_imm_out,
        ex_ctrlsigs_out(memread), ex_ctrlsigs_out(memwrite), ex_ctrlsigs_out(alusrc),
        ex_ctrlsigs_out(pcsrc), ex_ctrlsigs_out(regwrite), ex_ctrlsigs_out(regdst), ex_ctrlsigs_out(memtoreg)
    );

    execute: process(id_dataa_out, id_datab_out, id_imm_out, id_ctrlsigs_out, id_instr_out)
    BEGIN
        --TODO forwarding stuff here?
        ex_instr_in <= id_instr_out;
        -- when regdst is high, designate rt as the destination register
        if(id_ctrlsigs_out(regdst) = '0') then
            ex_instr_in(15 downto 11) <= id_instr_out(20 downto 16);
        end if;
    END PROCESS;

    memory: mem_stage
    PORT MAP (
        clock,
        ex_dataa_out,
        ex_ctrlsigs_out(memread), ex_ctrlsigs_out(memwrite),
        ex_datab_out,
        mem_dataa_in
    );

    mem_wb: pipe_reg
    PORT MAP (
        clock,
        '0',
        ex_instr_out, ex_newpc_out, mem_dataa_in, ex_dataa_out, ex_imm_out,
        ex_ctrlsigs_out(memread), ex_ctrlsigs_out(memwrite), ex_ctrlsigs_out(alusrc),
        ex_ctrlsigs_out(pcsrc), ex_ctrlsigs_out(regwrite), ex_ctrlsigs_out(regdst), ex_ctrlsigs_out(memtoreg),
        mem_instr_out, mem_newpc_out, mem_dataa_in, mem_dataa_out, mem_imm_out,
        mem_ctrlsigs_out(memread), mem_ctrlsigs_out(memwrite), mem_ctrlsigs_out(alusrc),
        mem_ctrlsigs_out(pcsrc),mem_ctrlsigs_out(regwrite),mem_ctrlsigs_out(regdst),mem_ctrlsigs_out(memtoreg)
    );

    writeback: process(mem_ctrlsigs_out, mem_dataa_out, mem_datab_out)
    BEGIN
        if(mem_ctrlsigs_out(memtoreg) = '1') then
            wb_data <= mem_dataa_out;
        else 
            wb_data <= mem_datab_out;
        end if;
    end PROCESS;
END mips;