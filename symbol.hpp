#pragma once
#include <climits>
#include <string>
#include <tuple>
#include <fmt/format.h>
#include <vector>
#define address_t long
const address_t NO_ADDRESS = LONG_MAX;
enum VarTypes {
    VT_NOTYPE = 0,
    VT_INT = 1,
    VT_REAL = 2
};

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
    std::vector<VarTypes> funcArgs;
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
    void placeInMemory(address_t address);
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
    void setFuncArgs(std::vector<VarTypes> args);
    void addFuncArg(VarTypes vt);
    std::vector<VarTypes> &getFuncArgs();
    VarTypes getArgType(size_t index);
    size_t getArgCount();
};