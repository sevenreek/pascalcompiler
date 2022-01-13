#pragma once
#include <vector>
#include <string>
#include <fstream>
#include <sstream>
#include "symboltable.hpp"
std::string operatorTokenToString(address_t token);
class Emitter {
private:
    std::fstream outputFile;
    std::stringstream outputTemp;
    std::iostream * currentOutput;
    static Emitter * instance;
public:
    Emitter(std::string outputfile);
    static Emitter* getDefault();
    void generateCode(std::string operation, size_t s1, size_t s2, size_t s3, std::string comment);
    void generateCode(std::string operation, size_t s1, size_t s2, std::string comment);
    void generateCode(std::string operation, size_t s1, std::string comment);
    void generateCodeConst(std::string operation, size_t s1, std::string constval, size_t s3, std::string comment);
    void generateCodeConst(std::string operation, size_t s1, size_t s3, std::string constval, std::string comment);
    void generateCodeConst(std::string operation, std::string constval, size_t s2i, std::string comment);
    void generateCodeConst(std::string operation, size_t s1i, std::string constval2, std::string constval3, std::string comment);
    void generateRaw(std::string raw);
    void subFromZero(size_t s1, size_t s2);
    std::string getSymbolString(Symbol* s);
    void initialJump();
    void beginProgram();
    void endProgram();
    void setDefault();
    void generateLabel(std::string lab);
    void generateJump(std::string toLabel);
    void enterTempOutput();
    void exitTempOutput(bool dumpToFile=true);
};

