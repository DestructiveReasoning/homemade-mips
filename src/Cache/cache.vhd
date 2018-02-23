library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache is
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
end cache;

architecture arch of cache is

-- declare signals here

	TYPE BLOCK_TYPE IS ARRAY(3 downto 0) OF STD_LOGIC_VECTOR(31 downto 0);
	TYPE CACHE_TYPE IS ARRAY(31 downto 0) OF BLOCK_TYPE;
	TYPE TAG_TYPE IS ARRAY(31 downto 0) OF STD_LOGIC_VECTOR(5 downto 0);
	TYPE STATE_TYPE IS (POWERON, MEM_READ, MEM_WRITE, HIT, IDLE, CACHE_MISS);
	SIGNAL valids: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
	SIGNAL dirty: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
	SIGNAL cache: CACHE_TYPE;
	SIGNAL tags_vector: TAG_TYPE;
	SIGNAL state: STATE_TYPE := POWERON;
	SIGNAL tag: STD_LOGIC_VECTOR(5 downto 0);
	SIGNAL word_offset: integer range 0 to 3;
	SIGNAL byte_offset: integer range 0 to 3;
	SIGNAL index: integer range 0 to 31;
begin

-- s_addr format:
-- TTTTTTIIIIIWWBB

-- make circuits here
	machine: process(clock, reset)
		VARIABLE data: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
		VARIABLE byte_index: integer range 0 to 4 := 0;
		VARIABLE write_miss: std_logic := '0';
	begin
		if(reset = '1') then
			state <= POWERON;
		elsif(rising_edge(clock)) then
			case (state) IS
				WHEN POWERON =>
					valids <= (others => '0');
					dirty <= (others => '0');
					state <= IDLE;
				WHEN IDLE =>
					if(s_read = '1') THEN
						if(tag = tags_vector(index) and valids(index) = '1') then
							state <= HIT;
						else 
							byte_index := 0;
							state <= CACHE_MISS;
						end if;
					elsif(s_write = '1') THEN
						data := s_writedata;
						if(tag = tags_vector(index) and valids(index) = '1') then
							cache(index)(word_offset) <= data;
							state <= HIT;
						else 
							byte_index := 0;
							state <= MEM_WRITE;
						end if;
					end if;
				WHEN CACHE_MISS =>
					if(dirty(index) = '1') then
						state <= MEM_WRITE;
					else
						state <= MEM_READ;
					end if;
				WHEN HIT =>
					state <= IDLE;
				WHEN MEM_READ =>
					m_addr <= to_integer(unsigned(s_addr)) + byte_index;
					dirty(index) <= '0';
					valids(index) <= '1';
					if(byte_index = 4) then
						if(write_miss = '1') then
							write_miss := '0';
							cache(index)(word_offset) <= data;
							dirty(index) <= '1';
						end if;
						state <= HIT;
					elsif(m_waitrequest = '0') then
						cache(index)(word_offset)((byte_index + 1) * 8 - 1 downto byte_index * 8) <= m_readdata;
						byte_index := byte_index + 1;
					end if;
				WHEN MEM_WRITE =>
					m_addr <= to_integer(unsigned(s_addr)) + byte_index;
					m_writedata <= cache(index)(word_offset)((byte_index + 1) * 8 - 1 downto byte_index * 8);
					if(byte_index = 4) then
						byte_index := 0;
						state <= MEM_READ;
					elsif(m_waitrequest = '0') then
						byte_index := byte_index + 1;
					end if;
				WHEN others => null;
				end case;
		end if;
	end process;

	s_readdata <= cache(index)(word_offset);
	m_read <= '1' WHEN state = MEM_READ ELSE '0';
	m_write <= '1' WHEN state = MEM_WRITE ELSE '0';
	tag <= s_addr(14 downto 9);
	index <= to_integer(unsigned(s_addr(8 downto 4)));
	word_offset <= to_integer(unsigned(s_addr(3 downto 2)));
	byte_offset <= to_integer(unsigned(s_addr(1 downto 0)));
	s_waitrequest <= '0' WHEN state = HIT ELSE '1';

end arch;
