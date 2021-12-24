#include "parser.hpp"
#include "lexer.hpp"
#include <iostream>
#include <fmt/format.h>

void yyerror(char *s)
{
  throw std::runtime_error(s);
  exit(1);
}
int main()
{
    SymbolTable st;
    st.setDefault();
    Emitter e("output.out");
    e.setDefault();
    yyparse();
    yylex_destroy();
    exit(0);
}
