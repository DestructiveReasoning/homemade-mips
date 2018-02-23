SRCDIR=./src
CACHEDIR=$(SRCDIR)/Cache
BUILDDIR=./build
TESTDIR=./test

processor: cache

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
