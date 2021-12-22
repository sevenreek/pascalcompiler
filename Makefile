all: comp

comp: parser.o symtable.o lexer.o
	g++ -Wall -g symtable.o lexer.o parser.o -o comp

lexer.o : lexer.c lexer.h parser.h
	g++ -Wall -g -c lexer.c -o lexer.o

symtable.o : symtable.c symtable.h parser.h
	g++ -Wall -g -c symtable.c -o symtable.o

parser.o : parser.c symtable.h lexer.h parser.h
	g++ -Wall -g -c parser.c -o parser.o

parser.c parser.h: parser.y 
	bison -d -o parser.c parser.y

lexer.c lexer.h: lexer.l 
	flex -o lexer.c --header=lexer.h lexer.l 


.PHONY: clean test

test: test_results_good_original.txt comp tests_good.txt
	./comp < tests_good.txt > test_results_good_bison.txt
	diff -s test_results_good_bison.txt test_results_good_original.txt

clean: 
	-rm -f 	comp lexer.h parser.h comp.o lexer.o parser.o lexer.c parser.c symtable.o test_results_good_bison.txt