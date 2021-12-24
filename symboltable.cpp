#include "symboltable.hpp"
#include <fmt/format.h>
#include <exception>
std::string varTypeEnumToString(VarTypes t)
{
    switch(t)
    {
        case VarTypes::VT_NOTYPE:
            return "<NOTYPE>";
        case VarTypes::VT_INT:
            return "integer";
        case VarTypes::VT_REAL:
            return "real";
        default:
            return "<BADTYPE>";
    }
}
int varTypeToSize(VarTypes t)
{
    switch(t)
    {
        case VarTypes::VT_INT:
            return 4;
        break;
        case VarTypes::VT_REAL:
            return 8;
        break;
    }
    return 4;
}
Symbol::Symbol(std::string attr, SymbolTypes type) : attribute(attr), symbolType(type) 
{

}
Symbol::Symbol(std::string attr, SymbolTypes stype, VarTypes vtype): attribute(attr), symbolType(stype), varType(vtype)
{

}
Symbol::Symbol(std::string attr, SymbolTypes stype, VarTypes vtype, address_t address): attribute(attr), symbolType(stype), varType(vtype), address(address)
{

}
Symbol::~Symbol()
{

}
bool Symbol::isInMemory()
{
    return (this->address != NO_ADDRESS) && (this->varType != VarTypes::VT_NOTYPE);
}
void Symbol::placeInMemory(VarTypes type, address_t address)
{
    this->varType = type;
    this->address = address;
}
const std::string Symbol::getAttribute()
{
    return this->attribute;
}
address_t Symbol::getAddress()
{
    return this->address;
}
SymbolTypes Symbol::getSymbolType()
{
    return this->symbolType;
}
VarTypes Symbol::getVarType()
{
    return this->varType;
}
std::string Symbol::getDescriptor()
{
    if(this->descriptor.empty()){
        return this->attribute;
    }
    else {
        return this->descriptor;
    }
}
void Symbol::setDescriptor(std::string desc)
{
    this->descriptor = desc;
}


SymbolTable* SymbolTable::instance = nullptr;
SymbolTable::SymbolTable()
{

}
SymbolTable::~SymbolTable()
{

}
void SymbolTable::setDefault()
{
    SymbolTable::instance = this;
}
address_t SymbolTable::getGlobalAddressAndIncrement(VarTypes type)
{
    address_t returnValue = this->lastGlobalAddress;
    this->lastGlobalAddress += varTypeToSize(type);
    return returnValue;
}

SymbolTable* SymbolTable::getDefault()
{
    return SymbolTable::instance;
}
bool SymbolTable::tryGetSymbolIndex(std::string s, size_t& index)
{
    if(this->symbols.size() == 0) return false;
    for(size_t i = this->symbols.size()-1; i >= 0; i--)
    {
        if(this->at(i).getAttribute() == s)
        {
            index = i;
            return true;
        }
        if(i==0) break;
    }
    return false;
}
size_t SymbolTable::getSymbolIndex(std::string s)
{
    size_t i = -1;
    if(this->tryGetSymbolIndex(s, i)) {
        return i;
    }
    else {
        throw std::runtime_error(fmt::format("Symbol {} is absent from the symbol table.", s));
        return i;
    }

}
size_t SymbolTable::insertOrGetSymbolIndex(std::string s)
{
    size_t i = -1;
    if(this->tryGetSymbolIndex(s, i)) {
        return i;
        fmt::print("Returning symbol '{}' at {}\n", s, i);
    }
    else {
        fmt::print("Pushing symbol '{}' at {}\n", s, this->symbols.size());
        this->symbols.push_back(Symbol(s, SymbolTypes::ST_ID));
        return this->symbols.size()-1;
    }
}
size_t SymbolTable::insertOrGetNumericalConstant(std::string s)
{
    size_t i = -1;
    VarTypes type;
    if (s.find(".") != std::string::npos) {
        type = VarTypes::VT_REAL;
    }
    else {
        type = VarTypes::VT_INT;
    }

    if(this->tryGetSymbolIndex(s, i)) {
        return i;
        fmt::print("Returning numeric constant '{}' of type {} at {}\n", s, varTypeEnumToString(type), i);
    }
    else {
        fmt::print("Pushing numeric constant '{}' of type {} at {}\n", s, varTypeEnumToString(type), this->symbols.size());
        this->symbols.push_back(Symbol(s, SymbolTypes::ST_NUM, type));
        return this->symbols.size()-1;
    }
}
size_t SymbolTable::getNextGlobalTemporaryAndIncrement()
{
    return nextGlobalTemporaryIndex++;
}
size_t SymbolTable::getNewTemporaryVariable(VarTypes type, std::string descriptor)
{
    std::string name = fmt::format("$t{}", this->getNextGlobalTemporaryAndIncrement());
    address_t addr = this->getGlobalAddressAndIncrement(type);
    this->symbols.push_back(Symbol(name, SymbolTypes::ST_ID, type, addr));
    Symbol &ts = this->at(this->symbols.size()-1);
    ts.setDescriptor(descriptor);
    fmt::print("Created new temporary {}({}) of type {} at {} @{}\n", name, ts.getDescriptor(), varTypeEnumToString(type), this->symbols.size()-1, addr);
    return this->symbols.size()-1;
}
Symbol& SymbolTable::at(size_t index)
{
    return this->symbols.at(index);
}
void SymbolTable::addToIdentifierListStack(size_t ind)
{
    fmt::print("Added '{}'({}) to id list.\n", this->at(ind).getAttribute(), ind);
    this->identifierListStack.push_back(ind);
}
void SymbolTable::clearIdentifierList()
{
    fmt::print("Cleared id list.\n");
    this->identifierListStack.clear();
}

void SymbolTable::setMemoryIdentifierList(VarTypes type, bool empty)
{
    fmt::print("Pushing id list to memory with type {}:\n", varTypeEnumToString( type ));
    for(auto i:this->identifierListStack)
    {
        address_t addr = this->getGlobalAddressAndIncrement(type);
        fmt::print("\t'{}'({}) @{}\n", this->at(i).getAttribute(), i, addr);
        this->at(i).placeInMemory(type, addr);
    }
    if(empty)
    {
        this->clearIdentifierList();
    }
}
