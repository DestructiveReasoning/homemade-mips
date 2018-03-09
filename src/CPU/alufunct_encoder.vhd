library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY ALUFunct_Encoder IS
    PORT(
        opcode  : IN std_logic_vector(5 downto 0);
        funct   : IN std_logic_vector(5 downto 0);
        code    : OUT std_logic_vector(4 downto 0)
    );
END ALUFunct_Encoder;

ARCHITECTURE encoder OF ALUFunct_Encoder IS
BEGIN
    process (opcode, funct)
    BEGIN
        CASE opcode IS
            WHEN "000000" =>
                CASE funct IS
                    WHEN "100000" =>        -- add
                        code <= "00000";
                    WHEN "100010" =>        -- sub
                        code <= "00001";
                    WHEN "011000" =>        -- mult
                        code <= "00010";
                    WHEN "011010" =>        -- div
                        code <= "00011";
                    WHEN "101010" =>        -- slt
                        code <= "00100";
                    WHEN "100100" =>        -- and
                        code <= "00101";
                    WHEN "100101" =>        -- or
                        code <= "00110";
                    WHEN "100110" =>        -- xor
                        code <= "00111";
                    WHEN "100111" =>        -- nor
                        code <= "10001";
                    WHEN "010000" =>        -- mfhi
                        code <= "01000";
                    WHEN "010010" =>        -- mflo
                        code <= "01001";
                    WHEN "000000" =>        -- sll
                        code <= "01011";
                    WHEN "000010" =>        -- srl
                        code <= "01100";
                    WHEN "000011" =>        -- sra
                        code <= "01101";
                    WHEN "001000" =>        -- jr
                        code <= "10000";
                    WHEN OTHERS => NULL;
                END CASE;
            WHEN "001000" =>                -- addi
                code <= "00000";
            WHEN "001010" =>                -- slti
                code <= "00100";
            WHEN "001100" =>                -- andi
                code <= "00101";
            WHEN "001101" =>                -- ori
                code <= "00110";
            WHEN "001110" =>                -- xori
                code <= "00111";
            WHEN "001111" =>                -- lui
                code <= "01010";
            WHEN "100011" =>                -- lw
                code <= "00000";
            WHEN "101011" =>                -- sw
                code <= "00000";
            WHEN "000100" =>                -- beq
                code <= "01110";
            WHEN "000101" =>                -- bne
                code <= "01110";
            WHEN "000010" =>                -- j
                code <= "01111";
            WHEN "000011" =>                -- jal
                code <= "01111";
            WHEN OTHERS => NULL;
        END CASE;
    END PROCESS;
END encoder;
