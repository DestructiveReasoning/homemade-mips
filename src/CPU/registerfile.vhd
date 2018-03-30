library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

ENTITY registerfile IS
    PORT(
        clock       : IN std_logic;
        reset       : IN std_logic;                         -- to reset the register file (is this necessary?)
        rs          : IN std_logic_vector(4 downto 0);      -- source register number
        rt          : IN std_logic_vector(4 downto 0);      -- target register number
        rd          : IN std_logic_vector(4 downto 0);      -- destination register number
        write_en    : IN std_logic;                         -- control signal to write to rd
        write_file  : IN std_logic;                         -- control signal to write to the physical register file
        write_data  : IN std_logic_vector(31 downto 0);     -- data to write to rd
        rs_data     : OUT std_logic_vector(31 downto 0);    -- data in source register
        rt_data     : OUT std_logic_vector(31 downto 0)     -- data in target register
    );
END registerfile;

ARCHITECTURE registerstuff OF registerfile IS
    TYPE register_mem IS ARRAY (31 downto 0) OF std_logic_vector(31 downto 0);
    SIGNAL registers: register_mem := (others => (others => '0'));


BEGIN
    register_transfer: process (clock, reset) -- process for handling register transactions
    BEGIN
            rs_data <= registers(to_integer(unsigned(rs)));
            rt_data <= registers(to_integer(unsigned(rt)));
        if(reset = '1') then
            registers <= (others => (others => '0'));
        elsif(falling_edge(clock)) then
            -- rs_data and rt_data available one CC after write_en
          if(write_en = '1') then
            if(rd = "00000") then
              registers(0) <= (others => '0');
            else
              registers(to_integer(unsigned(rd))) <= write_data;
            end if;

            if(rd = rs) then
              rs_data <= write_data;
            end if;
            if(rd = rt) then 
              rt_data <= write_data;
            end if;
          end if;

        end if;
    END process;

    file_writer: process (write_file) -- process for handling writing data to physical register file
        file output_file: text open write_mode is "register_file.txt";
        variable output_line: line;
        variable row_line: integer := 0;
    BEGIN
        if(write_file = '1') then
            while(row_line < 32) LOOP -- iterate over each register and write to file
                write(output_line, registers(row_line));
                writeline(output_file, output_line);
                row_line := row_line + 1;
            END LOOP;
        end if;
    END process;
END registerstuff;
