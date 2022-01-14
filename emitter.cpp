#include "emitter.hpp"
#include <fmt/format.h>

Emitter* Emitter::instance = nullptr;
Emitter::Emitter(std::string filename) :
    outputFile(filename, std::fstream::out | std::fstream::trunc)
{
    if (Emitter::instance == nullptr)
    {
        Emitter::instance = this;
    }
    this->currentOutput = &this->outputFile;
}
Emitter* Emitter::getDefault()
{
    return Emitter::instance;
}
std::string Emitter::getSymbolString(Symbol* s)
{
    if(s->getSymbolType()==SymbolTypes::ST_ID)
    {
        if(s->getIsReference()) {
            return fmt::format("*{}", s->getAddress());
        }
        else {
            return fmt::format("{}", s->getAddress());
        }
        
    }
    else if(s->getSymbolType()==SymbolTypes::ST_NUM)
    {
        return fmt::format("#{}", s->getAttribute());
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
    st->clearIdentifierList(); // idlist is filled with input output
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
size_t Emitter::pushIDListToStack()
{
    SymbolTable* st = SymbolTable::getDefault();
    const std::vector<size_t> &idList = st->getIDList();
    size_t stackSize = idList.size() * 4;
    for(auto i:idList)
    {
        this->generateTwoCodeInt("push", fmt::format("{}", st->at(i)->getAddress()));
    }
    st->clearIdentifierList();
    return stackSize;
}