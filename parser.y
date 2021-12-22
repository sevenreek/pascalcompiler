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

%token	PROGRAM
%token	ID
%token  VAR
%token  ARRAY
%token  OF
%token  NUM
%token  INTEGER
%token  REAL
%token  FUNCTION
%token  PROCEDURE
%token  BEGIN
%token  END
%token  ASSIGNOP
%token  IF
%token  THEN
%token  ELSE
%token  WHILE
%token  DO
%token  NOT
%token  OR
%token  AND
%token  LE
%token  GE
%token  NEQ
%token  DIV
%token  MOD
%token  EQ

%%
program:
    PROGRAM ID '(' identifier_list ')' ';'
    declarations
    subprogram_declarations
    compound_statement
    '.'
    ;

identifier_list:
    ID
    | identifier_list ',' ID
    ;

declarations:
    declarations VAR identifier_list ':' type ';'
    | %empty
    ;

type:
    standard_type
    | ARRAY '[' NUM '.' '.' NUM ']' OF standard_type
    ;

standard_type:
    INTEGER
    | REAL
    ;

subprogram_declarations:
    subprogram_declarations subprogram_declaration ';'
    | %empty
    ;

subprogram_declaration:
    subprogram_head declarations compound_statement
    ;

subprogram_head:
    FUNCTION ID arguments ':' standard_type ';'
    | PROCEDURE ID arguments ';'
    ;

arguments:
    '(' parameter_list ')'
    | %empty
    ;

parameter_list:
    identifier_list ':' type
    | parameter_list ';' identifier_list ':' type
    ;

compound_statement:
    BEGIN
    optional_statements
    END
    ;

optional_statements:
    statement_list
    | %empty
    ;

statement_list:
    statement
    | statement_list ';' statement
    ;

statement:
    variable ASSIGNOP expression
    | procedure_statement
    | compound_statement
    | IF expression THEN statement ELSE statement
    | WHILE expression DO statement
    ;

variable:
    ID
    | ID '[' expression ']'
    ;

procedure_statement:
    ID
    | ID '(' expression_list ')'
    ;

expression_list:
    expression
    | expression_list ',' expression
    ;

expression:
    simple_expression
    | simple_expression relop simple_expression 
    ;

relop:
    '>'
    | '<'
    | LE
    | GE
    | NEQ
    | EQ
    ;

simple_expression:
    term
    | sign term
    | simple_expression sign term
    | simple_expression OR term
    | simple_expression AND term
    ;

sign:
    '+'
    | '-'
    ;

term:
    factor
    | term mulop factor
    ;

mulop:
    '*'
    | '/'
    | DIV
    | MOD
    ;

factor:
    variable
    | ID '(' expression_list ')'
    | NUM
    | '(' expression ')'
    | NOT factor
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

