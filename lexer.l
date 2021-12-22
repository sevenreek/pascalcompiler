%option nounput
%option noinput
%option noyywrap
%option yylineno
%{
    #include "parser.h"
%}
digits      [0-9]+
integer     {digits}
real        {digits}\.{digits}([Ee][\+\-]?{digits})?
id          [a-zA-Z][a-zA-Z0-9]*
whitespace  [ \t\r]+

%%
"program"   return PROGRAM;
{id}        {
                std::string parsedText(yytext);
                int idPosition = SymbolTable::getDefault().insertOrGetSymbolIndex(parsedText);
                yylval = idPosition;
                return ID;
            }
"var"       return VAR;
"array"     return ARRAY;
"of"        return OF;
{integer}   {
                std::string parsedText(yytext);
                int idPosition = SymbolTable::getDefault().insertOrGetNumericalConstant(parsedText);
                yylval = idPosition;
                return NUM;
            }
{real}      {
                std::string parsedText(yytext);
                int idPosition = SymbolTable::getDefault().insertOrGetNumericalConstant(parsedText);
                yylval = idPosition;
                return NUM;
            }
"integer"   return INTEGER;
"real"      return REAL;
"function"  return FUNCTION;
"procedure" return PROCEDURE;
"begin"     return BEGIN;
"end"       return END;
":="        return ASSIGNOP;
"if"        return IF;
"then"      return THEN;
"else"      return ELSE;
"while"     return WHILE;
"do"        return DO;
"not"       return NOT;
"or"        return OR;
"and"       return AND;
"<="        return LE;
">="        return GE;
"<>"        return NEQ;
"div"       return DIV;
"mod"       return MOD;
"=="        return EQ;

%%

