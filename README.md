# homemade-mips
VHDL implementation of the MIPS ISA

Project 4  <br />
Instruction Set Architecture: <br />
* IF
* ID
* EX
* MEM
* WB
* Instruction pipeline registers
* Registers completed by Harley
* MUX
* Controller
* ALU

Register $0 must be wired to 0x0000, PC initialized to 0x0 <br />
No functionality for FPU and Interrupts and Exceptions <br />

Hazard Detection: Stalls instructions in ID when a required operand is not ready yet. A stall (bubble) can be inserted in the pipeline. <br />
Forwarding: Take results from EX/ME and ME/WB pipeline registers and make them available as ALU inputs. Recommended that you implement forwarding second, after hazard detection has been tested. <br />
Memory: Instantiate two memories, one for instructions and one for data. Use the model provided previously from P3. Keep data memory sized at 32768 bytes. Processor can run a program of at most 1024 instructions. <br />
Testbench: Testbench reads a program called "program.txt" and write final contents of the register file to a text called "register_file.txt".
