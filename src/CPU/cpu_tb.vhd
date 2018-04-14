library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY cpu_tb IS
	PORT (
		clock: IN STD_LOGIC;
		reset: IN STD_LOGIC
	);
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
            q_new_addr: OUT STD_LOGIC_VECTOR(31 downto 0);
            branching : out STD_LOGIC;
            forwarded_rs, forwarded_rt : integer range 0 to 1;
            forwarded_rs_data, forwarded_rt_data : STD_LOGIC_VECTOR(31 downto 0)
        );
    END COMPONENT;

    COMPONENT pipe_reg is
        PORT (
            clock: IN STD_LOGIC;
            reset: IN STD_LOGIC;
            s_clr: in STD_LOGIC;
        stall:in STD_LOGIC;
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

--    SIGNAL clock: STD_LOGIC := '0';
    SIGNAL stall: STD_LOGIC := '0';

	-- input and output signals for the IF/ID register
    SIGNAL if_instr_in,if_newpc_in,if_instr_out,if_newpc_out: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
	SIGNAL the_new_addr: STD_LOGIC_VECTOR(31 downto 0) := (others => '0'); -- new PC address loaded into IF

	-- input and output signals for the ID/EX register
    SIGNAL id_instr_in,id_newpc_in,id_instr_out,id_newpc_out: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL id_dataa_in,id_datab_in,id_dataa_out,id_datab_out: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL id_imm_in, id_imm_out: STD_LOGIC_VECTOR(31 downto 0);
    SIGNAL id_ctrlsigs_in, id_ctrlsigs_out: STD_LOGIC_VECTOR(6 downto 0);

	-- input and output signals for the EX/MEM register
    SIGNAL ex_instr_in, ex_instr_out,ex_newpc_out: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL ex_dataa_in,ex_datab_in,ex_dataa_out,ex_datab_out: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL ex_imm_out: STD_LOGIC_VECTOR(31 downto 0);
    SIGNAL ex_ctrlsigs_out: STD_LOGIC_VECTOR(6 downto 0);
    SIGNAL ex_alures: STD_LOGIC_VECTOR(31 downto 0);

	-- input and output signals for the MEM/WB register
    SIGNAL mem_instr_out,mem_newpc_out: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL mem_dataa_in, mem_datab_in: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL mem_dataa_out, mem_datab_out: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL mem_imm_out: STD_LOGIC_VECTOR(31 downto 0);
    SIGNAL mem_ctrlsigs_in, mem_ctrlsigs_out: STD_LOGIC_VECTOR(6 downto 0);

	-- output of WB stage
    SIGNAL wb_data: STD_LOGIC_VECTOR(31 downto 0);

    -- forwarding intermediate signals
    signal mem_wb_forward_data : std_logic_vector(31 downto 0); -- forwarding lw in wb to sw in mem
    signal ex_mem_forward_dataa : std_logic_vector(31 downto 0); -- forwarding data produced by alu to next instruction
    signal ex_mem_forward_datab : std_logic_vector(31 downto 0); -- forwarding data produced by alu to next instruction

	signal ex_forward_a : integer range 0 to 2; -- selects which data to forward into A input of ALU
    signal ex_forward_b : integer range 0 to 2; -- selects which data to forward into B input of ALU
	signal ex_forward_prealusrc : std_logic_vector(31 downto 0); -- forwarded data before selecting between data and imm

	signal reset_id: std_logic := '0'; -- signal to clear ID/EX and freeze IF/ID
	signal pc_addr: std_logic_vector(31 downto 0);

  -- old forwarding mechanism
  signal branching : STD_LOGIC;
  signal branching_data_forwarded : std_logic_vector(31 downto 0);
  signal branching_rd_forwarded : std_logic_vector(4 downto 0);
  signal branching_regwrite : STD_LOGIC;

  -- new mechanism
  -- data being forwarded to id_stage for branching
  signal branching_data_forwarded_rs : std_logic_vector(31 downto 0);
  signal branching_data_forwarded_rt : std_logic_vector(31 downto 0);
  -- which registers' data is actually being forwarded
  -- 0 = no forwarding
  -- 1 = from alu
  -- 2 = from mem
  signal branching_forward_rt : integer range 0 to 1;
  signal branching_forward_rs : integer range 0 to 1;

  signal write_reg : std_logic := '0';
BEGIN
    -- STALLING LOGIC
    -- This may need some work
    -- For the subset of MIPS that this CPU implements, the only instruction that causes a stall is lw
    -- When stall is HIGH, PC isn't incremented (last instr repeats) and ex/mem pipeline register clears
    hazard_detection: process (id_ctrlsigs_out, id_instr_out, if_instr_out)
        VARIABLE id_rt: STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
        VARIABLE if_rs, if_rt: STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
    BEGIN
        stall <= '1';
        id_rt := id_instr_out(20 downto 16);
        if_rt := if_instr_out(20 downto 16);
        if_rs := if_instr_out(25 downto 21);
        -- no need to stall if the user tries loading to $r0 for some reason
        if(id_ctrlsigs_out(memread) = '1') then
            -- if decoded instruction is lw,
            -- and the target register for lw is a register that will be consumed in the instr in IF, 
            -- then stall
            if((id_rt = if_rs) or (id_rt = if_rt)) then
                stall <= '0';
            end if;
        end if;
    END PROCESS;

	reset_id <=  (not stall); -- stall is implemented with negative logic
	pc_addr <= the_new_addr when reset = '0' else X"00000000"; -- when reset, set PC to 0

    fetch: if_stage
    PORT MAP (
        pc_addr,   -- new pc fed back by ID (in case of a branch, for example)
        stall,          -- when stall is high, the pc won't be modified
        clock,
        if_newpc_in,     -- PC + 4
        if_instr_in    -- instruction fetched from memory
    );

    if_id: pipe_reg
    PORT MAP (
        clock,
        reset,                                -- the IF/ID reg is never reset
        '0',
        reset_id,
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

    -- forward data from ex or mem if branching decision registers being modified in previous instrucitons
    -- ex priority over mem
    branching_forwarding: process(branching, reset, wb_data, mem_instr_out, mem_ctrlsigs_out, if_instr_out, id_instr_out, ex_instr_out, ex_instr_in)
      variable id_rt : std_logic_vector(4 downto 0) := if_instr_out(20 downto 16);
      variable id_rs : std_logic_vector(4 downto 0) := if_instr_out(25 downto 21);
      -- register numbers in ex stage
      variable ex_rd : std_logic_vector(4 downto 0) := ex_instr_in(15 downto 11);
      -- register numbers in mem stage
      variable mem_rd : std_logic_vector(4 downto 0) := ex_instr_out(15 downto 11);
    begin
      id_rt := if_instr_out(20 downto 16);
      id_rs := if_instr_out(25 downto 21);
      ex_rd := ex_instr_in(15 downto 11);
      mem_rd := ex_instr_out(15 downto 11);

      branching_forward_rt <= 0;
      branching_forward_rs <= 0;

      if(branching = '1') then
      -- ex to id
        if(id_ctrlsigs_out(regwrite) = '1') then
          if(id_rt = ex_rd) then
            branching_data_forwarded_rt <= ex_alures;
            branching_forward_rt <= 1;
          end if;
          if(id_rs = ex_rd) then
            branching_data_forwarded_rs <= ex_alures;
            branching_forward_rs <= 1;
          end if;
      -- mem to id
        elsif(ex_ctrlsigs_out(regwrite) = '1') then
          if(id_rt = mem_rd) then
            branching_data_forwarded_rt <= ex_dataa_out;
            branching_forward_rt <= 1;
          end if;
          if(id_rs = mem_rd) then
            branching_data_forwarded_rs <= ex_dataa_out;
            branching_forward_rs <= 1;
          end if;
        elsif(ex_ctrlsigs_out(memtoreg) = '1') then
          if(id_rt = mem_rd) then
            branching_data_forwarded_rt <= mem_dataa_in;
            branching_forward_rt <= 1;
          end if;
          if(id_rs = mem_rd) then
            branching_data_forwarded_rs <= mem_dataa_in;
            branching_forward_rs <= 1;
          end if;
        end if;
      end if;
    end process;

    decode: id_stage
    PORT MAP (
	if_newpc_out, if_instr_out, -- grab PC and instr from IF/ID register
        clock,
        mem_ctrlsigs_out(regwrite), -- controls when to write to the register file
        wb_data,                                       -- data to write to the register file comes from Wb
        mem_instr_out(15 downto 11), -- register number to write to (rd or rt)
        id_instr_in, id_newpc_in, id_dataa_in, id_datab_in, id_imm_in,
        id_ctrlsigs_in(memread), id_ctrlsigs_in(memwrite), id_ctrlsigs_in(alusrc),
        id_ctrlsigs_in(pcsrc), id_ctrlsigs_in(regwrite), id_ctrlsigs_in(regdst), id_ctrlsigs_in(memtoreg),
        the_new_addr,
        branching,
        branching_forward_rs, branching_forward_rt,
        branching_data_forwarded_rs, branching_data_forwarded_rt
    );

    id_ex: pipe_reg
    PORT MAP (
        clock,
        reset,
		reset_id, -- Clear out the id/ex (turn instruction into nop) when stalling
		'0',
        -- pull all pipeline register contents from the decoding from the ID stage
        id_instr_in, id_newpc_in, id_dataa_in, id_datab_in, id_imm_in,
        id_ctrlsigs_in(memread), id_ctrlsigs_in(memwrite), id_ctrlsigs_in(alusrc),
        id_ctrlsigs_in(pcsrc), id_ctrlsigs_in(regwrite), id_ctrlsigs_in(regdst), id_ctrlsigs_in(memtoreg),
        id_instr_out, id_newpc_out, id_dataa_out, id_datab_out, id_imm_out,
        id_ctrlsigs_out(memread), id_ctrlsigs_out(memwrite), id_ctrlsigs_out(alusrc),
        id_ctrlsigs_out(pcsrc), id_ctrlsigs_out(regwrite), id_ctrlsigs_out(regdst), id_ctrlsigs_out(memtoreg)
    );


	-- controls forwarding from mem or wb to the ALU input A
    ex_mem_forward_dataa <= ex_dataa_out when(ex_forward_a = 2) else wb_data when(ex_forward_a = 1) else id_dataa_out;
	-- controls forwarding from mem or wb to the ALU input B
    ex_mem_forward_datab <= id_imm_out when(id_ctrlsigs_out(alusrc) = '1') else ex_datab_out when(ex_forward_b = 2) else wb_data when(ex_forward_b = 1) else id_datab_out;
	-- retrieves the forwarded data from before selecting imm
    ex_forward_prealusrc <= ex_datab_out when(ex_forward_b = 2) else mem_datab_out when(ex_forward_b = 1) else id_datab_out;

    to_ex_forwarding: process(id_instr_out, ex_instr_out, mem_instr_out)
      -- register numbers in ex stage
      variable ex_rt : std_logic_vector(4 downto 0) := id_instr_out(20 downto 16);
      variable ex_rs : std_logic_vector(4 downto 0) := id_instr_out(25 downto 21);

      -- register numbers in mem stage
      variable mem_rd : std_logic_vector(4 downto 0) := ex_instr_out(15 downto 11);

      -- register numbers in wb stage
      variable wb_rd : std_logic_vector(4 downto 0) := mem_instr_out(15 downto 11);

    begin

      ex_rt := id_instr_out(20 downto 16);
      ex_rs := id_instr_out(25 downto 21);
      mem_rd := ex_instr_out(15 downto 11);
      wb_rd := mem_instr_out(15 downto 11);

      ex_forward_a <= 0;
      ex_forward_b <= 0;

      -- forwarding from wb
	  -- only forward if register is going to be written to nonzero reg in the WB instruction
      if mem_ctrlsigs_out(regwrite) = '1' and wb_rd /= "00000" then
        if(wb_rd = ex_rs) then ex_forward_a <= 1; -- data hazard between WB's rd and EX's rs
        end if;
        if(wb_rd = ex_rt) then ex_forward_b <= 1; -- data hazard between WB's rd and Ex's rt
        end if;
      end if;
      -- forwarding from mem
	  -- since mem data is more recent, overwrite forwarding if mem causes data hazard
      if(ex_ctrlsigs_out(regwrite) = '1' and mem_rd /= "00000") then
        if(mem_rd = ex_rs) then ex_forward_a <= 2; -- data hazard between MEM's rd and Ex's rs
        end if;
        if(mem_rd = ex_rt) then ex_forward_b <= 2; -- data hazard between MEM's rd and Ex's rt
        end if;
      end if;
    end process;

    arithmetic: alu
    PORT MAP (
        clock,
		ex_mem_forward_dataa, -- forwarded data
        ex_mem_forward_datab,
        id_instr_out(30 downto 26), -- alu function encoding section of instr
        ex_alures
    );

    ex_mem: pipe_reg
    PORT MAP (
        clock,
		reset,
		'0',
		'0',
        -- place ALU output in data A section
		-- place pre-alu-src (before selecting imm) in B, to preserve data to be written in sw, for example
        ex_instr_in, id_newpc_out, ex_alures, ex_forward_prealusrc, id_imm_out,
        id_ctrlsigs_out(memread), id_ctrlsigs_out(memwrite), id_ctrlsigs_out(alusrc),
        id_ctrlsigs_out(pcsrc), id_ctrlsigs_out(regwrite), id_ctrlsigs_out(regdst), id_ctrlsigs_out(memtoreg),
        ex_instr_out, ex_newpc_out, ex_dataa_out, ex_datab_out, ex_imm_out,
        ex_ctrlsigs_out(memread), ex_ctrlsigs_out(memwrite), ex_ctrlsigs_out(alusrc),
        ex_ctrlsigs_out(pcsrc), ex_ctrlsigs_out(regwrite), ex_ctrlsigs_out(regdst), ex_ctrlsigs_out(memtoreg)
    );

    execute: process(id_dataa_out, id_datab_out, id_imm_out, id_ctrlsigs_out, id_instr_out)
    BEGIN
        ex_instr_in <= id_instr_out;
        -- when regdst is high, designate rt as the destination register
        if(id_ctrlsigs_out(regdst) = '0') then
            ex_instr_in(15 downto 11) <= id_instr_out(20 downto 16);
        end if;
    END PROCESS;

	-- if sw instruction requires data from wb, forward wbdata to mem
	-- resolves WB/MEM data hazard
    mem_wb_forward_data <= wb_data when (mem_instr_out(15 downto 11) = ex_instr_out(15 downto 11) and mem_ctrlsigs_out(regwrite) = '1') else ex_datab_out;

    memory: mem_stage
    PORT MAP (
        clock,
        ex_dataa_out,
        ex_ctrlsigs_out(memread), ex_ctrlsigs_out(memwrite),
        mem_wb_forward_data,
        -- forwarding data from lw to sw
        mem_dataa_in
    );

    mem_wb: pipe_reg
    PORT MAP (
        clock,
        reset,
		'0',
		'0',
        ex_instr_out, ex_newpc_out, mem_dataa_in, ex_dataa_out, ex_imm_out,
        ex_ctrlsigs_out(memread), ex_ctrlsigs_out(memwrite), ex_ctrlsigs_out(alusrc),
        ex_ctrlsigs_out(pcsrc), ex_ctrlsigs_out(regwrite), ex_ctrlsigs_out(regdst), ex_ctrlsigs_out(memtoreg),
        mem_instr_out, mem_newpc_out, mem_dataa_out, mem_datab_out, mem_imm_out,
        mem_ctrlsigs_out(memread), mem_ctrlsigs_out(memwrite), mem_ctrlsigs_out(alusrc),
        mem_ctrlsigs_out(pcsrc),mem_ctrlsigs_out(regwrite),mem_ctrlsigs_out(regdst),mem_ctrlsigs_out(memtoreg)
    );

    writeback: process(mem_ctrlsigs_out, mem_dataa_out, mem_datab_out)
    BEGIN
        if(mem_ctrlsigs_out(memtoreg) = '1') then
            wb_data <= mem_dataa_out; -- write MEM output
        else 
            wb_data <= mem_datab_out; -- write ALU output
        end if;
    end PROCESS;
END mips;
