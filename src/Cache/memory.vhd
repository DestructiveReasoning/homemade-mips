--Adapted from Example 12-15 of Quartus Design and Synthesis handbook
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

ENTITY memory IS
	GENERIC(
		ram_size : INTEGER := 32768;
		mem_delay : time := 10 ns;
		clock_period : time := 1 ns;
    init_file : string := ""
	);
	PORT (
		clock: IN STD_LOGIC;
		writedata: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		address: IN INTEGER RANGE 0 TO ram_size-1;
		memwrite: IN STD_LOGIC;
		memread: IN STD_LOGIC;
		readdata: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		waitrequest: OUT STD_LOGIC
	);
END memory;

ARCHITECTURE rtl OF memory IS
	TYPE MEM IS ARRAY(ram_size-1 downto 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL read_address_reg: INTEGER RANGE 0 to ram_size-1;
	SIGNAL write_waitreq_reg: STD_LOGIC := '1';
	SIGNAL read_waitreq_reg: STD_LOGIC := '1';

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
          for k in 0 to 3 loop
            -- little endian system
            -- instruction msb in higher address
            -- TODO Make sure instruction bytes are loaded in correct order
            init_value((i*4)+k) := instr(7+k*8 downto k*8);
          end loop;
        end if;
      end loop;
      file_close(instr_file);
    else
      -- for cache_tb.vhd
      -- not meant to be actually used
      for i in 0 to ram_size-1 loop
        init_value(i) := std_logic_vector(to_unsigned(i, 8));
      end loop;
    end if;
    return init_value;
  end function init_mem;

  constant init_rom : MEM := init_mem;
  -- init ram data using program file from disk
	SIGNAL ram_block: MEM := init_rom;

BEGIN
	--This is the main section of the SRAM model
	mem_process: PROCESS (clock)
	BEGIN
		--This is the actual synthesizable SRAM block
		IF (clock'event AND clock = '1') THEN
			IF (memwrite = '1') THEN
				ram_block(address) <= writedata;
			END IF;
		read_address_reg <= address;
		END IF;
	END PROCESS;
	readdata <= ram_block(read_address_reg);


	--The waitrequest signal is used to vary response time in simulation
	--Read and write should never happen at the same time.
	waitreq_w_proc: PROCESS (memwrite)
	BEGIN
		IF(memwrite'event AND memwrite = '1')THEN
			write_waitreq_reg <= '0' after mem_delay, '1' after mem_delay + clock_period;

		END IF;
	END PROCESS;

	waitreq_r_proc: PROCESS (memread)
	BEGIN
		IF(memread'event AND memread = '1')THEN
			read_waitreq_reg <= '0' after mem_delay, '1' after mem_delay + clock_period;
		END IF;
	END PROCESS;
	waitrequest <= write_waitreq_reg and read_waitreq_reg;


END rtl;
