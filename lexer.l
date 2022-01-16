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
sc_sign     [\-\+]
sc_relops   [><=]
sc_mulops   [\*\/]
%%
{whitespace}    ;    // eat up whitespace
"program"       return TOK_PROGRAM;
"var"           return TOK_VAR;
"array"         return TOK_ARRAY;
"of"            return TOK_OF;
"integer"       {yylval = VarTypes::VT_INT; return TOK_INTEGER;}
"real"          {yylval = VarTypes::VT_REAL; return TOK_REAL;}
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


"write"          {yylval=TOK_WRITE; return TOK_WRITE;}
"read"           {yylval=TOK_READ; return TOK_READ;}

{sc_mulops}     {yylval=yytext[0]; return yylval;}
"and"           {yylval=TOK_AND; return TOK_AND;}
"div"           {yylval=TOK_DIV; return TOK_DIV;}
"mod"           {yylval=TOK_MOD; return TOK_MOD;}

"<="            {yylval=TOK_LE; return TOK_LE;}
">="            {yylval=TOK_GE; return TOK_GE;}
"<>"            {yylval=TOK_NEQ; return TOK_NEQ;}
{sc_relops}     {yylval=yytext[0]; return yylval;}
{sc_sign}       {yylval=yytext[0]; return yylval;}
"or"            {yylval=TOK_OR; return TOK_OR;}

{id}            {
                    std::string parsedText{yytext};
                    int idPosition = SymbolTable::getDefault()->insertOrGetSymbolIndex(parsedText);
                    yylval = idPosition;
                    return TOK_ID;
                }
{integer}       {
                    std::string parsedText{yytext};
                    int idPosition = SymbolTable::getDefault()->insertOrGetNumericalConstant(parsedText);
                    SymbolTable::getDefault()->at(idPosition)->setVarType(VarTypes::VT_INT);
                    yylval = idPosition;
                    return TOK_NUM;
                }
{real}          {
                    std::string parsedText{yytext};
                    int idPosition = SymbolTable::getDefault()->insertOrGetNumericalConstant(parsedText);
                    SymbolTable::getDefault()->at(idPosition)->setVarType(VarTypes::VT_REAL);
                    yylval = idPosition;
                    return TOK_NUM;
                }
\n              {} // yylineno
.               return yytext[0];

%%

