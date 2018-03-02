library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_tb is
end cache_tb;

architecture behavior of cache_tb is

component cache is
generic(
    ram_size : INTEGER := 32768
);
port(
    clock : in std_logic;
    reset : in std_logic;

    -- Avalon interface --
    s_addr : in std_logic_vector (31 downto 0);
    s_read : in std_logic;
    s_readdata : out std_logic_vector (31 downto 0);
    s_write : in std_logic;
    s_writedata : in std_logic_vector (31 downto 0);
    s_waitrequest : out std_logic; 

    m_addr : out integer range 0 to ram_size-1;
    m_read : out std_logic;
    m_readdata : in std_logic_vector (7 downto 0);
    m_write : out std_logic;
    m_writedata : out std_logic_vector (7 downto 0);
    m_waitrequest : in std_logic
);
end component;

component memory is 
GENERIC(
    ram_size : INTEGER := 32768;
    mem_delay : time := 10 ns;
    clock_period : time := 1 ns
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
end component;
	
-- test signals 
signal reset : std_logic := '0';
signal clk : std_logic := '0';
constant clk_period : time := 1 ns;

signal s_addr : std_logic_vector (31 downto 0);
signal s_read : std_logic;
signal s_readdata : std_logic_vector (31 downto 0);
signal s_write : std_logic;
signal s_writedata : std_logic_vector (31 downto 0);
signal s_waitrequest : std_logic;

signal m_addr : integer range 0 to 2147483647;
signal m_read : std_logic;
signal m_readdata : std_logic_vector (7 downto 0);
signal m_write : std_logic;
signal m_writedata : std_logic_vector (7 downto 0);
signal m_waitrequest : std_logic; 

signal tag : std_logic_vector(5 downto 0);
signal index : std_logic_vector(4 downto 0);
signal word_offest : std_logic_vector(1 downto 0);
signal byte_offset : std_logic_vector(1 downto 0);

begin

s_addr <= "00000000000000000" & tag & index & word_offest & byte_offset;

-- Connect the components which we instantiated above to their
-- respective signals.
dut: cache 
port map(
    clock => clk,
    reset => reset,

    s_addr => s_addr,
    s_read => s_read,
    s_readdata => s_readdata,
    s_write => s_write,
    s_writedata => s_writedata,
    s_waitrequest => s_waitrequest,

    m_addr => m_addr,
    m_read => m_read,
    m_readdata => m_readdata,
    m_write => m_write,
    m_writedata => m_writedata,
    m_waitrequest => m_waitrequest
);

MEM : memory
port map (
    clock => clk,
    writedata => m_writedata,
    address => m_addr,
    memwrite => m_write,
    memread => m_read,
    readdata => m_readdata,
    waitrequest => m_waitrequest
);
				

clk_process : process
begin
  clk <= '0';
  wait for clk_period/2;
  clk <= '1';
  wait for clk_period/2;
end process;

test_process : process
begin

  wait for clk_period;
-- put your tests here
  -- little endian system
  -- since data(addr) = addr(7 downto 0)
  -- only last 8 bits because mem width is one byte
  tag <= (others => '0');
  index <= (0 => '1', others => '0');
  word_offest <= (others => '0');
  byte_offset <= (others => '0');

  -- read a word
  -- we load word at 0x10
  -- bytes at 0x10, 0x11, 0x12, 0x13 will be loaded
  -- data word is 0x13121110
	s_read <= '1';
  s_write <= '0';
  s_writedata <= (others => '0');
	REPORT "WAITING";
  wait until s_waitrequest = '0';
  assert s_readdata = X"13121110" severity error;
  s_read <= '0';

  wait for 4*clk_period;
  -- load another word into cache
  -- we load word at 0x220
  -- bytes at 0x220, 0x221, 0x222, 0x223 will be loaded
  -- data word is 0x23222120
  tag <= (0 => '1', others => '0');
  index <= (1 => '1', others => '0');
	s_read <= '1';
  s_write <= '0';
  s_writedata <= (others => '0');
	REPORT "WAITING";
  wait until s_waitrequest = '0';
  assert s_readdata = x"23222120" severity error;
  s_read <= '0';


  -- write to previous address
  -- write to address for block loaded into memory
  wait for 4*clk_period;
	s_read <= '0';
  s_write <= '1';
  s_writedata <= (others => '1');
	REPORT "WAITING";
  wait until s_waitrequest = '0';
  s_write <= '0';

  -- write to block that maps to same set
  -- to trigger write back
  wait for 4*clk_period;
  tag <= (1 => '1', others => '0');
	s_read <= '1';
  s_write <= '0';
  s_writedata <= (others => '0');
	REPORT "WAITING";
  wait until s_waitrequest = '0';
  s_read <= '0';

  wait for 6*clk_period;
  -- read and check whether write back
  -- data present in main memory
  tag <= (0 => '1', others => '0');
  index <= (1 => '1', others => '0');
	s_read <= '1';
  s_write <= '0';
  s_writedata <= (others => '0');
	REPORT "WAITING";
  wait until s_waitrequest = '0';
  assert s_readdata = x"FFFFFFFF" severity error;
  s_read <= '0';

  wait for 4*clk_period;
  -- Attempt to read misaligned word
  -- cache should ignore 2 lsb bit of s_addr
  -- aka auto-align block request
  -- since address is 0x7FFF
  -- data loaded from 0x7FFC, 0x7FFD, 0x7FFE, 0x7FFF
  -- loaded word should be 0xFFFEFDFC
  tag <= (others => '1');
  index <= (others => '1');
  word_offest <= (others => '1');
  byte_offset <= (others => '1');
	s_read <= '1';
  s_write <= '0';
  s_writedata <= (others => '0');
	REPORT "WAITING";
  wait until s_waitrequest = '0';
  assert s_readdata = x"FFFEFDFC" severity error;
  s_read <= '0';


  wait for 4*clk_period;
  -- attempt to trigger write allocate policy
  -- write to block not present in memory
  -- address is 0x0800
  -- data loaded from 0x0800, 0x0801, 0x0802, 0x8003
  -- loaded word is 03020100
  tag <= (2 => '1', others => '0');
  index <= (others => '0');
  word_offest <= (others => '0');
  byte_offset <= (others => '0');
	s_read <= '0';
  s_write <= '1';
  s_writedata <= (others => '1');
	REPORT "WAITING";
  wait until s_waitrequest = '0';
  s_write <= '0';


	WAIT;
	
end process;
	
end;
