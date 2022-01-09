#pragma once
#include <vector>
#include <string>
#include <tuple>
#define address_t unsigned long
const size_t NO_ADDRESS = -1;
enum VarTypes {
    VT_NOTYPE = 0,
    VT_INT = 1,
    VT_REAL = 2
};
std::string varTypeEnumToString(VarTypes t);
enum SymbolTypes {
    ST_NUM = 0,
    ST_ID = 1
};
int varTypeToSize(VarTypes t, size_t arraySize=0);
class Symbol {
private:
    std::string attribute;
    std::string descriptor;
    SymbolTypes symbolType;
    VarTypes varType = VarTypes::VT_NOTYPE;
    std::tuple<size_t,size_t> arrayBounds = {0,0};
    address_t address = NO_ADDRESS;
    bool isReference = false;
public:
    Symbol(std::string attr, SymbolTypes type);
    Symbol(std::string attr, SymbolTypes type, VarTypes vtype);
    Symbol(std::string attr, SymbolTypes stype, VarTypes vtype, address_t address);
    ~Symbol();
    const std::string getAttribute();
    address_t getAddress();
    SymbolTypes getSymbolType();
    VarTypes getVarType();
    void setVarType(VarTypes vt);
    void placeInMemory(VarTypes type, address_t address);
    bool isInMemory();
    std::string getDescriptor();
    void setDescriptor(std::string desc);
    bool isArray();
    std::tuple<size_t, size_t> getArrayBounds();
    void setArrayBounds(std::tuple<size_t, size_t> bounds);
    void setIsReference(bool ref);
    bool getIsReference();
};


class SymbolTable {
private:
    address_t lastGlobalAddress = 0;
    size_t nextGlobalTemporaryIndex = 0;
    size_t nextLabel = 0;
    std::vector<Symbol> symbols;
    static SymbolTable* instance;
    address_t getGlobalAddressAndIncrement(VarTypes type, size_t arraySize=0);
    size_t getNextGlobalTemporaryAndIncrement();
    std::vector<size_t> identifierListStack;
    std::tuple<size_t, size_t> arrayBounds = {0,0};
public:
    SymbolTable();
    ~SymbolTable();
    void setDefault();
    static SymbolTable* getDefault();
    bool tryGetSymbolIndex(std::string s, size_t& index);
    size_t getSymbolIndex(std::string s);
    size_t insertOrGetSymbolIndex(std::string s);
    size_t insertOrGetNumericalConstant(std::string s);
    size_t getNewTemporaryVariable(VarTypes type, std::string descriptor="");
    Symbol* at(size_t index);
    void addToIdentifierListStack(size_t index);
    void setMemoryIdentifierList(VarTypes type, bool empty=true);
    void clearIdentifierList();
    size_t getNextLabelIndex();
    void setCurrentArraySize(std::tuple<size_t, size_t> bounds);
    std::tuple<size_t, size_t> getCurrentArraySize();
    bool isTypeArray();

};
