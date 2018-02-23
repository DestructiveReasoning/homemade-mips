SRCDIR=./src
CACHEDIR=$(SRCDIR)/Cache
BUILDDIR=./build

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

clean: 
	rm -rf $(BUILDDIR)
	rm *.o *.cf
