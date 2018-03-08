library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY ALU IS
    PORT(
        clock   : IN std_logic;
        a       : IN std_logic_vector(31 downto 0);
        b       : IN std_logic_vector(31 downto 0);
        funct   : IN std_logic_vector(4 downto 0); -- we are supposed to support 27 instructions
        output  : OUT std_logic_vector(31 downto 0)
    );
END ALU;

ARCHITECTURE calculator OF ALU IS
    -- 64 bit register to accomadate mfhi and mflo
    SIGNAL wide_out: std_logic_vector(63 downto 0);

BEGIN
    process  (a, b, funct, clock)
    BEGIN
        CASE funct IS
            when "00000" => -- add (includes add, addi, lw, sw)
                output <= std_logic_vector(signed(a) + signed(b));
            when "00001" => -- sub
                output <= std_logic_vector(signed(a) - signed(b));
            when "00010" => -- mult
                if(rising_edge(clock)) then
                    wide_out <= std_logic_vector(signed(a) * signed(b));
                end if;
                output <= std_logic_vector(to_signed(to_integer(signed(a)) * to_integer(signed(b)), 32));
            when "00011" => -- div
                -- remainder goes to hi portion of 64b reg, division goes to lo portion, as per MIPS spec
                if(rising_edge(clock)) then
                    wide_out(63 downto 32) <= std_logic_vector(unsigned(a) mod unsigned(b));
                    wide_out(31 downto 0) <= std_logic_vector(signed(a) / signed(b));
                end if;
                output <= std_logic_vector(to_signed(to_integer(signed(a)) / to_integer(signed(b)), 32));
            when "00100" => -- set less than (includes slt and slti)
                if(to_integer(unsigned(a)) < to_integer(unsigned(b))) then
                    output <= X"00000001";
                else
                    output <= X"00000000";
                end if;
            when "00101" => -- and (includes and, andi)
                output <= a AND b;
            when "00110" => -- or (includes or, ori)
                output <= a OR b;
            when "00111" => -- xor (includes xor, xori)
                output <= a xor b;
            when "01000" => -- mfhi
                output <= wide_out(63 downto 32);
            when "01001" => -- mflo
                output <= wide_out(31 downto 0);
            when "01010" => -- lui
                output <= b(15 downto 0) & X"0000"; -- note that we use b because imm is always loaded into input b of the ALU
            when "01011" => -- sll
                if(to_integer(unsigned(b)) >= 32) then
                    output <= X"00000000";
                else
                    output <= a(31 - to_integer(unsigned(b)) downto 0) & std_logic_vector(to_unsigned(0, to_integer(unsigned(b))));
                end if;
            when "01100" => -- srl
                if(to_integer(unsigned(b)) >= 32) then
                    output <= X"00000000";
                else
                    output <= std_logic_vector(to_unsigned(0, to_integer(unsigned(b)))) & a(31 downto to_integer(unsigned(b)));
                end if;
            when "01101" => -- sra
                if(to_integer(unsigned(b)) >= 32) then
                    output <= X"00000000"; -- -0 = 0
                elsif(a(31) = '1') then
                    output <= (to_integer(unsigned(b)) - 1 downto 0 => '1') & a(31 downto (to_integer(unsigned(b))));
                else
                    output <= std_logic_vector(to_unsigned(0, to_integer(unsigned(b)))) & a(31 downto to_integer(unsigned(b)));
                end if;
            when "01110" => -- beq and bne (basically, computes new address when branch is taken)
                -- a stores PC+4, b stores branch distance
                output <= std_logic_vector(to_unsigned(to_integer(unsigned(a)) + 4 * to_integer(unsigned(b)), 32));
            when "01111" => -- jump (j and jal)
                -- a stores PC+4, b stores jump address
                -- j-type instructions store 26-bit pseudo-addresses
                -- to convert to 32 bit address, assume 4 MSB's are equivalent to PC+4's, and 2 LSB's are 0
                output <= a(31 downto 28) & b & "00";
            when "10000" => -- jump to register value
                output <= a;
            when others =>
                NULL;
        end CASE;
    END process;
END calculator;
