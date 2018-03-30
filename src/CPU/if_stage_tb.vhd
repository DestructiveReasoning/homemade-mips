library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

ENTITY if_stage_tb IS
END if_stage_tb;

ARCHITECTURE test of if_stage_tb IS
    COMPONENT if_stage IS
        PORT(
            new_addr:   IN STD_LOGIC_VECTOR(31 downto 0);   
            pc_en:      IN STD_LOGIC;
            clock:      IN STD_LOGIC;
            q_new_addr: OUT STD_LOGIC_VECTOR(31 downto 0);
            q_instr:    OUT STD_LOGIC_VECTOR(31 downto 0)
        );
    END COMPONENT;

    SIGNAL new_addr: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL pc_en: STD_LOGIC := '0';
    SIGNAL clock: STD_LOGIC := '0';
    SIGNAL q_new_addr: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL q_instr: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    SIGNAL finished: std_logic := '0';
    CONSTANT clock_period : time := 1 ns;

    constant ram_size : integer := 1024;
	  TYPE MEM IS ARRAY(ram_size-1 downto 0) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
    constant init_file : string := "program.txt";

    function init_mem return MEM is
      variable init_value : MEM;
  
      file instr_file : text;
      variable instr_line : line;
      variable instr : STD_LOGIC_VECTOR(31 downto 0);
      variable i : integer range 0 to ram_size;
  
    begin
      for i in 0 to ram_size-1 loop
       init_value(i) := (others => '0');
      end loop;
  
      if(init_file /= "") then
  		  file_open(instr_file, init_file, read_mode);
        for i in 0 to ram_size-1 loop
          if not endfile(instr_file) then
            readline (instr_file, instr_line);
            read(instr_line, instr);
            init_value(i) := instr;
          else
            init_value(i) := (others => '0');
          end if;
        end loop;
        file_close(instr_file);
      end if;
      return init_value;
    end function init_mem;

  constant init_rom : MEM := init_mem;

BEGIN
    fetch: if_stage
    PORT MAP (
        new_addr    => new_addr,
        pc_en       => pc_en,
        clock       => clock,
        q_new_addr  => q_new_addr,
        q_instr     => q_instr
    );

    test: process
    BEGIN
    pc_en <= '1';

    new_addr <= (others => '0');
    wait for clock_period;

    for i in 0 to 20 loop
      new_addr <= q_new_addr;
      wait for clock_period;
    end loop;

    wait;
    END process;

    data_validator : process
    begin
      wait for clock_period;
      for i in 0 to 10 loop
        assert q_instr = init_rom(i);
        wait for 1*clock_period;
      end loop;
      wait;
    end process;
END test;
