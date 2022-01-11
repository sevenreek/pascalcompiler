#include "parser.hpp"
#include "lexer.hpp"
#include <iostream>
#include <fmt/format.h>
#include <exception>

void yyerror(std::string s)
{
  throw std::runtime_error(s);
}
int main()
{
    SymbolTable st;
    st.setDefault();
    Emitter e("output.asm");
    e.setDefault();
    try {
      yyparse();
    } catch (const std::runtime_error& e) {
      fmt::print("error @{}: {}\n", yylineno, e.what());
    }
    yylex_destroy();
    exit(0);
}
