all: comp

comp: lexer.o parser.o symboltable.o emitter.o main.cpp
	g++ -std=c++17 -Wall -g symboltable.o lexer.o parser.o emitter.o main.cpp -lfmt  -o comp 

lexer.o : lexer.cpp parser.hpp
	g++ -std=c++17 -Wall -g -c lexer.cpp -o lexer.o -lfmt

symboltable.o : symboltable.cpp symboltable.hpp
	g++  -std=c++17 -Wall -g -c symboltable.cpp -o symboltable.o -lfmt

emitter.o : emitter.cpp emitter.hpp
	g++ -std=c++17 -Wall -g -c emitter.cpp -o emitter.o -lfmt

parser.o : parser.cpp 
	g++ -std=c++17 -Wall -g -c parser.cpp -o parser.o -lfmt

parser.cpp parser.hpp: parser.y 
	bison -d -o parser.cpp parser.y

lexer.cpp lexer.hpp: lexer.l 
	flex -o lexer.cpp --header=lexer.hpp lexer.l 


.PHONY: clean test


clean: 
	-rm -f 	comp lexer.h parser.h comp.o lexer.o parser.o lexer.c parser.c symboltable.o test_results_good_bison.txt
