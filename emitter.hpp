#pragma once
#include <vector>
#include <string>
#include <fstream>
#include "symboltable.hpp"
std::string operatorTokenToString(address_t token);
class Emitter {
private:
    std::fstream outputFile;
    static Emitter * instance;
public:
    Emitter(std::string outputfile);
    static Emitter* getDefault();
    void generateCode(std::string operation, size_t s1, bool ref1, size_t s2, bool ref2, size_t s3, bool ref3, std::string comment="");
    void generateCode(std::string operation, size_t s1, bool ref1, size_t s2, bool ref2, std::string comment="");
    void generateCode(std::string operation, size_t s1, bool ref1, std::string comment="");
    void generateCodeConst(std::string operation, size_t s1, bool ref1, std::string constval, size_t s3, bool ref3, std::string comment="");
    std::string getSymbolString(Symbol* s, bool isRef);
    void beginProgram();
    void endProgram();
    void setDefault();
};

