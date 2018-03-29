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

ARCHITECTURE memory OF mem_stage IS
    -- TODO: Instantiate memory
constant sz : integer := 127;
type register_mem is array (sz downto 0) of std_logic_vector(31 downto 0);
signal memory : register_mem := (others => (others => '0'));
signal next_data, next_alu, next_address: STD_LOGIC_VECTOR(31 downto 0);
signal i_addr : integer := to_integer(unsigned(addr));

-- Value from ALU to store, then address from, open up internal memory and write to address then store data in that
-- Include the part where it dumps to disk, include this from register vhd, logic to write to disk is there

BEGIN

   i_addr <= to_integer(unsigned(addr));

    process(clock)
    BEGIN
        if(rising_edge(clock)) then
		if(write = '1') then
			memory(i_addr) <= write_data;
		elsif(read = '1') then
			output <= memory(i_addr);
		end if;
        END IF;
    END process;
END memory;