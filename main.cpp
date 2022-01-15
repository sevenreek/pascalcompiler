#include "parser.hpp"
#include "lexer.hpp"
#include <iostream>
#include <fmt/format.h>
#include <exception>

void yyerror(std::string s)
{
  throw std::runtime_error(s);
}
int main(int argc, char* argv[])
{
    SymbolTable st;
    st.setDefault();
    std::string outfile{"myoutput.asm"};
    if(argc > 2) outfile = argv[2];
    Emitter e(outfile);
    e.setDefault();
    FILE * infilePointer = nullptr;
    
      if(argc > 1) {
        infilePointer = fopen(argv[1], "r");
        auto bufState = yy_create_buffer(infilePointer, YY_BUF_SIZE);
        yy_switch_to_buffer(bufState);
      }
      yyparse();
    try {
    } catch (const std::runtime_error& e) {
      fmt::print("error at line {}: {}\n", yylineno, e.what());
    }
    yylex_destroy();
    exit(0);
}
