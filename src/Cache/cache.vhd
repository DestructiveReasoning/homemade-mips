library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache is
generic(
	ram_size : INTEGER := 32768;
	set_bits: INTEGER := 5;
	word_bits: INTEGER := 2
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

	CONSTANT SETS: INTEGER := (2**set_bits);		-- Amount of sets in cache
	CONSTANT SLOTS_PER_SET: INTEGER := 32-SETS + 1;	-- Amount of slots in each set

	TYPE BLOCK_TYPE IS ARRAY((2**word_bits)-1 downto 0) OF STD_LOGIC_VECTOR(31 downto 0);
	TYPE SET_TYPE IS ARRAY(SLOTS_PER_SET-1 downto 0) OF BLOCK_TYPE;
	TYPE CACHE_TYPE IS ARRAY(SETS-1 downto 0) OF SET_TYPE;

	-- Array of tags for all entries in a given set
	TYPE TAG_SET_TYPE IS ARRAY(SLOTS_PER_SET-1 downto 0) OF STD_LOGIC_VECTOR(15-(word_bits+set_bits+2+1) downto 0);
	-- Array of tag arrays, one for each set
	TYPE TAG_TYPE IS ARRAY(SETS-1 downto 0) OF TAG_SET_TYPE;

	TYPE STATE_TYPE IS (POWERON, MEM_READ, MEM_WRITE, HIT, IDLE, CACHE_MISS);
	TYPE VALIDS_TYPE IS ARRAY(SETS-1 downto 0) OF STD_LOGIC_VECTOR(SLOTS_PER_SET-1 downto 0);

	-- At each cell in array, store a number corresponding to the next index 
	-- to be overwritten in a set
	-- The appropriate queue head will be incremented (circularly) at each cache miss on the given set
	TYPE QUEUE_HEADS IS ARRAY(SETS-1 downto 0) OF INTEGER RANGE 0 TO (SLOTS_PER_SET-1);

	SIGNAL valids: VALIDS_TYPE := (others => (others => '0'));					-- Stores the valid bit for each cache entry
	SIGNAL dirty: VALIDS_TYPE := (others => (others => '0'));					-- Stores the valid bit for each cache entry
	SIGNAL cache: CACHE_TYPE;
	SIGNAL tags_vector: TAG_TYPE;
	SIGNAL state: STATE_TYPE := POWERON;
	SIGNAL tag: STD_LOGIC_VECTOR(15-(word_bits+set_bits+2+1) downto 0);			-- Stores extracted tag from input address
	SIGNAL word_offset: integer range 0 to (2**word_bits)-1;					-- Stores extracted word offset from input address
	SIGNAL byte_offset: integer range 0 to 3;									-- Stores extracted byte offset from input address (should always be 0 if aligned)
	SIGNAL index: integer range 0 to SETS-1;									-- Stores extracted index from input address
	SIGNAL queues: QUEUE_HEADS := (others => 0);
begin

-- make circuits here
	machine: process(clock, reset)
		VARIABLE data: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');			-- Stores data that is to be written to main memory
		VARIABLE byte_index: integer range 0 to 4 := 0;								-- Counts the byte (within a word) that is currently being read/written
		VARIABLE word_index: integer range 0 to (2**word_bits) := 0;				-- Counts the word (within a block) that is currently being read/written
		VARIABLE write_miss: std_logic := '0';										-- Indicates if the cache miss came from a read or a write
	begin
		if(reset = '1') then
			state <= POWERON;
		elsif(rising_edge(clock)) then
			case (state) IS
				WHEN POWERON => -- Initialize all dirty and valid bits to 0
					valids <= (others => (others => '0'));
					dirty <= (others => (others => '0'));
					m_read <= '0';
					m_write <= '0';
					state <= IDLE;
				WHEN IDLE => -- Main waiting state
					if(s_read = '1') THEN
						state <= CACHE_MISS;
						byte_index := 0;
						word_index := 0;
						-- search for matching tag in set
						-- TODO: Add delay?
						FOR i in 0 to SETS - 1 LOOP
							if(tag = tags_vector(index)(i) and valids(index)(i) = '1') then
								state <= HIT; -- Indicates that the cache's job is done
							end if;
						END LOOP;
					elsif(s_write = '1') THEN
						data := s_writedata;
						byte_index := 0;
						word_index := 0;
						write_miss := '1';
						state <= CACHE_MISS;
						-- search for matching tag in set
						-- TODO: Add delay?
						FOR i in 0 to SETS - 1 LOOP
							if(tag = tags_vector(index)(i) and valids(index)(i) = '1') then
								cache(index)(i)(word_offset) <= data;
								dirty(index)(i) <= '1';
								write_miss := '0';
								state <= HIT;
							end if;
						END LOOP;
					end if;
				WHEN CACHE_MISS =>
					-- Upon cache miss, regardless of read or write, must check if block is dirty
					-- If dirty, always write to memory
					-- TODO: Implement more clever eviction policy
					queues(index) <= (queues(index) + 1) rem SLOTS_PER_SET;
					if(dirty(index)(queues(index)) = '1') then
						state <= MEM_WRITE;
					else
						state <= MEM_READ;
					end if;
				WHEN HIT =>
					-- If we're in the HIT state,
					-- we know that the desired word is in the cache
					-- therefore the correct tag is guaranteed to be in the set
					s_readdata <= cache(index)(0)(word_offset);
					FOR i IN 0 TO SLOTS_PER_SET-1 LOOP
						IF tag = tags_vector(index)(i) THEN
							s_readdata <= cache(index)(i)(word_offset);
						END IF;
					END LOOP;
					state <= IDLE; -- Set waitrequest LOW for one clock cycle
				WHEN MEM_READ =>
					m_addr <= to_integer(unsigned(tag))*(2**(2+word_bits+set_bits)) + index*(2**(2+word_bits)) + word_index*4 + byte_index;
					m_read <= '1';

					--TODO: Implement more clever eviction policy
					dirty(index)(queues(index)) <= '0'; -- Newly-read block is always clean
					valids(index)(queues(index)) <= '1'; -- Newly-read block is always valid
					tags_vector(index)(queues(index)) <= tag;
					
					-- TODO: Edited to read FULL BLOCK from memory. This needs to be reviewed
					if(m_waitrequest = '0') then
						cache(index)(queues(index))(word_index)((byte_index + 1) * 8 - 1 downto byte_index * 8) <= m_readdata; -- Read appropriate byte from word
						byte_index := byte_index + 1;
						m_read <= '0';
						if(byte_index = 4) then
							byte_index := 0;
							word_index := word_index + 1;
							-- Check if full block was read
							if(word_index = (2**word_bits)) THEN
								if(write_miss = '1') then
									write_miss := '0';
									cache(index)(queues(index))(word_offset) <= data; -- When finished reading, write appropriate word in block if a write was requested
									dirty(index)(queues(index)) <= '1';
								end if;
								state <= HIT;
								word_index := 0;
								m_read <= '0';
							END IF;
						end if;
					end if;
				WHEN MEM_WRITE =>
					-- Memory writes are only ever called when replacing a dirty block, whether it's with a read or a write
					-- Must transition to a memory read always after a memory write, to bring appropriate block into cache
					-- TODO: Edited to write FULL BLOCK to memory. This needs to be reviewed
					if(byte_index = 4) then
						byte_index := 0;
						word_index := word_index + 1;
						if(word_index = (2**word_bits)) THEN
							word_index := 0;
							m_write <= '0';
							state <= MEM_READ;
						END IF;
					elsif(m_waitrequest = '0') then
						byte_index := byte_index + 1;
						m_write <= '0';
					else
						--TODO: Implement more clever eviction policy
						m_addr <= to_integer(unsigned(tags_vector(index)(queues(index))))*(2**(2+word_bits+set_bits)) + index*(2**(2+word_bits)) + word_index*4 + byte_index;
						m_writedata <= cache(index)(queues(index))(word_index)((byte_index + 1) * 8 - 1 downto byte_index * 8);
						m_write <= '1';
					end if;
				WHEN others => null;
			end case;
		end if;
	end process;

--	s_readdata <= cache(index)(word_offset);					-- We can continuously update this output because the processor will only read it in the HIT state
	tag <= s_addr(14 downto (word_bits+set_bits+2));
	index <= to_integer(unsigned(s_addr((word_bits + set_bits + 2 - 1) downto (word_bits + 2))));
	word_offset <= to_integer(unsigned(s_addr((word_bits + 2 - 1) downto 2)));
	byte_offset <= to_integer(unsigned(s_addr(1 downto 0)));
	s_waitrequest <= '0' WHEN state = HIT ELSE '1';

end arch;
