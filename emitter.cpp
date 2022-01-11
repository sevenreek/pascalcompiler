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
    this->outputFile << '\t' << out << " " << comment << "\n";
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
    this->outputFile << '\t' << out << " " << comment << "\n";
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
    this->outputFile << '\t' << out << " " << comment << "\n";
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
    this->outputFile << '\t' << out << " " << comment << "\n";
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
    this->outputFile << '\t' << out << " " << comment << "\n";
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
    this->outputFile << '\t' << out << " " << comment << "\n";
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
    this->outputFile << '\t' << out << " " << comment << "\n";
    fmt::print("{}\n", comment);
}
void Emitter::generateRaw(std::string raw)
{
    this->outputFile << raw << " " <<  "\n";
    fmt::print("{}\n", raw);
}
void Emitter::beginProgram()
{
    fmt::print("Begin program\n");
    SymbolTable *st = SymbolTable::getDefault();
    st->clearIdentifierList(); // idlist is filled with input output
    std::string label = fmt::format("lab{}",st->getNextLabelIndex());
    this->outputFile << fmt::format("\tjump.i #{};\n", label);
    this->outputFile << fmt::format("{}:\n", label);
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