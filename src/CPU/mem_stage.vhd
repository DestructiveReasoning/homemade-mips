library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Ports needed to interact with rest of CPU

entity mem_stage is
    PORT (
        clock:      IN STD_LOGIC;
        addr:       IN STD_LOGIC_VECTOR(31 downto 0);
        read,write: IN STD_LOGIC;
        write_data: IN STD_LOGIC_VECTOR(31 downto 0);
        output:     OUT STD_LOGIC_VECTOR(31 downto 0)
    );
END mem_stage;

ARCHITECTURE mem OF mem_stage IS
    
-- Declaring the memory component:

    COMPONENT memory IS
        GENERIC(
            ram_size : INTEGER := 32768;
            mem_delay : time := 1 ns;
            clock_period : time := 1 ns;
            init_file : string := ""
        );
        PORT (
                clock: IN STD_LOGIC;
        writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
        address: IN INTEGER RANGE 0 TO ram_size-1;
        memwrite: IN STD_LOGIC;
        memread: IN STD_LOGIC;
        readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
        waitrequest: OUT STD_LOGIC
        );
    END COMPONENT;

  -- All the memory block input signals with initial values
    
    signal writedata: std_logic_vector(31 downto 0);
    signal address: INTEGER RANGE 0 TO 32768-1;
    signal memwrite: STD_LOGIC := '0';
    signal memread: STD_LOGIC := '0';
    signal readdata: STD_LOGIC_VECTOR (31 DOWNTO 0);
    signal waitrequest: STD_LOGIC;
    
    signal i_addr : integer := to_integer(unsigned(addr));

-- Map internal memory component to the signals we take in mem_stage

BEGIN
    i_addr <= to_integer(unsigned(addr))/4;

    instr_mem : memory
    PORT MAP(
        clock => clock, 
        writedata => write_data,
        address => i_addr,
        memwrite => write,
        memread => read,
        readdata => output,
        waitrequest => open
    );
END mem;
