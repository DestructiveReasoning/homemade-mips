SRCDIR=./src
CACHEDIR=$(SRCDIR)/Cache
CPUDIR=$(SRCDIR)/CPU
MISCDIR=$(SRCDIR)/misc
BUILDDIR=./build
TESTDIR=./test

processor: cache misc cpu

all: processor

cache: memory
	ghdl -a $(CACHEDIR)/cache.vhd
	ghdl -e -o $(BUILDDIR)/cache cache

memory: init
	ghdl -a $(CACHEDIR)/memory.vhd
	ghdl -e -o $(BUILDDIR)/memory memory

init:
	mkdir -p $(BUILDDIR)

test_init: 
	mkdir -p $(TESTDIR)

clean: 
	rm -rf $(BUILDDIR)
	rm -rf $(TESTDIR)
	rm *.o *.cf

memory_test: memory test_init
	ghdl -a $(CACHEDIR)/memory_tb.vhd
	ghdl -e -o $(TESTDIR)/memory_tb memory_tb
	cd $(TESTDIR) && ghdl -r memory_tb --vcd=memory_tb.vcd

cache_test: cache test_init
	ghdl -a $(CACHEDIR)/cache_tb.vhd
	ghdl -e -o $(TESTDIR)/cache_tb cache_tb
	cd $(TESTDIR) && ghdl -r cache_tb --vcd=cache_tb.vcd

cpu: register alu stages
	ghdl -a --ieee=synopsys $(CPUDIR)/cpu_tb.vhd
	ghdl -e --ieee=synopsys -o $(BUILDDIR)/cpu_tb cpu_tb

stages: init
	ghdl -a --ieee=synopsys $(CPUDIR)/pipe_reg.vhd
	ghdl -e --ieee=synopsys -o $(BUILDDIR)/pipe_reg pipe_reg
	ghdl -a --ieee=synopsys $(CPUDIR)/if_stage.vhd
	ghdl -e --ieee=synopsys -o $(BUILDDIR)/if_stage if_stage
	ghdl -a --ieee=synopsys $(CPUDIR)/id_stage.vhd
	ghdl -e --ieee=synopsys -o $(BUILDDIR)/id_stage id_stage
	ghdl -a --ieee=synopsys $(CPUDIR)/mem_stage.vhd
	ghdl -e --ieee=synopsys -o $(BUILDDIR)/mem_stage mem_stage

register: init
	ghdl -a --ieee=synopsys $(CPUDIR)/registerfile.vhd
	ghdl -e --ieee=synopsys -o $(BUILDDIR)/registerfile registerfile

register_test: register test_init
	ghdl -a --ieee=synopsys $(CPUDIR)/registerfile_tb.vhd
	ghdl -e --ieee=synopsys -o $(TESTDIR)/registerfile_tb registerfile_tb
	cd $(TESTDIR) && ghdl -r registerfile_tb --vcd=registerfile_tb.vcd

alu: init
	ghdl -a --ieee=synopsys $(CPUDIR)/alu.vhd
	ghdl -e --ieee=synopsys -o $(BUILDDIR)/alu alu
	ghdl -a --ieee=synopsys $(CPUDIR)/alufunct_encoder.vhd
	ghdl -e --ieee=synopsys -o $(BUILDDIR)/alufunct_encoder alufunct_encoder
	
alu_test: alu test_init
	ghdl -a --ieee=synopsys $(CPUDIR)/alu_tb.vhd
	ghdl -e --ieee=synopsys -o $(TESTDIR)/alu_tb alu_tb
	cd $(TESTDIR) && ghdl -r alu_tb --vcd=alu_tb.vcd

misc: init
	ghdl -a $(MISCDIR)/busmux21.vhd
	ghdl -e -o $(BUILDDIR)/busmux21 busmux21
	ghdl -a $(MISCDIR)/busmux41.vhd
	ghdl -e -o $(BUILDDIR)/busmux41 busmux41
	ghdl -a $(MISCDIR)/signextender.vhd
	ghdl -e -o $(BUILDDIR)/signextender signextender

misc_test: misc test_init
	ghdl -a $(MISCDIR)/busmux41_tb.vhd
	ghdl -e -o $(TESTDIR)/busmux41_tb busmux41_tb
	cd $(TESTDIR) && ghdl -r busmux41_tb --vcd=busmux41_tb.vcd
	ghdl -a $(MISCDIR)/signextender_tb.vhd
	ghdl -e -o $(TESTDIR)/signextender_tb signextender_tb
	cd $(TESTDIR) && ghdl -r signextender_tb --vcd=signextender_tb.vcd
