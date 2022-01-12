%option nounput
%option noinput
%option noyywrap
%option yylineno
%{
    #include "parser.hpp"
%}
digits      [0-9]+
integer     {digits}
real        {digits}\.{digits}([Ee][\+\-]?{digits})?
id          [a-zA-Z][a-zA-Z0-9]*
whitespace  [ \t\r]+
mathop      [\-\+\/\*\%]

%%
{whitespace}    ;    // eat up whitespace
"program"       return TOK_PROGRAM;
"var"           return TOK_VAR;
"array"         return TOK_ARRAY;
"of"            return TOK_OF;
"write"         return TOK_WRITE;
"integer"       return TOK_INTEGER;
"real"          return TOK_REAL;
"function"      return TOK_FUNCTION;
"procedure"     return TOK_PROCEDURE;
"begin"         return TOK_BEGIN;
"end"           return TOK_END;
":="            return TOK_ASSIGNOP;
"if"            return TOK_IF;
"then"          return TOK_THEN;
"else"          return TOK_ELSE;
"while"         return TOK_WHILE;
"do"            return TOK_DO;
"not"           return TOK_NOT;
"or"            return TOK_OR;
"and"           return TOK_AND;
"<="            return TOK_LE;
">="            return TOK_GE;
"<>"            return TOK_NEQ;
"div"           return TOK_DIV;
"mod"           return TOK_MOD;
{id}            {
                    std::string parsedText(yytext);
                    int idPosition = SymbolTable::getDefault()->insertOrGetSymbolIndex(parsedText);
                    yylval = idPosition;
                    return TOK_ID;
                }
{integer}       {
                    std::string parsedText(yytext);
                    int idPosition = SymbolTable::getDefault()->insertOrGetNumericalConstant(parsedText);
                    yylval = idPosition;
                    return TOK_NUM;
                }
{real}          {
                    std::string parsedText(yytext);
                    int idPosition = SymbolTable::getDefault()->insertOrGetNumericalConstant(parsedText);
                    yylval = idPosition;
                    return TOK_NUM;
                }
\n              {} // yylineno
.               return yytext[0];

%%

