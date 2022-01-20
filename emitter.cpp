#include "emitter.hpp"
#include <fmt/format.h>

Emitter* Emitter::instance = nullptr;
Emitter::Emitter(std::string filename) :
    outputFile(filename, std::fstream::out | std::fstream::trunc)
{
    this->currentOutput = &this->outputFile;
}
Emitter* Emitter::getDefault()
{
    return Emitter::instance;
}

std::string Emitter::getSymbolAddress(Symbol* s)
{
    if(s->getAddress() == -1) {
        throw ParsingException(fmt::format("Address of variable {} not set.", s->getDescriptor()));
    }
    if(s->isLocal())
        return fmt::format("BP{:+}",s->getAddress());
    else 
        return fmt::format("{}", s->getAddress());
}
std::string Emitter::getSymbolString(Symbol* s)
{
    if(s->getFuncType()==FunctionTypes::FP_FUNC)
    {
        return fmt::format("*BP+8");
    }
    if(s->getSymbolType()==SymbolTypes::ST_ID)
    {
        if(!s->isInMemory()) 
        {
            throw ParsingException(fmt::format("Undeclared variable {}.", s->getDescriptor()));
        }
        if(s->getIsReference()) {
            return fmt::format("*{}", this->getSymbolAddress(s));
        }
        else {
            return fmt::format("{}", this->getSymbolAddress(s));
        }   
    }
    else if(s->getSymbolType()==SymbolTypes::ST_NUM)
    {
        return fmt::format("#{}", s->getAttribute());
    }
    return "<ERROR>";
}
std::string Emitter::getSymbolReferenceString(size_t symbolIndex)
{
    SymbolTable* st = SymbolTable::getDefault();
    Symbol *s = st->at(symbolIndex);
    if(s->getIsReference()) {
        return fmt::format("{}", this->getSymbolAddress(s));
    } 
    else if (s->getSymbolType() == SymbolTypes::ST_NUM) {
        size_t tempIndex = st->getNewTemporaryVariable(s->getVarType(), fmt::format("store({})", s->getDescriptor()));
        Symbol *temp = st->at(tempIndex);
        this->generateCode("mov", symbolIndex, tempIndex, fmt::format("{}", temp->getDescriptor()));
        return fmt::format("#{}", temp->getAddress());
    }
    else {
        return fmt::format("#{}", this->getSymbolAddress(s));
    }
    return "<ERROR>";
}
void Emitter::generateCode(std::string operation, size_t s1i,  size_t s2i, size_t s3i, std::string comment)
{
    SymbolTable* st = SymbolTable::getDefault();
    char typeChar = st->at(s1i)->getVarType()==VarTypes::VT_INT?'i':'r';
    std::string out = fmt::format(
        "{}.{} {}, {}, {};", 
        operation, 
        typeChar, 
        this->getSymbolString(st->at(s1i)),
        this->getSymbolString(st->at(s2i)),
        this->getSymbolString(st->at(s3i))
    );
    *this->currentOutput << '\t' << out << " " << comment << "\n";
    fmt::print("{}\n", comment);
}
void Emitter::generateCode(std::string operation, size_t s1i, size_t s2i, std::string comment)
{
    SymbolTable* st = SymbolTable::getDefault();
    char typeChar = st->at(s1i)->getVarType()==VarTypes::VT_INT?'i':'r';
    std::string out =  fmt::format(
        "{}.{} {}, {};", 
        operation, 
        typeChar, 
        this->getSymbolString(st->at(s1i)),
        this->getSymbolString(st->at(s2i))
    );
    *this->currentOutput << '\t' << out << " " << comment << "\n";
    fmt::print("{}\n", comment);
}
void Emitter::generateCode(std::string operation, size_t s1i, std::string comment)
{
    SymbolTable* st = SymbolTable::getDefault();
    char typeChar = st->at(s1i)->getVarType()==VarTypes::VT_INT?'i':'r';
    std::string out =  fmt::format(
        "{}.{} {};", 
        operation, 
        typeChar, 
        this->getSymbolString(st->at(s1i))
    );
    *this->currentOutput << '\t' << out << " " << comment << "\n";
    fmt::print("{}\n", comment);
}
void Emitter::generateCodeConst(std::string operation, size_t s1i, std::string constval, size_t s3i, std::string comment)
{
    SymbolTable* st = SymbolTable::getDefault();
    char typeChar = st->at(s1i)->getVarType()==VarTypes::VT_INT?'i':'r';
    std::string out = fmt::format(
        "{}.{} {}, {}, {};", 
        operation, 
        typeChar, 
        this->getSymbolString(st->at(s1i)),
        constval,
        this->getSymbolString(st->at(s3i))
    );
    *this->currentOutput << '\t' << out << " " << comment << "\n";
    fmt::print("{}\n", comment);
}
void Emitter::generateCodeConst(std::string operation, size_t s1i, size_t s2i, std::string constval, std::string comment)
{
    SymbolTable* st = SymbolTable::getDefault();
    char typeChar = st->at(s1i)->getVarType()==VarTypes::VT_INT?'i':'r';
    std::string out = fmt::format(
        "{}.{} {}, {}, {};", 
        operation, 
        typeChar, 
        this->getSymbolString(st->at(s1i)),
        this->getSymbolString(st->at(s2i)),
        constval
    );
    *this->currentOutput << '\t' << out << " " << comment << "\n";
    fmt::print("{}\n", comment);
}
void Emitter::generateCodeConst(std::string operation, std::string constval, size_t s2i, std::string comment)
{
    SymbolTable* st = SymbolTable::getDefault();
    char typeChar = st->at(s2i)->getVarType()==VarTypes::VT_INT?'i':'r';
    std::string out = fmt::format(
        "{}.{} {}, {};", 
        operation, 
        typeChar, 
        constval,
        this->getSymbolString(st->at(s2i))
    );
    *this->currentOutput << '\t' << out << " " << comment << "\n";
    fmt::print("{}\n", comment);
}
void Emitter::generateCodeConst(std::string operation, size_t s1i, std::string constval2, std::string constval3, std::string comment)
{
    SymbolTable* st = SymbolTable::getDefault();
    char typeChar = st->at(s1i)->getVarType()==VarTypes::VT_INT?'i':'r';
    std::string out = fmt::format(
        "{}.{} {}, {}, {};", 
        operation, 
        typeChar, 
        this->getSymbolString(st->at(s1i)),
        constval2,
        constval3
    );
    *this->currentOutput << '\t' << out << " " << comment << "\n";
    fmt::print("{}\n", comment);
}
void Emitter::subFromZero(size_t s1i, size_t s2i) 
{
    SymbolTable* st = SymbolTable::getDefault();
    char typeChar = st->at(s1i)->getVarType()==VarTypes::VT_INT?'i':'r';
    std::string out = fmt::format(
        "sub.{} #0, {}, {};", 
        typeChar, 
        this->getSymbolString(st->at(s1i)),
        this->getSymbolString(st->at(s2i))
    );
    *this->currentOutput << '\t' << out << " " <<  "\n";
}
void Emitter::generateRaw(std::string raw)
{
    *this->currentOutput << raw << " " <<  "\n";
    fmt::print("{}\n", raw);
}
void Emitter::generateLabel(std::string lab)
{
    *this->currentOutput << lab << ":" <<  "\n";
}
void Emitter::generateJump(std::string to)
{
    *this->currentOutput << "\tjump.i #" << to <<  ";\n";
}
void Emitter::initialJump()
{
    SymbolTable *st = SymbolTable::getDefault();
    std::string label = fmt::format("lab{}",st->pushNextLabelIndex());
    this->generateJump(label);
}
void Emitter::beginProgram()
{
    fmt::print("Begin program\n");
    SymbolTable *st = SymbolTable::getDefault();
    this->generateLabel(fmt::format("lab{}", st->popLabelIndex()));
}
void Emitter::endProgram()
{
    this->outputFile << fmt::format("\texit;\n");
    this->outputFile.close();
}
void Emitter::setDefault()
{
    Emitter::instance = this;
}
void Emitter::enterTempOutput()
{
    this->currentOutput = &this->outputTemp;
}
void Emitter::exitTempOutput(size_t localStackSize, bool dumpToFile)
{
    this->generateEnterProcedure(localStackSize);
    this->outputFile << this->outputTemp.str();
    this->outputTemp.str(std::string()); // clear 
    this->currentOutput = &this->outputFile;
    this->generateProcedureReturn();
}
void Emitter::generateEnterProcedure(size_t size)
{
    this->outputFile << "\tenter.i #" << size << ";\n";
}
void Emitter::generateProcedureReturn()
{
    this->outputFile << "\tleave;\n";
    this->outputFile << "\treturn;\n";
}
void Emitter::generateTwoCodeInt(std::string operation, std::string target)
{
    *this->currentOutput << "\t" << operation << ".i #" << target << ";\n";
}
void Emitter::pushSymbolToStack(size_t symbolIndex)
{
    SymbolTable *st = SymbolTable::getDefault();
    std::string ref = this->getSymbolReferenceString(symbolIndex);
    *this->currentOutput << "\t" << "push.i " << ref << "; " << fmt::format("push {}", st->at(symbolIndex)->getDescriptor()) <<"\n";
}
