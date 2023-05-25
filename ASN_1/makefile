BIN  = bC  # name of thing to be built goes here
CC   = g++
# CFLAGS = -g
# CCFLAGS = -DCPLUSPLUS -g  # for use with C++ if file ext is .cc
# CFLAGS = -DCPLUSPLUS -g  # for use with C++ if file ext is .c

SRCS = parser.y parser.l token.h
OBJS = lex.yy.o parser.tab.o
LIBS = -lm 

bC: $(OBJS)
	$(CC) $(CCFLAGS) $(OBJS) $(LIBS) -o bC

parser.tab.h parser.tab.c: parser.y
	bison -v -t -d parser.y  

lex.yy.c: parser.l parser.tab.h
	flex parser.l

all:    
	touch $(SRCS)
	make

clean:
	rm -f $(OBJS) bC lex.yy.c parser.tab.h parser.tab.c bC.tar parser.output core

tar:
	tar -cvf bC.tar $(SRCS) makefile 
