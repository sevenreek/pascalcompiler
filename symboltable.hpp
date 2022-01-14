#pragma once
#include <vector>
#include <string>
#include <stack>
#include "symbol.hpp"

std::string varTypeEnumToString(VarTypes t);
int varTypeToSize(VarTypes t, size_t arraySize=0);
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
    const std::vector<size_t> & getIDList();
};
