library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity if_stage is
    PORT (
        new_addr:   IN STD_LOGIC_VECTOR(31 downto 0);   -- incoming pc address
        pc_en:      IN STD_LOGIC;                       -- enable line to increment pc (low when stalling)
        clock:      IN STD_LOGIC;
        q_new_addr: OUT STD_LOGIC_VECTOR(31 downto 0);  -- outputs pc + 4
        q_instr:    OUT STD_LOGIC_VECTOR(31 downto 0);  -- outputs instruction fetched from memory
    );
END if_stage;

ARCHITECTURE fetch OF if_stage IS
   -- -- INSTRUCTION MEMORY COMPONENT
   -- COMPONENT memory is 
	 -- GENERIC(
	 --     ram_size : INTEGER := 1024;
	 --     mem_delay : time := 0 ns;
	 --     clock_period : time := 1 ns;
   --     init_file: string := "program.txt"
	 -- );
	 -- PORT (
	 --     clock: IN STD_LOGIC;
	 --     writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
	 --     address: IN INTEGER RANGE 0 TO ram_size-1;
	 --     memwrite: IN STD_LOGIC;
	 --     memread: IN STD_LOGIC;
	 --     readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
	 --     WAITrequest: OUT STD_LOGIC
	 -- );
	 -- END COMPONENT;

    COMPONENT cache is
      GENERIC(
               ram_size : INTEGER := 32768
             );
       PORT(
             clock : in std_logic;
             reset : in std_logic;

           -- Avalon interface --
             s_addr : in std_logic_vector (31 downto 0);
             s_read : in std_logic;
             s_readdata : out std_logic_vector (31 downto 0);
             s_write : in std_logic;
             s_writedata : in std_logic_vector (31 downto 0);
             s_WAITrequest : out std_logic; 

             m_addr : out integer range 0 to ram_size-1;
             m_read : out std_logic;
             m_readdata : in std_logic_vector (7 downto 0);
             m_write : out std_logic;
             m_writedata : out std_logic_vector (7 downto 0);
             m_WAITrequest : in std_logic
           );
    END COMPONENT;

     -- SIGNALS
    SIGNAL pc: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL q_addr : STD_LOGIC_VECTOR(31 downto 0);
    signal not_clock : STD_LOGIC;
    
BEGIN
    -- Initialized memory for reading only
    ram : memory
    PORT MAP (
        clock => not_clock,
      	writedata => x"0000_0000",
		    address => m_addr,
		    memwrite => '0',
		    memread => '1',
		    readdata => m_readdata,
		    WAITrequest => open
    );
  --                         
  -- if_stage <--> cache <--> ram
  instr_mem : cache
	PORT MAP(
        -- TODO verify that using the regular clock is okay
        -- previously i was using not_clock
				clock => clock,
				reset => '0',

        -- between cpu_tb and if_stage
				s_addr => q_addr,
				s_read => '1', -- TODO look into toggling this line, 
                       -- might cause some issues when reading
				s_readdata => q_instr,
				s_write => '1',
				s_writedata => x"0000_0000",
        -- ignore the cache telling us to wait
        -- TODO change to represent cache miss condition
				s_WAITrequest => open,

        -- connections between cache and unified memory
				m_addr => m_addr,
				m_read => m_read,
				m_readdata => m_readdata,
				m_write => m_write,
				m_writedata => m_writedata,
				m_WAITrequest => m_WAITrequest
			);

    not_clock <= not clock;
    pc <= new_addr;
    q_addr <= std_logic_vector(unsigned(pc)/4);
    fetch_process : process(clock, pc)
    BEGIN
        if(pc_en = '1' and unsigned(pc) < 1020) then
            q_new_addr <= std_logic_vector(unsigned(pc) + 4); -- increment pc by 4
        else
            q_new_addr <= pc;
        end if;
    END process;
END fetch;
