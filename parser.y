%require "3.2"

%code requires {
    #include "symboltable.hpp"
    #include "emitter.hpp"
    #include <exception>
    #include <string>
    #include <fmt/format.h>
}

%code provides {
    const static size_t NO_SYMBOL = -1;
    void yyerror(char *s);
    int yylex(void);
    std::string operatorTokenToString(address_t token);
}
%define api.token.prefix {TOK_}
%define api.value.type {address_t}
%locations
%start	program 

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
%token  WRITE

%%
program:
    PROGRAM ID '(' identifier_list ')' ';'
    { Emitter::getDefault()->beginProgram(); }
    declarations
    subprogram_declarations
    compound_statement
    '.'
    { Emitter::getDefault()->endProgram(); }
    ; 

identifier_list:
    ID {SymbolTable::getDefault()->addToIdentifierListStack($1);}
    | identifier_list ',' ID {SymbolTable::getDefault()->addToIdentifierListStack($3);}
    ;

declarations:
        declarations VAR identifier_list ':' type ';' {
            VarTypes t;
            switch($5)
            {
                case TOK_INTEGER:
                    t = VarTypes::VT_INT;
                break;
                case TOK_REAL:
                    t = VarTypes::VT_REAL;
                break;
                default:
                    yyerror("Bad type");
                break;
            }
            SymbolTable::getDefault()->setMemoryIdentifierList(t);
        }
    |   %empty
    ;

type:
    standard_type {$$ = $1;}
    | ARRAY '[' NUM '.' '.' NUM ']' OF standard_type
    ;

standard_type:
        INTEGER {$$ = TOK_INTEGER;}
    |   REAL    {$$ = TOK_REAL;}
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
        variable ASSIGNOP expression {
            Emitter::getDefault()->generateCode("mov", $3, false, $1, false);
        }
    |   procedure_statement
    |   compound_statement
    |   IF expression THEN statement ELSE statement
    |   WHILE expression DO statement
    |   WRITE '(' expression ')' {
            Emitter::getDefault()->generateCode("write", $3, false); 
        }
    ;

variable:
        ID {$$ = $1;}
    |   ID '[' expression ']'
    ;

procedure_statement:
        ID
    |   ID '(' expression_list ')'
    ;

expression_list:
        expression {$$ = $1;}
    |   expression_list ',' expression
    ;

expression:
        simple_expression {$$ = $1;}
    |   simple_expression relop simple_expression 
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
        term {$$ = $1;}
    |   sign term {
            if($1=='-') {
                SymbolTable *st = SymbolTable::getDefault();
                Emitter *e = Emitter::getDefault();
                Symbol& original = st->at($2);
                size_t negResult = st->getNewTemporaryVariable(original.getVarType());
                size_t zeroConst = st->insertOrGetNumericalConstant("0");
                e->generateCode("sub", zeroConst, false, $2, false, negResult, false);
                $$ = negResult;
            }
            else { // '+'
                $$ = $2;
            }
        }
    |   simple_expression exprop term {
            SymbolTable *st = SymbolTable::getDefault();
            Emitter *e = Emitter::getDefault();
            Symbol& exp = st->at($1);
            Symbol& trm = st->at($3);
            bool isTempReal = (exp.getVarType() | trm.getVarType()) & VarTypes::VT_REAL; // TODO: CONVERT IF NEEDED
            size_t opResult = st->getNewTemporaryVariable(isTempReal ? VarTypes::VT_REAL : VarTypes::VT_INT, fmt::format("{}{}{}", exp.getDescriptor(), operatorTokenToString($2), trm.getDescriptor()) );
            switch($2) {
                case '-':
                    e->generateCode("sub", $1, false, $3, false, opResult, false);
                break;
                case '+':
                    e->generateCode("add", $1, false, $3, false, opResult, false);
                break;
                case TOK_OR:
                    e->generateCode("or", $1, false, $3, false, opResult, false);
                break;
                case TOK_AND:
                    e->generateCode("and", $1, false, $3, false, opResult, false);
                break;
                default:
                    yyerror("Invalid expression operation");
                break;
            }
            $$ = opResult;
        }
    |   simple_expression OR term
    |   simple_expression AND term
    ;

exprop:
        sign {$$ = $1;}
    |   OR   {$$ = TOK_OR;}
    |   AND  {$$ = TOK_AND;}
    ;

sign:
        '+' {$$ = '+';}
    |   '-' {$$ = '-';}
    ;   

term:
        factor {$$ = $1;}
    |   term mulop factor {
            SymbolTable *st = SymbolTable::getDefault();
            Emitter *e = Emitter::getDefault();
            Symbol& trm = st->at($1);
            Symbol& fac = st->at($3);
            bool isTempReal = trm.getVarType() | fac.getVarType();
            bool mustConvert = !(trm.getVarType() & fac.getVarType()) & isTempReal;
            if(mustConvert) {
                throw std::runtime_error{"inttoreal is not implemented yet."};
            }
            size_t newTemp = st->getNewTemporaryVariable(isTempReal?VarTypes::VT_REAL:VarTypes::VT_INT, fmt::format("{}{}{}", trm.getDescriptor(), operatorTokenToString($2), fac.getDescriptor()) );
            switch($2) {
                case '*':
                    e->generateCode("mul", $1, false, $3, false, newTemp, false);
                break;
                case '/': case TOK_DIV:
                    e->generateCode("div", $1, false, $3, false, newTemp, false);
                break;
                case TOK_MOD:
                    e->generateCode("mod", $1, false, $3, false, newTemp, false);
                break;
            }
        }
    
    ;

mulop:
        '*' {$$ = '*';}
    |   '/' {$$ = '/';}
    |   DIV {$$ = TOK_DIV;} 
    |   MOD {$$ = TOK_MOD;}
    |   '%' {$$ = TOK_MOD;}
    ;   

factor:
        variable {$$ = $1;}
    |   ID '(' expression_list ')'
    |   NUM {$$ = $1;}
    |   '(' expression ')' {
            $$ = $2;
        }
    |   NOT factor
    ;

%%

std::string operatorTokenToString(address_t token)
{
    switch(token)
    {
        case TOK_OR :   return "or";
        case TOK_AND:   return "and";
        case TOK_LE :   return "<=";
        case TOK_GE :   return ">=";
        case TOK_NEQ:   return "<>";
        case TOK_DIV:   return "div";
        case TOK_MOD:   return "mod";
        case TOK_EQ :   return "==";
        case '%':       return "%";
        case '*':       return "*";
        case '/':       return "/";
        case '+':       return "+";
        case '-':       return "-";
        default: return "<UNNKOWNOPSTRING>";
    }
}