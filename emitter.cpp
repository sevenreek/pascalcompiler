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
std::string Emitter::getSymbolString(Symbol& s, bool isRef)
{
    if(s.getSymbolType()==SymbolTypes::ST_ID)
    {
        if(isRef) {
            return fmt::format("*{}", s.getAddress());
        }
        else {
            return fmt::format("{}", s.getAddress());
        }
        
    }
    else if(s.getSymbolType()==SymbolTypes::ST_NUM)
    {
        return fmt::format("#{}", s.getAttribute());
    }
    return "<ERROR>";
}

void Emitter::generateCode(std::string operation, size_t s1i, bool ref1, size_t s2i, bool ref2, size_t s3i, bool ref3, std::string comment)
{
    SymbolTable* st = SymbolTable::getDefault();
    char typeChar = st->at(s1i).getVarType()==VarTypes::VT_INT?'i':'r';
    std::string out = fmt::format(
        "{}.{} {}, {}, {};", 
        operation, 
        typeChar, 
        this->getSymbolString(st->at(s1i), ref1),
        this->getSymbolString(st->at(s2i), ref2),
        this->getSymbolString(st->at(s3i), ref3)
    );
    this->outputFile << '\t' << out << " " << comment << "\n";
    //fmt::print(out);
}
void Emitter::generateCode(std::string operation, size_t s1i, bool ref1, size_t s2i, bool ref2, std::string comment)
{
    SymbolTable* st = SymbolTable::getDefault();
    char typeChar = st->at(s1i).getVarType()==VarTypes::VT_INT?'i':'r';
    std::string out =  fmt::format(
        "{}.{} {}, {};", 
        operation, 
        typeChar, 
        this->getSymbolString(st->at(s1i), ref1),
        this->getSymbolString(st->at(s2i), ref2)
    );
    this->outputFile << '\t' << out << " " << comment << "\n";
    //fmt::print(out);
}
void Emitter::generateCode(std::string operation, size_t s1i, bool ref1, std::string comment)
{
    SymbolTable* st = SymbolTable::getDefault();
    char typeChar = st->at(s1i).getVarType()==VarTypes::VT_INT?'i':'r';
    std::string out =  fmt::format(
        "{}.{} {};", 
        operation, 
        typeChar, 
        this->getSymbolString(st->at(s1i), ref1)
    );
    this->outputFile << '\t' << out << " " << comment << "\n";
    //fmt::print(out);
}
void Emitter::beginProgram()
{
    fmt::print("Begin program\n");
    SymbolTable::getDefault()->clearIdentifierList(); // idlist is filled with input output
    this->outputFile << fmt::format("jump.i #main;\n");
    this->outputFile << fmt::format("main:\n");
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