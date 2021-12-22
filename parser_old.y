
%code requires {
    #include "symtable.h"
}

%code provides {
    void yyerror(char *s);
    int yylex(void);
}

%define api.header.include {"parser.h"}
%define api.value.type {int}
%locations
%start	input 

%token	NUM
%token  ID
%token  DIV
%token  MOD
%left	  '+' '-'
%left	  '*' '/' DIV MOD

%%



input: %empty
      | expr ';' input { return 0; }
		  ;

expr:	expr '+' expr	{ printf("+\n"); }
		| expr '-' expr { printf("-\n"); }
    | expr '*' expr { printf("*\n"); }
    | expr '/' expr { printf("/\n"); }
    | expr DIV expr { printf("DIV\n"); }
    | expr MOD expr { printf("MOD\n"); }
    | '(' expr ')'  {  }
    | NUM           { printf("%d\n", $1); }
    | ID            { printf("%s\n", symtable[$1].lexptr); }
		;

%%
#include "lexer.h"

void yyerror(char *s)
{
  fprintf (stderr, "line%d:%s\n", yylineno, s);
  exit (1);
}

int main()
{
  yyparse();
  yylex_destroy();
  exit(0);
}