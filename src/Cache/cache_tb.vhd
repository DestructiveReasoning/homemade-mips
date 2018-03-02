library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_tb is
	END cache_tb;

architecture behavior of cache_tb is

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

	COMPONENT memory is 
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
				 WAITrequest: OUT STD_LOGIC
			 );
	END COMPONENT;

-- test SIGNALs 
	SIGNAL reset : std_logic := '0';
	SIGNAL clk : std_logic := '0';
	CONSTANT clk_period : time := 1 ns;

	SIGNAL s_addr : std_logic_vector (31 downto 0);
	SIGNAL s_read : std_logic;
	SIGNAL s_readdata : std_logic_vector (31 downto 0);
	SIGNAL s_write : std_logic;
	SIGNAL s_writedata : std_logic_vector (31 downto 0);
	SIGNAL s_WAITrequest : std_logic;

	SIGNAL m_addr : integer range 0 to 2147483647;
	SIGNAL m_read : std_logic;
	SIGNAL m_readdata : std_logic_vector (7 downto 0);
	SIGNAL m_write : std_logic;
	SIGNAL m_writedata : std_logic_vector (7 downto 0);
	SIGNAL m_WAITrequest : std_logic; 

	SIGNAL tag : std_logic_vector(5 downto 0);
	SIGNAL index : std_logic_vector(4 downto 0);
	SIGNAL word_offest : std_logic_vector(1 downto 0);
	SIGNAL byte_offset : std_logic_vector(1 downto 0);

BEGIN

	s_addr <= "00000000000000000" & tag & index & word_offest & byte_offset;

-- Connect the COMPONENTs which we instantiated above to their
-- respective SIGNALs.
	dut: cache 
	PORT MAP(
				clock => clk,
				reset => reset,

				s_addr => s_addr,
				s_read => s_read,
				s_readdata => s_readdata,
				s_write => s_write,
				s_writedata => s_writedata,
				s_WAITrequest => s_WAITrequest,

				m_addr => m_addr,
				m_read => m_read,
				m_readdata => m_readdata,
				m_write => m_write,
				m_writedata => m_writedata,
				m_WAITrequest => m_WAITrequest
			);

	MEM : memory
	PORT MAP (
				 clock => clk,
				 writedata => m_writedata,
				 address => m_addr,
				 memwrite => m_write,
				 memread => m_read,
				 readdata => m_readdata,
				 WAITrequest => m_WAITrequest
			 );


	clk_PROCESS : PROCESS
	BEGIN
		clk <= '0';
		WAIT FOR clk_period/2;
		clk <= '1';
		WAIT FOR clk_period/2;
	END PROCESS;

	test_PROCESS : PROCESS
	BEGIN

		WAIT FOR clk_period;
  -- put your tests here
  -- little ENDian system
  -- since data(addr) = addr(7 downto 0)
  -- only last 8 bits because mem width is one byte
		tag <= (OTHERS => '0');
		index <= (0 => '1', OTHERS => '0');
		word_offest <= (OTHERS => '0');
		byte_offset <= (OTHERS => '0');

	-- read a word
	-- we load word at 0x10
	-- bytes at 0x10, 0x11, 0x12, 0x13 will be loaded
	-- data word is 0x13121110
		s_read <= '1';
		s_write <= '0';
		s_writedata <= (OTHERS => '0');
		REPORT "WAITING";
		WAIT UNTIL s_WAITrequest = '0';
		ASSERT s_readdata = X"13121110" SEVERITY ERROR;
		s_read <= '0';

		WAIT FOR 4*clk_period;
  -- load another word into cache
  -- we load word at 0x220
  -- bytes at 0x220, 0x221, 0x222, 0x223 will be loaded
  -- data word is 0x23222120
		tag <= (0 => '1', OTHERS => '0');
		index <= (1 => '1', OTHERS => '0');
		s_read <= '1';
		s_write <= '0';
		s_writedata <= (OTHERS => '0');
		REPORT "WAITING";
		WAIT UNTIL s_WAITrequest = '0';
		ASSERT s_readdata = x"23222120" SEVERITY ERROR;
		s_read <= '0';


  -- write to previous address
  -- write to address FOR block loaded into memory
		WAIT FOR 4*clk_period;
		s_read <= '0';
		s_write <= '1';
		s_writedata <= (OTHERS => '1');
		REPORT "WAITING";
		WAIT UNTIL s_WAITrequest = '0';
		s_write <= '0';

  -- write to block that maps to same set
  -- to trigger write back
		WAIT FOR 4*clk_period;
		tag <= (1 => '1', OTHERS => '0');
		s_read <= '1';
		s_write <= '0';
		s_writedata <= (OTHERS => '0');
		REPORT "WAITING";
		WAIT UNTIL s_WAITrequest = '0';
		s_read <= '0';

		WAIT FOR 6*clk_period;
  -- read and check whether write back
  -- data present in main memory
		tag <= (0 => '1', OTHERS => '0');
		index <= (1 => '1', OTHERS => '0');
		s_read <= '1';
		s_write <= '0';
		s_writedata <= (OTHERS => '0');
		REPORT "WAITING";
		WAIT UNTIL s_WAITrequest = '0';
		ASSERT s_readdata = x"FFFFFFFF" SEVERITY ERROR;
		s_read <= '0';

		WAIT FOR 4*clk_period;
  -- Attempt to read misaligned word
  -- cache should ignore 2 lsb bit of s_addr
  -- aka auto-align block request
  -- since address is 0x7FFF
  -- data loaded from 0x7FFC, 0x7FFD, 0x7FFE, 0x7FFF
  -- loaded word should be 0xFFFEFDFC
		tag <= (OTHERS => '1');
		index <= (OTHERS => '1');
		word_offest <= (OTHERS => '1');
		byte_offset <= (OTHERS => '1');
		s_read <= '1';
		s_write <= '0';
		s_writedata <= (OTHERS => '0');
		REPORT "WAITING";
		WAIT UNTIL s_WAITrequest = '0';
		ASSERT s_readdata = x"FFFEFDFC" SEVERITY ERROR;
		s_read <= '0';


		WAIT FOR 4*clk_period;
  -- attempt to trigger write allocate policy
  -- write to block not present in memory
  -- address is 0x0800
  -- data loaded from 0x0800, 0x0801, 0x0802, 0x8003
  -- loaded word is 03020100

  --trigger write miss
		tag <= (2 => '1', OTHERS => '0');
		index <= (OTHERS => '0');
		word_offest <= (OTHERS => '0');
		byte_offset <= (OTHERS => '0');
		s_read <= '0';
		s_write <= '1';
		s_writedata <= (OTHERS => '1');
		REPORT "WAITING";
		WAIT UNTIL s_WAITrequest = '0';
		s_write <= '0';
  --verify write allocate
		s_read <= '1';
		s_writedata <= (OTHERS => '0');
		REPORT "WAITING";
		WAIT UNTIL s_WAITrequest = '0';
		ASSERT s_readdata = x"FFFFFFFF" SEVERITY ERROR;
		s_read <= '0';
		WAIT FOR 1*clk_period;

  --trigger another write miss with tag collision
		s_write <= '1';
		tag <= (5 => '1', OTHERS => '0');
		s_writedata <= x"DEADBEEF";
		REPORT "WAITING";
		WAIT UNTIL s_WAITrequest = '0';
		s_write <= '0';
		WAIT FOR 1*clk_period;
  --verify write back
		tag <= (2 => '1', OTHERS => '0');
		s_read <= '1';
		s_writedata <= (OTHERS => '0');
		REPORT "WAITING";
		WAIT UNTIL s_WAITrequest = '0';
		ASSERT s_readdata = x"FFFFFFFF" SEVERITY ERROR;
		s_read <= '0';
		WAIT FOR 4*clk_period;

  --evaluate reset performance
  --generate writeback first
		s_write <= '1';
		tag <= (2 => '1', OTHERS => '0');
		s_writedata <= X"DEADBEEF";
		REPORT "WAITING";
		WAIT UNTIL s_WAITrequest = '0';
		WAIT FOR 1*clk_period;
  --reset before the dirty word is written back to memory
		reset <= '1';
		WAIT FOR 0.1 * clk_period;
		reset <= '0';
		WAIT FOR 0.9 * clk_period;
  --ensure that the dirty bit was not written back to memory, and its previous value is still in memory
		s_read <= '1';
		REPORT "WAITING";
		WAIT UNTIL s_WAITrequest = '0';
		ASSERT s_readdata = X"FFFFFFFF" SEVERITY ERROR;
		s_read <= '0';
		REPORT "FINISHED RUNNING TESTS";

		WAIT;

	END PROCESS;

END;
