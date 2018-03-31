library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY id_stage IS
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
END id_stage;

ARCHITECTURE id of id_stage IS
	COMPONENT ALUFunct_Encoder IS
		PORT(
			opcode  : IN std_logic_vector(5 downto 0);
			funct   : IN std_logic_vector(5 downto 0);
			code    : OUT std_logic_vector(4 downto 0)
		);
	END COMPONENT;
	COMPONENT registerfile IS
		PORT(
			clock       : IN std_logic;
			reset       : IN std_logic;                         -- to reset the register file 
			rs          : IN std_logic_vector(4 downto 0);      -- source register number
			rt          : IN std_logic_vector(4 downto 0);      -- target register number
			rd          : IN std_logic_vector(4 downto 0);      -- destination register number
			write_en    : IN std_logic;                         -- control signal to write to rd
			write_file  : IN std_logic;                         -- control signal to write to the physical register file
			write_data  : IN std_logic_vector(31 downto 0);     -- data to write to rd
			rs_data     : OUT std_logic_vector(31 downto 0);    -- data in source register
			rt_data     : OUT std_logic_vector(31 downto 0)     -- data in target register
		);
	END COMPONENT;

	SIGNAL rs, rt, rd: STD_LOGIC_VECTOR(4 downto 0);
	SIGNAL op: STD_LOGIC_VECTOR(5 downto 0);

	SIGNAL i_data_a, i_data_b: STD_LOGIC_VECTOR(31 downto 0);
--	SIGNAL new_addr: STD_LOGIC_VECTOR(31 downto 0);


  -- constants for figuring out instructions
	CONSTANT addi: STD_LOGIC_VECTOR(5 downto 0) := "001010";
	CONSTANT slti: STD_LOGIC_VECTOR(5 downto 0) := "001000";
	CONSTANT andi: STD_LOGIC_VECTOR(5 downto 0) := "001100";
	CONSTANT ori: STD_LOGIC_VECTOR(5 downto 0) := "001101";
	CONSTANT xori: STD_LOGIC_VECTOR(5 downto 0) := "001110";
	CONSTANT lui: STD_LOGIC_VECTOR(5 downto 0) := "001111";
	CONSTANT lw: STD_LOGIC_VECTOR(5 downto 0) := "100011";
	CONSTANT sw: STD_LOGIC_VECTOR(5 downto 0) := "101011";
	CONSTANT jr: STD_LOGIC_VECTOR(5 downto 0) := "001000"; -- funct
	CONSTANT j: STD_LOGIC_VECTOR(5 downto 0) := "000010";
	CONSTANT jal: STD_LOGIC_VECTOR(5 downto 0) := "000011";
	CONSTANT beq: STD_LOGIC_VECTOR(5 downto 0) := "000100";
	CONSTANT bne: STD_LOGIC_VECTOR(5 downto 0) := "000101";

  signal write_reg : std_logic := '0';
BEGIN
	enc: ALUFunct_Encoder
	PORT MAP (
		instr(31 downto 26),
		instr(5 downto 0),
		q_instr(30 downto 26)
	);

	op <= instr(31 downto 26);
	rs <= instr(25 downto 21);
	rd <= instr(15 downto 11);
	q_instr(31) <= '0';
	q_instr(25 downto 0) <= instr(25 downto 0); -- Gets ALU operation encoding from OP+Funct

	reg: registerfile
	PORT MAP (
		clock,
		'0',
		rs,
		rt,
		s_rd,
		s_write_en,
		write_reg, -- signal to write register contents to disk
		s_write_data,
		i_data_a,
		i_data_b
	);
    -- when approaching 10000 cycles dump register contents to disk
    process
    begin
      wait for 9999 ns;
      write_reg <= '1';
      wait for 1 ns;
      write_reg <= '0';
      wait for 1 ns;
    end process;
	-- RegDst = 1 -> Write back to rd (else write back into rt)
	-- ALUSrc = 1 -> Don't use immediate value (else use imm)
	process(instr, clock, i_data_a, i_data_b, s_rd)
  variable forwarded_data_a, forwarded_data_b : STD_LOGIC_VECTOR(31 downto 0);
	BEGIN
    -- control signal assertions
		q_pcsrc <= '0';
		q_memwrite <= '0';
		q_memread <= '0';
		q_memtoreg <= '0';
		q_regdst <= '0';
		q_alusrc <= '1';
		q_regwrite <= '1';
		q_data_a <= i_data_a;
		q_data_b <= i_data_b;
		q_new_addr <= newpc;
    branching <= '0';
		q_imm(31 downto 16) <= (others => instr(15));
		q_imm(15 downto 0) <= instr(15 downto 0);
    forwarded_data_a := i_data_a;
    forwarded_data_b := i_data_b;
		if(op = "000000") then
			q_regdst <= '1';
			q_alusrc <= '0';
      -- for figuring out jr
			if instr(5 downto 0) = "001000" then
				q_new_addr <= i_data_a;
				q_regwrite <= '0';
			end if;
		end if;
		rt <= instr(20 downto 16);
    -- op is opcode 
		case op IS
			WHEN beq|bne =>
        branching <= '1';
				q_regwrite <= '0';

        -- select data to compare based on forwarding
        if forwarded_rs = 1 then forwarded_data_a := forwarded_rs_data;
        end if;
        if forwarded_rt = 1 then forwarded_data_b := forwarded_rt_data;
        end if;

        if op = beq xnor forwarded_data_a = forwarded_data_b then -- xnor handles both bne and beq
					q_new_addr <= std_logic_vector(unsigned(newpc) + unsigned(b"000000" & instr(15 downto 0) & b"00"));
				end if;

			WHEN sw =>
				q_memwrite <= '1';
				q_regwrite <= '0';
			WHEN lw =>
				q_memread <= '1';
				q_memtoreg <= '1';
			WHEN jal =>
				rt <= "11111";
				q_data_a <= newpc;
				q_data_b <= (others => '0');
				q_pcsrc <= '1';
				-- Assuming PC and PC+4 have the same 4 MSB's
        -- multiply pc by 4 and pad
				q_new_addr <= (X"F0000000" and newpc) or (X"0" & instr(25 downto 0) & "00");
				q_alusrc <= '0';
			WHEN j =>
        -- similar to above
				--q_new_addr <= (X"F0000000" and newpc) or (X"0" & instr(25 downto 0) & "00");
				q_new_addr <= "0000" & instr(25 downto 0) & "00";
				q_regwrite <= '0';
			WHEN andi|ori|xori =>
				q_imm <= X"0000" & instr(15 downto 0);
			WHEN others => null;
		END CASE;
	END process;
END id;
