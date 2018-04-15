library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Ports needed to interact with rest of CPU

entity mem_stage is
	PORT (
			 clock:      IN STD_LOGIC;                       -- Clock
			 addr:       IN STD_LOGIC_VECTOR(31 downto 0);   -- Address we care about
	read,write: IN STD_LOGIC;                       -- Check if reading or writing
	write_data: IN STD_LOGIC_VECTOR(31 downto 0);   -- Data itself
	output:     OUT STD_LOGIC_VECTOR(31 downto 0);   -- Data output
	miss:		OUT STD_LOGIC
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
				 writedata: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				 address: IN INTEGER RANGE 0 TO ram_size-1;
				 memwrite: IN STD_LOGIC;
				 memread: IN STD_LOGIC;
				 readdata: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
				 waitrequest: OUT STD_LOGIC
			 );
	END COMPONENT;

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

	-- All the memory block input signals with initial values

	signal writedata: std_logic_vector(31 downto 0);
	signal address: INTEGER RANGE 0 TO 32768-1;
	signal memwrite: STD_LOGIC := '0';
	signal memread: STD_LOGIC := '0';
	signal readdata: STD_LOGIC_VECTOR (31 DOWNTO 0);
	signal waitrequest: STD_LOGIC;

	signal i_addr : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

	SIGNAL m_addr: integer range 0 to 32768-1;
	SIGNAL m_readdata: STD_LOGIC_VECTOR(7 downto 0) := (others =>'0');
	SIGNAL m_read: STD_LOGIC := '0';
	SIGNAL m_waitrequest: STD_LOGIC := '0';
	SIGNAL m_write: STD_LOGIC := '0';
	SIGNAL m_writedata: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

-- Map internal memory component to the signals we take in mem_stage

BEGIN
	i_addr <= "00" & addr(31 downto 2);

	data_mem : memory
	PORT MAP(
				clock => clock, 
				writedata => m_writedata,
				address => m_addr,
				memwrite => m_write,
				memread => m_read,
				readdata => m_readdata,
				waitrequest => m_waitrequest
			);

  data_cache : cache
	PORT MAP(
        -- TODO verify that using the regular clock is okay
        -- previously i was using not_clock
				clock => clock,
				reset => '0',

        -- between cpu_tb and if_stage
				s_addr => i_addr,
				s_read => read, -- TODO look into toggling this line, 
                       -- might cause some issues when reading
				s_readdata => output,
				s_write => write,
				s_writedata => write_data,
				s_WAITrequest => miss,
        -- ignore the cache telling us to wait
        -- TODO change to represent cache miss condition

        -- connections between cache and unified memory
				m_addr => m_addr,
				m_read => m_read,
				m_readdata => m_readdata,
				m_write => m_write,
				m_writedata => m_writedata,
				m_WAITrequest => m_WAITrequest
			);
END mem;
