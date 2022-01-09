%require "3.2"

%code requires {
    #include "symboltable.hpp"
    #include "emitter.hpp"
    #include <exception>
    #include <string>
    #include <tuple>
    #include <fmt/format.h>
}

%code provides {
    const static size_t NO_SYMBOL = -1;
    void yyerror(char *s);
    int yylex(void);
    std::string operatorTokenToString(address_t token);
    bool isResultReal(Symbol * s1, Symbol *s2);
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
        standard_type {
            SymbolTable::getDefault()->setCurrentArraySize({0,0});
            $$ = $1;
        }
    |   ARRAY '[' NUM '.' '.' NUM ']' OF standard_type {
            SymbolTable *st = SymbolTable::getDefault();
            Symbol* startSym = st->at($3);
            Symbol* endSym = st->at($6);
            if(startSym->getVarType() != VarTypes::VT_INT || endSym->getVarType() != VarTypes::VT_INT) {
                throw std::runtime_error(fmt::format("Expected integer type in array type bounds."));
            }
            size_t start = std::stoi(startSym->getAttribute());
            size_t end = std::stoi(endSym->getAttribute());
            if(start > end) {
                throw std::runtime_error(fmt::format("Expected increasing array bounds."));
            }
            st->setCurrentArraySize({start, end});
            $$ = $9;
        }
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
            SymbolTable *st = SymbolTable::getDefault();
            Emitter *e = Emitter::getDefault();
            size_t varIndex = $1;
            size_t exprIndex = $3;
            Symbol* var = st->at(varIndex);
            Symbol* expr = st->at(exprIndex);
            if(var->getVarType()==VarTypes::VT_INT && expr->getVarType()==VarTypes::VT_REAL) {
                std::string conversionComment = fmt::format("int({})", expr->getDescriptor());
                size_t convertedIndex = st->getNewTemporaryVariable(VarTypes::VT_INT, conversionComment);
                e->generateCode("realtoint", exprIndex, false, convertedIndex, false, conversionComment);
                exprIndex = convertedIndex;
                expr = st->at(exprIndex);
            } else if(var->getVarType()==VarTypes::VT_REAL && expr->getVarType()==VarTypes::VT_INT) {
                std::string conversionComment = fmt::format("real({})", expr->getDescriptor());
                size_t convertedIndex = st->getNewTemporaryVariable(VarTypes::VT_REAL, conversionComment);
                e->generateCode("inttoreal", exprIndex, false, convertedIndex, false, conversionComment);
                exprIndex = convertedIndex;
                expr = st->at(exprIndex);
            }
            else if (var->getVarType()==expr->getVarType()) {
                // no conversion needed
            }
            else {
                throw std::runtime_error(
                    fmt::format("Types not set properly in assignment {}:={}", 
                        varTypeEnumToString(var->getVarType()),  varTypeEnumToString(expr->getVarType())
                    )
                );
            }
            std::string comment = fmt::format("{}:={}", st->at(varIndex)->getDescriptor(), st->at(exprIndex)->getDescriptor());
            e->generateCode("mov", exprIndex, false, varIndex, false, comment);
        }
    |   procedure_statement
    |   compound_statement
    |   IF expression THEN statement ELSE statement
    |   WHILE expression DO statement
    |   WRITE '(' expression ')' {
            SymbolTable *st = SymbolTable::getDefault();
            std::string comment = fmt::format("write({})", st->at($3)->getDescriptor());
            Emitter::getDefault()->generateCode("write", $3, st->at($3)->getIsReference(), comment); 
        }
    ;

variable:
        ID {$$ = $1;}
    |   ID '[' expression ']' {
            SymbolTable *st = SymbolTable::getDefault();
            Emitter *e = Emitter::getDefault();
            size_t expressionIndex = $3;
            size_t arrayIndex = $1;
            Symbol* expression = st->at(expressionIndex);
            Symbol* array = st->at(arrayIndex);
            if(!array->isArray()) {
                throw std::runtime_error(fmt::format("{} is not an array.", array->getDescriptor()));
            }
            if(expression->getVarType() != VarTypes::VT_INT) { // convert to int maybe?
                throw std::runtime_error(fmt::format("Array index must be integer."));
            }
            std::string comment = fmt::format("{}[{}]", array->getDescriptor(), expression->getDescriptor());
            size_t arrayIndexTemp = st->getNewTemporaryVariable(VarTypes::VT_INT, comment); 
            size_t arrayStart = std::get<0>(array->getArrayBounds());
            int varSize = varTypeToSize(array->getVarType());
            comment = fmt::format("CALC_ARRAY_OFFSET({}-{})", expression->getDescriptor(), arrayStart);
            e->generateCodeConst("sub.i", expressionIndex, false, fmt::format("#{}", arrayStart), arrayIndexTemp, false, comment);
            comment = fmt::format("CALC_ARRAY_OFFSET(({}-{})*{})", expression->getDescriptor(), arrayStart, varSize);
            e->generateCodeConst("mul.i", arrayIndexTemp, false, fmt::format("#{}", varSize), arrayIndexTemp, false, comment);
            comment = fmt::format("{}[{}]", array->getDescriptor(), expression->getDescriptor());
            e->generateCodeConst("add.i", arrayIndexTemp, false, fmt::format("#{}", array->getAddress()), arrayIndexTemp, false, comment);
            st->at(arrayIndexTemp)->setIsReference(true);
            st->at(arrayIndexTemp)->setVarType(array->getVarType()); // change to double if needed
            $$ = arrayIndexTemp;
        }
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
                Symbol* original = st->at($2);
                size_t negResult = st->getNewTemporaryVariable(original->getVarType());
                size_t zeroConst = st->insertOrGetNumericalConstant("0");
                std::string comment = fmt::format("-{}", st->at($2)->getDescriptor());
                e->generateCode("sub", zeroConst, false, $2, false, negResult, false, comment);
                $$ = negResult;
            }
            else { // '+'
                $$ = $2;
            }
        }
    |   simple_expression exprop term {
            SymbolTable *st = SymbolTable::getDefault();
            Emitter *e = Emitter::getDefault();
            Symbol* exp = st->at($1);
            Symbol* trm = st->at($3);
            size_t expressionIndex = $1;
            size_t termIndex = $3;
            bool isTempReal = isResultReal(exp,trm);
            if(isTempReal) {
                if(exp->getVarType()==VarTypes::VT_INT) {
                    size_t convertedIndex = st->getNewTemporaryVariable(VarTypes::VT_REAL, fmt::format("real({})", exp->getDescriptor()));
                    e->generateCode("inttoreal", expressionIndex, false, convertedIndex, false);
                    expressionIndex = convertedIndex;
                    exp = st->at(expressionIndex);
                }
                else if(trm->getVarType()==VarTypes::VT_INT) {
                    size_t convertedIndex = st->getNewTemporaryVariable(VarTypes::VT_REAL, fmt::format("real({})", trm->getDescriptor()));
                    e->generateCode("inttoreal", termIndex, false, convertedIndex, false);
                    termIndex = convertedIndex;
                    trm = st->at(termIndex);
                }
            }
            std::string tempDescriptor = fmt::format("{}{}{}", exp->getDescriptor(), operatorTokenToString($2), trm->getDescriptor());
            size_t opResult = st->getNewTemporaryVariable(isTempReal ? VarTypes::VT_REAL : VarTypes::VT_INT,  tempDescriptor);
            switch($2) {
                case '-':
                    e->generateCode("sub", expressionIndex, false, termIndex, false, opResult, false, tempDescriptor);
                break;
                case '+':
                    e->generateCode("add", expressionIndex, false, termIndex, false, opResult, false, tempDescriptor);
                break;
                case TOK_OR:
                    e->generateCode("or",  expressionIndex, false, termIndex, false, opResult, false, tempDescriptor);
                break;
                case TOK_AND:
                    e->generateCode("and", expressionIndex, false, termIndex, false, opResult, false, tempDescriptor);
                break;
                default:
                    yyerror("Invalid expression operation");
                break;
            }
            $$ = opResult;
        }
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
            size_t termIndex = $1;
            size_t factorIndex = $3;
            Symbol* trm = st->at(termIndex);
            Symbol* fac = st->at(factorIndex);
            bool isTempReal = isResultReal(trm,fac);
            if(isTempReal) {
                if(trm->getVarType()==VarTypes::VT_INT) {
                    size_t convertedIndex = st->getNewTemporaryVariable(VarTypes::VT_REAL, fmt::format("real({})", trm->getDescriptor()));
                    e->generateCode("inttoreal", termIndex, false, convertedIndex, false);
                    termIndex = convertedIndex;
                    trm = st->at(termIndex);
                }
                else if(fac->getVarType()==VarTypes::VT_INT) {
                    size_t convertedIndex = st->getNewTemporaryVariable(VarTypes::VT_REAL, fmt::format("real({})", fac->getDescriptor()));
                    e->generateCode("inttoreal", factorIndex, false, convertedIndex, false);
                    factorIndex = convertedIndex;
                    fac = st->at(factorIndex);
                }
            }
            std::string tempDescriptor = fmt::format("{}{}{}", trm->getDescriptor(), operatorTokenToString($2), fac->getDescriptor());
            size_t opResult = st->getNewTemporaryVariable(isTempReal?VarTypes::VT_REAL:VarTypes::VT_INT,  tempDescriptor);
            switch($2) {
                case '*':
                    e->generateCode("mul", termIndex, false, factorIndex, false, opResult, false, tempDescriptor);
                break;
                case '/': case TOK_DIV:
                    e->generateCode("div", termIndex, false, factorIndex, false, opResult, false, tempDescriptor);
                break;
                case TOK_MOD: case '%':
                    e->generateCode("mod", termIndex, false, factorIndex, false, opResult, false, tempDescriptor);
                break;
            }
            $$ = opResult;
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
bool isResultReal(Symbol * s1, Symbol *s2)
{
    return (s1->getVarType() | s2->getVarType()) & VarTypes::VT_REAL;
}
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