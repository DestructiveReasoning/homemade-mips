library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY registerfile_tb IS
END registerfile_tb;

ARCHITECTURE test OF registerfile_tb IS
    COMPONENT registerfile IS
        PORT(
            clock       : IN std_logic;
            reset       : IN std_logic;
            rs          : IN std_logic_vector(4 downto 0);
            rt          : IN std_logic_vector(4 downto 0);
            rd          : IN std_logic_vector(4 downto 0);
            write_en    : IN std_logic;
            write_file  : IN std_logic;
            write_data  : IN std_logic_vector(31 downto 0);
            rs_data     : OUT std_logic_vector(31 downto 0);
            rt_data     : OUT std_logic_vector(31 downto 0)
        );
    END COMPONENT;

    SIGNAL clock: std_logic := '0';
    SIGNAL reset: std_logic := '0';
    SIGNAL rs: std_logic_vector(4 downto 0) := (others => '0');
    SIGNAL rt: std_logic_vector(4 downto 0) := (others => '0');
    SIGNAL rd: std_logic_vector(4 downto 0) := (others => '0');
    SIGNAL write_en: std_logic := '0';
    SIGNAL write_file: std_logic := '0';
    SIGNAL write_data: std_logic_vector(31 downto 0) := (others => '0');
    SIGNAL rs_data: std_logic_vector(31 downto 0);
    SIGNAL rt_data: std_logic_vector(31 downto 0);

    CONSTANT clock_period: time := 1 ns;
    SIGNAL finished: std_logic := '0';

BEGIN
    reg: registerfile
    PORT MAP (
        clock => clock,
        reset => reset,
        rs => rs,
        rd => rd,
        rt => rt,
        write_en => write_en,
        write_data => write_data,
        write_file => write_file,
        rs_data => rs_data,
        rt_data => rt_data
    );

    -- updating clock this way avoids endless hang when running tb via ghdl
    -- this method lets us explicitly stop the clock
    clock <= '0' WHEN (finished = '1') ELSE NOT clock AFTER 0.5 * clock_period;

    test: process
    BEGIN
        -- verify that data is being written to appropriate register
        rd <= "00010";
        write_data <= X"DEADBEEF";
        rs <= "00010";
        WAIT FOR clock_period;
        ASSERT rs_data = X"00000000" REPORT "Data written prematurely!" SEVERITY ERROR;
        write_en <= '1';
        WAIT FOR clock_period;
        write_en <= '0';
        WAIT FOR clock_period; --rs_data and rt_data are available 1CC after write_en was asserted
        ASSERT rs_data = X"DEADBEEF" REPORT "Data not written to destination register!" SEVERITY ERROR;
        -- verify that $0 cannot be written to
        rs <= "00000";
        rd <= "00000";
        WAIT FOR clock_period;
        write_en <= '1';
        WAIT FOR clock_period;
        write_en <= '0';
        WAIT FOR clock_period;
        ASSERT rs_data = X"00000000" REPORT "$0 register was overwritten!" SEVERITY ERROR;
        write_file <= '1';
        WAIT FOR clock_period;
        write_file <= '0';
        WAIT FOR clock_period;
        finished <= '1';
        WAIT;
    END process;
END test;
