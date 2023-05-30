BIN  = bC
PARSE = parser
CC   = g++
# CFLAGS = -g 
# CCFLAGS = -DCPLUSPLUS -g  # for use with C++ if file ext is .cc
CPPFLAGS = -g     # for use with C++ if file ext is .c
CPPFLAGS = -O3     # for use with C++ if file ext is .c

SRCS =\
$(PARSE).y\
$(PARSE).l\
main.cpp\
treeUtils.cpp\

HDRS =\
scanType.h\
treeNodes.h\
treeUtils.h\

OBJS = \
$(PARSE).tab.o\
lex.yy.o\
treeUtils.o\

LIBS = -lm 

$(PARSE): $(OBJS)
	$(CC) $(CPPFLAGS) $(OBJS) dot.o $(LIBS) -o bC

$(PARSE).tab.h $(PARSE).tab.c: $(PARSE).y scanType.h treeUtils.h
	bison -v -t -d $(PARSE).y  

lex.yy.c: $(PARSE).l $(PARSE).tab.h scanType.h
	flex $(PARSE).l

all:    
	touch $(SRCS)
	make

clean:
	/bin/rm *~ $(OBJS) $(BIN) lex.yy.c $(PARSE).tab.h $(PARSE).tab.c $(PARSE).tar $(PARSE).output

tar:
	tar -cvf $(BIN).tar $(SRCS) $(HDRS) makefile 
	ls -l $(BIN).tar

test:
	echo $(TSTS) | xargs -n1 runtest

tartests: 
	tar -cvf setOfTests.tar $(TSTS) $(OUTS) $(OUTP)
	tar -cvf justTests.tar $(TSTS)
	ls -l setOfTests.tar justTests.tar

tarall: 
	make tartests
	tar -cvf $(BIN)-all.tar $(SRCS) $(HDRS) $(TSTS) setOfTests.tar makefile	
	ls -l $(BIN)-all.tar

