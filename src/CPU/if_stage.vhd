library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity if_stage is
	PORT (
		new_addr:	IN STD_LOGIC_VECTOR(31 downto 0);	-- incoming pc address
		pc_en:		IN STD_LOGIC;						-- enable line to increment pc (low when stalling)
		clock:		IN STD_LOGIC;
		q_new_addr:	OUT STD_LOGIC_VECTOR(31 downto 0);	-- outputs pc + 4
		q_instr:	OUT STD_LOGIC_VECTOR(31 downto 0)	-- outputs instruction fetched from memory
	);
END if_stage;

ARCHITECTURE fetch OF if_stage IS
	SIGNAL pc: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
	-- TODO: Instantiate memory
BEGIN
	process(clock)
	BEGIN
		if(rising_edge(clock)) then
			if(pc_en = '1') then
				pc <= new_addr;
				q_new_addr <= std_logic_vector(unsigned(pc) + 4);
			END IF;
			-- TODO fetch stuff from memory
		END IF;
	END process;
END fetch;
