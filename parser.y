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
    void yyerror(std::string s);
    int yylex(void);
    std::string operatorTokenToString(address_t token);
    bool isResultReal(Symbol * s1, Symbol *s2);
    size_t convertToReal(size_t stIndex, SymbolTable* st=nullptr, Emitter * e=nullptr);
    size_t convertToInt(size_t stIndex, SymbolTable* st=nullptr, Emitter * e=nullptr);
    VarTypes attributeToVarType(size_t attr);
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
%token  WRITE

%%
program:
    PROGRAM ID '(' identifier_list ')' ';'
    { Emitter::getDefault()->initialJump(); }
    declarations
    subprogram_declarations
    { Emitter::getDefault()->beginProgram(); }
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
            SymbolTable::getDefault()->setMemoryIdentifierList(attributeToVarType($5));
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
        subprogram_head declarations compound_statement {
            SymbolTable *st = SymbolTable::getDefault();
            st->exitLocalContext();
            Emitter::getDefault()->exitTempOutput();
        }
    ;

subprogram_head:
        FUNCTION ID arguments ':' standard_type ';'
    |   PROCEDURE ID  {
            SymbolTable *st = SymbolTable::getDefault();
            Emitter *e = Emitter::getDefault();
            std::string procLabel = st->at($2)->getAttribute();
            e->generateLabel(procLabel);
            st->enterLocalContext(false);
            e->enterTempOutput();
        } arguments ';'
    ;

arguments:
    '(' parameter_list ')'
    | %empty
    ;

parameter_list:
        identifier_list ':' type {
            SymbolTable *st = SymbolTable::getDefault();
            st->idListToArguments();
        }
    |   parameter_list ';' identifier_list ':' type {
            SymbolTable *st = SymbolTable::getDefault();
            st->idListToArguments();
        }
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
                exprIndex = convertToInt(exprIndex);
                expr = st->at(exprIndex);
            } else if(var->getVarType()==VarTypes::VT_REAL && expr->getVarType()==VarTypes::VT_INT) {
                exprIndex = convertToReal(exprIndex);
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
            e->generateCode("mov", exprIndex, varIndex, comment);
        }
    |   procedure_statement
    |   compound_statement
    |   IF expression THEN   {
            SymbolTable *st = SymbolTable::getDefault();
            Emitter *e = Emitter::getDefault();
            size_t expressionIndex = $2;
            Symbol * expression = st->at(expressionIndex);
            if(expression->getVarType()==VarTypes::VT_REAL) {
                expressionIndex = convertToInt(expressionIndex);
                expression = st->at(expressionIndex);
            }
            std::string labelElse = fmt::format("lab{}_else", st->pushNextLabelIndex());
            e->generateCodeConst("je", expressionIndex, "#0", fmt::format("#{}",labelElse), "");
        } statement ELSE  {
            SymbolTable *st = SymbolTable::getDefault();
            Emitter *e = Emitter::getDefault();
            std::string labelElse = fmt::format("lab{}_else", st->popLabelIndex());
            std::string labelAfter = fmt::format("lab{}_endif", st->pushNextLabelIndex());
            e->generateJump(labelAfter);
            e->generateLabel(labelElse);
        } statement {
            SymbolTable *st = SymbolTable::getDefault();
            Emitter *e = Emitter::getDefault();
            std::string labelAfter = fmt::format("lab{}_endif", st->popLabelIndex());
            e->generateLabel(labelAfter);
        }
    |   WHILE expression {
            SymbolTable *st = SymbolTable::getDefault();
            Emitter *e = Emitter::getDefault();
            std::string labelEndWhile = fmt::format("lab{}_endwhile", st->pushNextLabelIndex());
            std::string labelWhile = fmt::format("lab{}_while", st->pushNextLabelIndex());
            size_t expressionIndex = $2;
            Symbol * expression = st->at(expressionIndex);
            if(expression->getVarType()==VarTypes::VT_REAL) {
                expressionIndex = convertToInt(expressionIndex);
                expression = st->at(expressionIndex);
            }
            e->generateLabel(labelWhile);
            e->generateCodeConst("je", expressionIndex, "#0", fmt::format("#{}",labelEndWhile), "");
        } DO statement {
            SymbolTable *st = SymbolTable::getDefault();
            Emitter *e = Emitter::getDefault();
            std::string labelWhile = fmt::format("lab{}_while", st->popLabelIndex());
            std::string labelEndWhile = fmt::format("lab{}_endwhile", st->popLabelIndex());
            e->generateJump(labelWhile);
            e->generateLabel(labelEndWhile);

        }
    |   WRITE '(' expression ')' {
            SymbolTable *st = SymbolTable::getDefault();
            std::string comment = fmt::format("write({})", st->at($3)->getDescriptor());
            Emitter::getDefault()->generateCode("write", $3, comment); 
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
            e->generateCodeConst("sub", expressionIndex, fmt::format("#{}", arrayStart), arrayIndexTemp, comment);
            comment = fmt::format("CALC_ARRAY_OFFSET(({}-{})*{})", expression->getDescriptor(), arrayStart, varSize);
            e->generateCodeConst("mul", arrayIndexTemp, fmt::format("#{}", varSize), arrayIndexTemp, comment);
            comment = fmt::format("{}[{}]", array->getDescriptor(), expression->getDescriptor());
            e->generateCodeConst("add", arrayIndexTemp, fmt::format("#{}", array->getAddress()), arrayIndexTemp, comment);
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
    |   simple_expression relop simple_expression {
            SymbolTable *st = SymbolTable::getDefault();
            Emitter *e = Emitter::getDefault();
            size_t e1i = $1;
            size_t e2i = $3;
            Symbol * e1 = st->at(e1i);
            Symbol * e2 = st->at(e2i);
            bool isTempReal = isResultReal(e1,e2);
            if(isTempReal) {
                if(e1->getVarType()==VarTypes::VT_INT) {
                    e1i = convertToReal(e1i);
                    e1 = st->at(e1i);
                }
                else if(e2->getVarType()==VarTypes::VT_INT) {
                    e2i = convertToReal(e2i);
                    e2 = st->at(e2i);
                }
                else if(e1->getVarType()==VarTypes::VT_REAL && e2->getVarType()==VarTypes::VT_REAL) {
                    // all good 
                }
                else {   
                    throw std::runtime_error(fmt::format("Unknown type conversion in {}{}{}", e1->getDescriptor(), operatorTokenToString($2), e2->getDescriptor()));
                }
            }
            std::string tempDescriptor = fmt::format("{}{}{}", e1->getDescriptor(), operatorTokenToString($2), e2->getDescriptor());
            size_t opResultIndex = st->getNewTemporaryVariable(VarTypes::VT_INT,  tempDescriptor);
            std::string labelTrue = fmt::format("lab{}_true", st->getNextLabelIndex());
            std::string trueHash = fmt::format("#{}", labelTrue);
            std::string labelAfter = fmt::format("lab{}_end", st->getNextLabelIndex());
            switch($2) {
                case '=':
                    e->generateCodeConst("je", e1i, e2i, trueHash, "");
                break;
                case '>': 
                    e->generateCodeConst("jg", e1i, e2i, trueHash, "");
                break;
                case '<': 
                    e->generateCodeConst("jl", e1i, e2i, trueHash, "");
                break;
                case TOK_NEQ: 
                    e->generateCodeConst("jne", e1i, e2i, trueHash,"");
                break;
                case TOK_GE: 
                    e->generateCodeConst("jge", e1i, e2i, trueHash,"");
                break;
                case TOK_LE: 
                    e->generateCodeConst("jle", e1i, e2i, trueHash,"");
                break;
            }
            e->generateCodeConst("mov", "#0", opResultIndex, "");
            e->generateJump(labelAfter);
            e->generateLabel(labelTrue);
            e->generateCodeConst("mov", "#1", opResultIndex, "");
            e->generateLabel(labelAfter);
            $$ = opResultIndex;

        }
    ;

relop:
        '>'     {$$ = '>';}
    |   '<'     {$$ = '<';}
    |   LE      {$$ = TOK_LE;}
    |   GE      {$$ = TOK_GE;}
    |   NEQ     {$$ = TOK_NEQ;}
    |   '='     {$$ = '=';}
    ;

simple_expression:
        term {$$ = $1;}
    |   sign term {
            if($1=='-') {
                SymbolTable *st = SymbolTable::getDefault();
                Emitter *e = Emitter::getDefault();
                Symbol* original = st->at($2);
                size_t negResult = st->getNewTemporaryVariable(original->getVarType());
                std::string comment = fmt::format("-{}", st->at($2)->getDescriptor());
                e->subFromZero($2, negResult);
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
                    expressionIndex = convertToReal(expressionIndex);
                    exp = st->at(expressionIndex);
                }
                else if(trm->getVarType()==VarTypes::VT_INT) {
                    termIndex = convertToReal(termIndex);
                    trm = st->at(termIndex);
                }
                else if(exp->getVarType()==VarTypes::VT_REAL && trm->getVarType()==VarTypes::VT_REAL) {
                    // all good 
                }
                else {   
                    throw std::runtime_error(fmt::format("Unknown type conversion in {}{}{}", exp->getDescriptor(), operatorTokenToString($2), trm->getDescriptor()));
                }
            }
            std::string tempDescriptor = fmt::format("{}{}{}", exp->getDescriptor(), operatorTokenToString($2), trm->getDescriptor());
            size_t opResult = st->getNewTemporaryVariable(isTempReal ? VarTypes::VT_REAL : VarTypes::VT_INT,  tempDescriptor);
            switch($2) {
                case '-':
                    e->generateCode("sub", expressionIndex, termIndex, opResult, tempDescriptor);
                break;
                case '+':
                    e->generateCode("add", expressionIndex, termIndex, opResult, tempDescriptor);
                break;
                case TOK_OR:
                    e->generateCode("or",  expressionIndex, termIndex, opResult, tempDescriptor);
                break;
                case TOK_AND:
                    e->generateCode("and", expressionIndex, termIndex, opResult, tempDescriptor);
                break;
                default:
                    throw std::runtime_error(fmt::format("Unknown operation {}.", $2));
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
                    termIndex = convertToReal(termIndex);
                    trm = st->at(termIndex);
                }
                else if(fac->getVarType()==VarTypes::VT_INT) {
                    factorIndex = convertToReal(factorIndex);
                    fac = st->at(factorIndex);
                }
            }
            std::string tempDescriptor = fmt::format("{}{}{}", trm->getDescriptor(), operatorTokenToString($2), fac->getDescriptor());
            size_t opResult = st->getNewTemporaryVariable(isTempReal?VarTypes::VT_REAL:VarTypes::VT_INT,  tempDescriptor);
            switch($2) {
                case '*':
                    e->generateCode("mul", termIndex, factorIndex, opResult, tempDescriptor);
                break;
                case '/': case TOK_DIV:
                    e->generateCode("div", termIndex, factorIndex, opResult, tempDescriptor);
                break;
                case TOK_MOD: case '%':
                    e->generateCode("mod", termIndex, factorIndex, opResult, tempDescriptor);
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
    |   NOT factor {
            SymbolTable *st = SymbolTable::getDefault();
            Emitter *e = Emitter::getDefault();
            size_t factorIndex = $2;
            Symbol * factor = st->at(factorIndex);
            if(factor->getVarType()==VarTypes::VT_REAL) {
                factorIndex = convertToInt(factorIndex);
                factor = st->at(factorIndex);
            }
            size_t opResultIndex = st->getNewTemporaryVariable(VarTypes::VT_INT,  fmt::format("!{}", factor->getDescriptor()));
            std::string labelTrue = fmt::format("lab{}_totrue", st->getNextLabelIndex());
            std::string trueHash = fmt::format("#{}", labelTrue);
            std::string labelAfter = fmt::format("lab{}_end", st->getNextLabelIndex());
            e->generateCodeConst("je", factorIndex, "#0", trueHash, "");
            e->generateCodeConst("mov", "#0", opResultIndex, "");
            e->generateRaw(fmt::format("\tjump.i #{}", labelAfter));
            e->generateRaw(fmt::format("{}:", labelTrue));
            e->generateCodeConst("mov", "#1", opResultIndex, "");
            e->generateRaw(fmt::format("{}:", labelAfter));
            $$ = opResultIndex;
        }
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
        case TOK_OR :   return " or ";
        case TOK_AND:   return " and ";
        case TOK_LE :   return "<=";
        case TOK_GE :   return ">=";
        case '<' :   return "<";
        case '>' :   return ">";
        case TOK_NEQ:   return "!=";
        case TOK_DIV:   return " div ";
        case TOK_MOD:   return " mod ";
        case '=' :      return "==";
        case '%':       return "%";
        case '*':       return "*";
        case '/':       return "/";
        case '+':       return "+";
        case '-':       return "-";
        default: return "<UNNKOWNOPSTRING>";
    }
}
size_t convertToReal(size_t stIndex, SymbolTable* st, Emitter * e)
{
    if(!e) e = Emitter::getDefault();
    if(!st) st = SymbolTable::getDefault();
    Symbol * toConvert = st->at(stIndex);
    std::string comment = fmt::format("real({})", toConvert->getDescriptor());
    if(toConvert->getVarType() != VarTypes::VT_INT) throw std::runtime_error(fmt::format("Tried to convert nonint {} to real.", toConvert->getAttribute()));
    size_t convertedIndex = st->getNewTemporaryVariable(VarTypes::VT_REAL, comment);
    e->generateCode("inttoreal", stIndex, convertedIndex, comment);
    return convertedIndex;
}
size_t convertToInt(size_t stIndex, SymbolTable* st, Emitter * e)
{
    if(!e) e = Emitter::getDefault();
    if(!st) st = SymbolTable::getDefault();
    Symbol * toConvert = st->at(stIndex);
    std::string comment = fmt::format("int({})", toConvert->getDescriptor());
    if(toConvert->getVarType() != VarTypes::VT_REAL) throw std::runtime_error(fmt::format("Tried to convert nonreal {} to int.", toConvert->getAttribute()));
    size_t convertedIndex = st->getNewTemporaryVariable(VarTypes::VT_INT, comment);
    e->generateCode("realtoint", stIndex, convertedIndex, comment);
    return convertedIndex;
}
VarTypes attributeToVarType(size_t attr)
{
    VarTypes t;
    switch(attr)
    {
        case TOK_INTEGER:
            t = VarTypes::VT_INT;
        break;
        case TOK_REAL:
            t = VarTypes::VT_REAL;
        break;
        default:
            throw std::runtime_error(fmt::format("Bad type"));
        break;
    }
    return t;
}