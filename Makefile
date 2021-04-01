.PHONY: clean all examples
.SECONDARY:

all::

# Commands, default directories.

SHELL=/bin/sh
INSTALL=/usr/bin/install
INSTALL_PROGRAM=$(INSTALL)
INSTALL_DATA=$(INSTALL) -m 644
CMP=/bin/cmp -s
CP=/bin/cp

prefix=/usr/local
exec_prefix=$(prefix)
bindir=$(exec_prefix)/bin
libdir=$(exec_prefix)/lib
includedir=$(prefix)/include
datarootdir=$(prefix)/share
mandir=$(datarootdir)/man

.SUFFFIXES:
.SUFFFIXES: .cc .o

# General set up: sources, default targets.

top:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))

VPATH=$(top)src:$(top)lib:$(top)test

all:: lmorpho liblmorpho.a

lib-src:=placeholder.cc
exe-src:=lmorpho.cc
test-src:=unit.cc

all-src:=$(test-src) $(exe-src) $(lib-src)
all-obj:=$(patsubst %.cc, %.o, $(all-src))

gtest-top:=$(top)test/googletest/googletest
gtest-inc:=$(gtest-top)/include
gtest-src:=$(gtest-top)/src/gtest-all.cc

OPTFLAGS?=-O3 -march=native -g
CXXFLAGS+=$(OPTFLAGS) -MMD -MP -std=c++17 -pthread
CPPFLAGS+=-isystem $(gtest-inc) -I $(top)lib/include -I .

depends:=$(patsubst %.cc, %.d, $(all-src)) gtest.d
-include $(depends)

gtest.o: CPPFLAGS+=-I $(gtest-top)
gtest.o: ${gtest-src}
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -o $@ -c $<

# Unit tests:

unit: $(patsubst %.cc, %.o, $(test-src)) gtest.o
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -o $@ $^ $(LDFLAGS) $(LDLIBS)

# Library:

liblmorpho.a: $(patsubst %.cc, %.o, $(lib-src))
	$(AR) rcs $@ $^

# Command line tool:

lmorpho: $(patsubst %.cc, %.o, $(exe-src)) liblmorpho.a
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -o $@ $^ $(LDFLAGS) $(LDLIBS)

# Clean up:

clean:
	rm -f $(all-obj)

realclean: clean
	rm -f unit lmorpho liblmorpho.a gtest.o $(depends)

# Install:

public-includes:=$(wildcard $(top)lib/include/lmorpho/*.h)

install: lmorpho liblmorpho.a
	$(INSTALL_PROGRAM) -D lmorpho $(DESTDIR)$(bindir)/lmorpho
	$(INSTALL_DATA) -D liblmorpho.a $(DESTDIR)$(libdir)/liblmorpho.a
	$(INSTALL) -d $(DESTDIR)$(includedir)/lmorpho
	$(INSTALL_DATA) $(public-includes) $(DESTDIR)$(includedir)/lmorpho
