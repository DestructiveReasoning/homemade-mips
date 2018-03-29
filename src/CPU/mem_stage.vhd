library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
--Declare the memory component:

    COMPONENT memory IS
        GENERIC(
            ram_size : INTEGER := 32768;
            mem_delay : time := 10 ns;
            clock_period : time := 1 ns
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

  --all the input signals with initial values
    signal clk : std_logic := '0';
    constant clk_period : time := 1 ns;
    signal writedata: std_logic_vector(31 downto 0);
    signal address: INTEGER RANGE 0 TO 32768-1;
    signal memwrite: STD_LOGIC := '0';
    signal memread: STD_LOGIC := '0';
    signal readdata: STD_LOGIC_VECTOR (31 DOWNTO 0);
    signal waitrequest: STD_LOGIC;
    
    constant sz : integer := 127;
    type register_mem is array (sz downto 0) of std_logic_vector(31 downto 0);
    signal mem : register_mem := (others => (others => '0'));
    signal next_data, next_alu, next_address: STD_LOGIC_VECTOR(31 downto 0);
    signal i_addr : integer := to_integer(unsigned(addr));

-- Value from ALU to store, then address from, open up internal memory and write to address then store data in that
-- Include the part where it dumps to disk, include this from register vhd, logic to write to disk is there

BEGIN

   i_addr <= to_integer(unsigned(addr));

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

    process(clock)
    BEGIN
        if(rising_edge(clock)) then
		if(write = '1') then
			mem(i_addr) <= write_data;
		elsif(read = '1') then
			output <= mem(i_addr);
		end if;
        END IF;
    END process;
END mem;
