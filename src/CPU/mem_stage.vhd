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
    
    signal next_data, next_alu, next_address: STD_LOGIC_VECTOR(31 downto 0);
    
BEGIN
    process(clock)
    BEGIN
        if(rising_edge(clock)) then
            -- TODO deal with memory
        END IF;
    END process;
END memory;
