library ieee;
use ieee.std_logic_1164.all;

ENTITY busmux21 IS
    GENERIC (
        width: integer := 32
    );

    PORT (
        data0:  IN std_logic_vector(width-1 downto 0);
        data1:  IN std_logic_vector(width-1 downto 0);
        sel:    IN std_logic;
        output: OUT std_logic_vector(width-1 downto 0)
    );
END busmux21;

ARCHITECTURE multiplexer OF busmux21 IS
BEGIN
    output <= data0 WHEN sel = '0' else data1;
END multiplexer;
