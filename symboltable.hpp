#pragma once
#include <vector>
#include <string>
#include <tuple>
#include <climits>
#include <stack>
#define address_t long
const address_t NO_ADDRESS = LONG_MAX;
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
enum FunctionTypes {
    FP_NONE = 0,
    FP_PROC = 1,
    FP_FUNC = 2
};
enum AddressContext {
    AC_GLOBAL = 0,
    AC_PROC = 1,
    AC_FUNC = 2
};
int varTypeToSize(VarTypes t, size_t arraySize=0);
class Symbol {
private:
    std::string attribute;
    std::string descriptor;
    SymbolTypes symbolType;
    VarTypes varType = VarTypes::VT_NOTYPE;
    FunctionTypes funcType = FunctionTypes::FP_NONE;
    std::tuple<size_t,size_t> arrayBounds = {0,0};
    address_t address = NO_ADDRESS;
    bool isReference = false;
    bool local = false;
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
    FunctionTypes getFuncType();
    void setFuncType(FunctionTypes ft);
    void setLocal(bool local);
    bool isLocal();
};


class SymbolTable {
private:
    address_t lastGlobalAddress = 0;
    address_t lastLocalAddress = 0;
    address_t lastArgumentAddress = 0;
    size_t nextGlobalTemporaryIndex = 0;
    size_t nextLabel = 0;
    std::vector<Symbol> symbols;
    static SymbolTable* instance;
    address_t getNextAddressAndIncrement(VarTypes type, size_t arraySize=0);
    size_t getNextGlobalTemporaryAndIncrement();
    address_t getNextArgumentAddress();
    std::vector<size_t> identifierListStack;
    std::tuple<size_t, size_t> arrayBounds = {0,0};
    std::stack<size_t> labelStack;
    AddressContext addressContext;
    size_t localVectorStartPos;
public:
    SymbolTable();
    ~SymbolTable();
    void setDefault();
    static SymbolTable* getDefault();
    bool tryGetSymbolIndex(std::string s, size_t& index);
    size_t getSymbolIndex(std::string s);
    size_t insertOrGetSymbolIndex(std::string s);
    size_t insertOrGetNumericalConstant(std::string s);
    size_t insertSymbolIndex(std::string s);
    size_t getNewTemporaryVariable(VarTypes type, std::string descriptor="");
    Symbol* at(size_t index);
    void addToIdentifierListStack(size_t index);
    void setMemoryIdentifierList(VarTypes type, bool empty=true);
    void clearIdentifierList();
    size_t getNextLabelIndex();
    size_t pushNextLabelIndex();
    size_t popLabelIndex();
    void setCurrentArraySize(std::tuple<size_t, size_t> bounds);
    std::tuple<size_t, size_t> getCurrentArraySize();
    bool isTypeArray();
    void enterLocalContext(bool hasReturnValue);
    void exitLocalContext();
    size_t getLocalStackSize();
    void idListToArguments(VarTypes type);


};
