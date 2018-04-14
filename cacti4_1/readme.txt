To use cacti, open a Bash console and run the command ./cacti
The command takes parameters in the following order:
Total Cache Size, Block Size (Bytes), Associativity, VDD (Divided by 10), Number of Read/Write Ports, Number of Read Ports, Number of Write Ports, Number of Banks

The data from the simulation is output to the console once you run the command

Config1: 4KB cache, 32B/line, Direct Map
./cacti 4096 32 1 0.13 1 2 2 1

Config2: 4KB cache, 32B/line, 2 Way Associativity
./cacti 4096 32 2 0.13 1 2 2 1

Config3: 16KB cache, 32B/line, Direct Map
./cacti 16384 32 1 0.13 1 2 2 1

Config4: 16KB cache, 32B/line, 4 Way Associativity
./cacti 16384 32 4 0.13 1 2 2 1