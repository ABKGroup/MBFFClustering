CSRCS = $(wildcard *.cpp)
CHDRS = $(wildcard *.h)
COBJS = $(addsuffix .o, $(basename $(CSRCS)))

DEPENDDIR = -I. -I$(BOOSTDIR) -L$(BOOSTDIR)/libs
TSAN ?= false
ASAN ?= false
CXX   = g++ 
CCC   = gcc
AR    = ar cr
ECHO  = /bin/echo
EXEC  = clustering
DIRS  = bin
ifeq ($(TSAN), true)
CXX += -std=c++14
else 
ifeq ($(ASAN), true)
CXX += -std=c++14
else
CXX += -std=c++11
endif
endif

CFLAGS = -O3 $(DEPENDDIR) -fopenmp -lboost_program_options

ifeq ($(TSAN), true)
CFLAGS += -fsanitize=thread -fPIC -pie -g -DTSAN
else 
ifeq ($(ASAN), true)
CFLAGS += -fno-omit-frame-pointer -fno-optimize-sibling-calls -fsanitize=address -fsanitize-recover=address -DASAN
else
CFLAGS += -Wall -Wextra -pedantic-errors -Werror -Wconversion	
endif
endif

.PHONY: depend

all: directory $(COBJS)
	@$(ECHO) "> building -> $(EXEC) ..."
	@$(CXX) $(CFLAGS) $(COBJS) -o bin/$(EXEC)
#	@ln -fs bin/$(EXEC) $(EXEC)

directory:
	@for dir in $(DIRS); \
	do \
		if [ ! -d $$dir ]; then \
			mkdir $$dir; \
			echo "Creating directory \"$$dir\" ..."; \
		fi; \
	done

%.o: %.cpp
	@$(ECHO) "> compiling: $< ..."
	@$(CXX) $(CFLAGS) -c -o $@ $<

clean:
	@rm -f *.o
#	@rm -f $(EXEC)
	@rm -f bin/$(EXEC)

## Make dependencies
depend: .depend.mak
.depend.mak: $(CSRCS) $(CHDRS)
	@$(ECHO) Making dependencies ...
	@$(CXX) -MM $(DEPENDDIR) $(CSRCS) > $@

include .depend.mak
