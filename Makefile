all: comp

comp: lexer.o parser.o parsingexception.o symbol.o symboltable.o emitter.o main.cpp
	g++ -std=c++2a -Wall -g parsingexception.o symbol.o symboltable.o lexer.o parser.o emitter.o main.cpp -lfmt  -o comp 

lexer.o : lexer.cpp parser.hpp
	g++ -std=c++2a -Wall -g -c lexer.cpp -o lexer.o -lfmt

symboltable.o : symboltable.cpp symboltable.hpp
	g++  -std=c++2a -Wall -g -c symboltable.cpp -o symboltable.o -lfmt

symbol.o : symbol.cpp symbol.hpp
	g++  -std=c++2a -Wall -g -c symbol.cpp -o symbol.o -lfmt

emitter.o : emitter.cpp emitter.hpp
	g++ -std=c++2a -Wall -g -c emitter.cpp -o emitter.o -lfmt

parser.o : parser.cpp 
	g++ -std=c++2a -Wall -g -c parser.cpp -o parser.o -lfmt

parser.cpp parser.hpp: parser.y 
	bison -d -o parser.cpp parser.y

lexer.cpp lexer.hpp: lexer.l 
	flex -o lexer.cpp --header=lexer.hpp lexer.l 

parsingexception.o : parsingexception.cpp parsingexception.hpp
	g++ -std=c++2a -Wall -g -c parsingexception.cpp -o parsingexception.o -lfmt

.PHONY: clean test


clean: 
	-rm -f 	comp lexer.h parser.h comp.o lexer.o parser.o lexer.c parser.c symboltable.o test_results_good_bison.txt
