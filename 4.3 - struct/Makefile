LEX = lex 
YACC = yacc -d 

CC = CC

struct: y.tab.o lex.yy.o functions.o
	$(CC) -o $@ y.tab.o lex.yy.o functions.o

lex.yy.o: lex.yy.c y.tab.h

y.tab.c y.tab.h: parser.y
	$(YACC) parser.y
lex.yy.c: lexer.l 
	$(LEX) lexer.l
functions.o : functions.c

clean:
	-rm -f *.o lex.yy.c *.tab.* struct