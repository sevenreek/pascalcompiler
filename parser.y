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
    size_t convertToType(size_t stIndex, VarTypes vt, SymbolTable* st=nullptr, Emitter * e=nullptr);
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
        ID
    |   identifier_list ',' ID
    ;

typed_identifier_list:
    ID typed_identifier_list_right {
            SymbolTable *st = SymbolTable::getDefault();
            st->contextualizeSymbol($1, static_cast<VarTypes>($2));
            $$ = $2;
        }
    ;

typed_identifier_list_right:
        ',' ID typed_identifier_list_right {
            SymbolTable *st = SymbolTable::getDefault();
            st->contextualizeSymbol($2, static_cast<VarTypes>($3));
            $$ = $3;
        }
    |   ':' type { $$ = $2; }
    ;

declarations:
        declarations VAR typed_identifier_list ';' {
            SymbolTable::getDefault()->placeContextInMemory();
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
        INTEGER {$$ = $1;}
    |   REAL    {$$ = $1;}
    ;

subprogram_declarations:
    subprogram_declarations subprogram_declaration ';'
    | %empty
    ;

subprogram_declaration:
        subprogram_head declarations compound_statement {
            SymbolTable *st = SymbolTable::getDefault();
            st->exitLocalContext();
            Emitter::getDefault()->exitTempOutput(st->getLocalStackSize());
        }
    ;

subprogram_head:
        FUNCTION ID  {
            SymbolTable *st = SymbolTable::getDefault();
            Emitter *e = Emitter::getDefault();
            Symbol * func = st->at($2);
            func->setFuncType(FunctionTypes::FP_FUNC);
            std::string funcLabel = func->getAttribute();
            e->generateLabel(funcLabel);
            st->enterLocalContext($2);
            e->enterTempOutput();
        } arguments ':' standard_type ';' {
            SymbolTable *st = SymbolTable::getDefault();
            Symbol * func = st->at($2);
            func->setVarType(static_cast<VarTypes>($6));
        }
    |   PROCEDURE ID  {
            SymbolTable *st = SymbolTable::getDefault();
            Emitter *e = Emitter::getDefault();
            Symbol * proc = st->at($2);
            proc->setFuncType(FunctionTypes::FP_PROC);
            std::string procLabel = proc->getAttribute();

            e->generateLabel(procLabel);
            st->enterLocalContext($2);
            e->enterTempOutput();
        } arguments ';'
    ;

arguments:
    '(' parameter_list ')' {
            SymbolTable *st = SymbolTable::getDefault();
            $$ = st->placeContextAsArguments($-2);
        }
    | %empty
    ;

parameter_list:
        typed_identifier_list  {
            $$ = $-2;
        }
    |   parameter_list ';' typed_identifier_list  {
            $$ = $-2;
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
            if(var->getFuncType()==FunctionTypes::FP_FUNC && st->getActiveFunction() != varIndex) {
                throw std::runtime_error(
                    fmt::format("Cannot assign to function {} outside of its scope.", 
                        var->getDescriptor()
                    )
                );
            }
            else if(var->getFuncType()==FunctionTypes::FP_PROC) {
                throw std::runtime_error(
                    fmt::format("Cannot assign to procedure {}.", 
                        var->getDescriptor()
                    )
                );
            }
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
        ID  {
            SymbolTable *st = SymbolTable::getDefault();
            Emitter *e = Emitter::getDefault();
            switch(st->at($1)->getFuncType()) {
                case FunctionTypes::FP_NONE:
                    throw std::runtime_error(fmt::format("{} is not a function or procedure.", st->at($1)->getDescriptor()));
                break;
                case FunctionTypes::FP_FUNC:
                    fmt::print("Ignoring return value of function {}.", st->at($1)->getDescriptor());
                case FunctionTypes::FP_PROC:
                    e->generateTwoCodeInt("call", st->at($1)->getAttribute());
                break;
            }   
        }
    |   ID {
            SymbolTable *st = SymbolTable::getDefault();
            st->pushToCallStack($1);
        } '(' expression_list ')' {
            SymbolTable *st = SymbolTable::getDefault();
            Emitter *e = Emitter::getDefault();
            Symbol * func = st->at($1);
            switch(func->getFuncType()) {
                case FunctionTypes::FP_NONE:
                    throw std::runtime_error(fmt::format("{} is not a function or procedure.", func->getDescriptor()));
                break;
                case FunctionTypes::FP_FUNC:
                    fmt::print("Ignoring return value of function {}.", func->getDescriptor());
                case FunctionTypes::FP_PROC:
                    e->generateTwoCodeInt("call", func->getAttribute());
                    e->generateTwoCodeInt("incsp", fmt::format("{}", $4*4));
                break;
            }
            st->popFromCallStack();
        }
    ;

expression_list:
        expression {
            Emitter *e = Emitter::getDefault();
            SymbolTable *st = SymbolTable::getDefault();
            e->pushSymbolToStack($1);
            $$ = 1;
            fmt::print("Argument {} at {}\n", st->at($1)->getDescriptor(), 0);
        }
    |     expression_list ',' expression {
            Emitter *e = Emitter::getDefault();
            SymbolTable *st = SymbolTable::getDefault();
            e->pushSymbolToStack($3);
            $$ = $1 + 1;
            fmt::print("Argument {} at {}\n", st->at($3)->getDescriptor(), $1);
        }
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
                default:
                    throw std::runtime_error(fmt::format("Unknown expression operator {}.", $2));
                break;
            }
            $$ = opResult;
        }
    ;

exprop:
        sign {$$ = $1;}
    |   OR   {$$ = TOK_OR;}
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
                case TOK_AND:
                    e->generateCode("and", termIndex, factorIndex, opResult, tempDescriptor);
                break;
                default:
                    throw std::runtime_error(fmt::format("Unknown muloperator {}.", $2));
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
    |   AND  {$$ = TOK_AND;}
    ;   

factor:
        variable {$$ = $1;}
    |   ID '(' expression_list ')' {
            SymbolTable *st = SymbolTable::getDefault();
            Emitter *e = Emitter::getDefault();
            Symbol * func = st->at($1);
            if(st->at($1)->getFuncType() != FunctionTypes::FP_FUNC) {
                throw std::runtime_error(fmt::format("{} is not a function.", st->at($1)->getDescriptor()));
            }
            if(static_cast<long>(func->getArgCount()) != $3) {
                throw std::runtime_error(
                    fmt::format(
                        "Excepted {} arguments in function call to {}, got {}.", 
                        func->getArgCount(), func->getDescriptor(), $3
                    )   
                );
            }
            size_t returnValue = st->getNewTemporaryVariable(func->getVarType(), fmt::format("{}()", func->getDescriptor()));
            e->pushSymbolToStack(returnValue);
            e->generateTwoCodeInt("call", st->at($1)->getAttribute());
            e->generateTwoCodeInt("incsp", fmt::format("{}", $3*4+4)); // add 4 for the return value
            $$ = returnValue;
        }
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

size_t convertToType(size_t stIndex, VarTypes target, SymbolTable* st, Emitter * e)
{
    if(!e) e = Emitter::getDefault();
    if(!st) st = SymbolTable::getDefault();
    Symbol * toConvert = st->at(stIndex);
    size_t convertedIndex = stIndex;
    VarTypes source = toConvert->getVarType();
    std::string targetVarTypeString = varTypeEnumToString(target);
    std::string comment = fmt::format("{}({})", targetVarTypeString, toConvert->getDescriptor());
    if(source != VarTypes::VT_INT && source != VarTypes::VT_REAL) {
        throw std::runtime_error(fmt::format("Tried to convert errortyped {}.", toConvert->getAttribute()));
    } 
    else if (source == VarTypes::VT_INT && target == VarTypes::VT_REAL) { // int to real
        convertedIndex = st->getNewTemporaryVariable(VarTypes::VT_REAL, comment);
        e->generateCode("inttoreal", stIndex, convertedIndex, comment);
    } 
    else if (source == VarTypes::VT_REAL && target == VarTypes::VT_INT) { // real to int
        convertedIndex = st->getNewTemporaryVariable(VarTypes::VT_INT, comment);
        e->generateCode("realtoint", stIndex, convertedIndex, comment);
    } 
    else if (source == target) { // no convert
        // all good
    }
    return convertedIndex;
}
size_t convertToReal(size_t stIndex, SymbolTable* st, Emitter * e)
{
    return convertToType(stIndex, VarTypes::VT_REAL, st, e);
}
size_t convertToInt(size_t stIndex, SymbolTable* st, Emitter * e)
{
    return convertToType(stIndex, VarTypes::VT_INT, st, e);
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
