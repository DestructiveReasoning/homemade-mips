library ieee;
use ieee.std_logic_1164.all;

ENTITY busmux41_tb IS
END busmux41_tb;

ARCHITECTURE test of busmux41_tb IS
    COMPONENT busmux41 IS
        GENERIC (
            width: integer
        );
        PORT (
            data00: IN std_logic_vector(width-1 downto 0);
            data01: IN std_logic_vector(width-1 downto 0);
            data10: IN std_logic_vector(width-1 downto 0);
            data11: IN std_logic_vector(width-1 downto 0);
            sel: IN std_logic_vector(1 downto 0);
            output: OUT std_logic_vector(width-1 downto 0)
        );
    END COMPONENT;

    SIGNAL data00, data01, data10, data11: std_logic_vector(31 downto 0) := (others => '0');
    SIGNAL sel: std_logic_vector(1 downto 0) := "00";
    SIGNAL output: std_logic_vector(31 downto 0);

BEGIN
    mux: busmux41 GENERIC MAP (width => 32)
    PORT MAP (
        data00 => data00,
        data01 => data01,
        data10 => data10,
        data11 => data11,
        sel => sel,
        output => output
    );
    process
    BEGIN
        WAIT FOR 1 ns;
        ASSERT output = X"00000000" REPORT "Invalid initialization!" SEVERITY ERROR;
        data00 <= X"48151623";
        data01 <= X"BADFACE0";
        data10 <= X"10101010";
        data11 <= X"DEADBEEF";
        WAIT FOR 1 ns;
        ASSERT output = X"48151623" REPORT "Invalid output at address 0!" SEVERITY ERROR;
        sel <= "01";
        WAIT FOR 1 ns;
        ASSERT output = X"BADFACE0" REPORT "Invalid output at address 1!" SEVERITY ERROR;
        sel <= "10";
        WAIT FOR 1 ns;
        ASSERT output = X"10101010" REPORT "Invalid output at address 2!" SEVERITY ERROR;
        sel <= "11";
        WAIT FOR 1 ns;
        ASSERT output = X"DEADBEEF" REPORT "Invalid output at address 3!" SEVERITY ERROR;
        WAIT FOR 1 ns;
        WAIT;
    END process;
END test;
