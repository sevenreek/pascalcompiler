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
int varTypeToSize(VarTypes t, size_t arraySize)
{
    size_t memorySize = 4;
    switch(t)
    {
        case VarTypes::VT_INT:
            memorySize = 4;
        break;
        case VarTypes::VT_REAL:
            memorySize = 8;
        break;
        default:
            throw std::runtime_error(fmt::format("Unkown VarType enum {}", t));
        break;
    }
    if(arraySize) memorySize*=arraySize;
    return memorySize;
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
address_t SymbolTable::getNextAddressAndIncrement(VarTypes type, size_t arraySize)
{
    if(this->addressContext==AddressContext::AC_GLOBAL)
    {
        address_t returnValue = this->lastGlobalAddress;
        this->lastGlobalAddress += varTypeToSize(type, arraySize);
        return returnValue;
    }
    else 
    {
        this->lastLocalAddress -= varTypeToSize(type, arraySize);
        return this->lastLocalAddress;
    }
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
        if(this->at(i)->getAttribute() == s)
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
size_t SymbolTable::insertSymbolIndex(std::string s)
{
    fmt::print("Force pushing symbol '{}' at {}\n", s, this->symbols.size());
    this->symbols.push_back(Symbol(s, SymbolTypes::ST_ID));
    return this->symbols.size()-1;
}
size_t SymbolTable::insertOrGetNumericalConstant(std::string s)
{
    size_t i = -1;
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
    return this->nextGlobalTemporaryIndex++;
}
size_t SymbolTable::getNextLabelIndex()
{
    return this->nextLabel++;
}

size_t SymbolTable::pushNextLabelIndex()
{
    size_t index = this->nextLabel++;
    this->labelStack.push(index);
    return index;
}
size_t SymbolTable::popLabelIndex()
{   
    size_t index = this->labelStack.top();
    this->labelStack.pop();
    return index;
}
size_t SymbolTable::getNewTemporaryVariable(VarTypes type, std::string descriptor)
{
    std::string name = fmt::format("$t{}", this->getNextGlobalTemporaryAndIncrement());
    address_t addr = this->getNextAddressAndIncrement(type);
    this->symbols.push_back(Symbol(name, SymbolTypes::ST_ID, type, addr));
    Symbol *ts = this->at(this->symbols.size()-1);
    ts->setDescriptor(descriptor);
    fmt::print("Created new temporary {}({}) of type {} at {} @{}\n", name, ts->getDescriptor(), varTypeEnumToString(type), this->symbols.size()-1, addr);
    return this->symbols.size()-1;
}
Symbol* SymbolTable::at(size_t index)
{
    return &this->symbols.at(index);
}
void SymbolTable::addToIdentifierListStack(size_t ind)
{
    fmt::print("Added '{}'({}) to id list.\n", this->at(ind)->getAttribute(), ind);
    this->identifierListStack.push_back(ind);
}
void SymbolTable::clearIdentifierList()
{
    fmt::print("Cleared id list.\n");
    this->identifierListStack.clear();
}

void SymbolTable::setMemoryIdentifierList(VarTypes type, bool empty)
{
    size_t aStart = std::get<0>(this->arrayBounds);
    size_t aEnd = std::get<1>(this->arrayBounds);
    if(this->isTypeArray()) {
        fmt::print(
            "Pushing id list to memory with type {}[{}..{}]:\n", 
            varTypeEnumToString( type ), aStart, aEnd);
    }
    else {
        fmt::print("Pushing id list to memory with type {}:\n", varTypeEnumToString( type ));
    }
    for(auto i:this->identifierListStack)
    {
        if(this->isTypeArray()) {
            address_t addr = this->getNextAddressAndIncrement(type, aEnd-aStart+1); // maybe remove +1???
            fmt::print("\t'{}'({}) @{}\n", this->at(i)->getAttribute(), i, addr);
            this->at(i)->placeInMemory(type, addr);
            this->at(i)->setArrayBounds({aStart,aEnd});
        }
        else {
            address_t addr = this->getNextAddressAndIncrement(type); 
            fmt::print("\t'{}'({}) @{}\n", this->at(i)->getAttribute(), i, addr);
            this->at(i)->placeInMemory(type, addr);
        }
        
    }
    if(empty)
    {
        this->clearIdentifierList();
    }
}


void SymbolTable::setCurrentArraySize(std::tuple<size_t, size_t> bounds)
{
    this->arrayBounds = bounds;
}
std::tuple<size_t, size_t> SymbolTable::getCurrentArraySize()
{
    return this->arrayBounds;
}
bool SymbolTable::isTypeArray()
{
    return (std::get<0>(this->arrayBounds) != 0) || (std::get<1>(this->arrayBounds) != 0);
}

address_t SymbolTable::getNextArgumentAddress()
{
    if(!this->addressContext) // global context
    {
        throw std::runtime_error("Tried getting next argument address in global context.");
    }
    address_t retval = this->lastArgumentAddress;
    this->lastArgumentAddress += 4; // pointers are 4 bytes
    return retval;
}
void SymbolTable::idListToArguments(VarTypes type)
{
    size_t aStart = std::get<0>(this->arrayBounds);
    size_t aEnd = std::get<1>(this->arrayBounds);
    if(this->isTypeArray()) {
        fmt::print(
            "Pushing id list to arguments with type {}[{}..{}]:\n", 
            varTypeEnumToString( type ), aStart, aEnd);
    }
    else {
        fmt::print("Pushing id list to arguments with type {}:\n", varTypeEnumToString( type ));
    }
    for(size_t i = this->identifierListStack.size()-1; i>=0; i--)
    {
        address_t addr = this->getNextArgumentAddress();
        size_t index = i;
        if(this->at(index)->isInMemory()) { // shadowing global or you don goofed
            index = this->insertSymbolIndex(this->at(i)->getAttribute());
        }
        this->at(index)->placeInMemory(type, addr);
        this->at(index)->setArrayBounds({aStart,aEnd});
        this->at(index)->setIsReference(true);
        this->at(index)->setDescriptor(fmt::format("&{}", this->at(index)->getAttribute()));
        fmt::print("\t{} ({}) @{}\n", this->at(index)->getDescriptor(), varTypeEnumToString(this->at(index)->getVarType() ), addr );
        if(i == 0) break;
    }
    this->clearIdentifierList();
    
}
void SymbolTable::enterLocalContext(bool hasReturnValue)
{
    if(this->addressContext) throw std::runtime_error("Already in procedure/function body.");
    if(hasReturnValue) {
        this->addressContext = AddressContext::AC_FUNC;
        this->lastArgumentAddress = 12; // return value is BP+8
    }
    else {
        this->addressContext = AddressContext::AC_PROC;
        this->lastArgumentAddress = 8;
    }
    this->lastLocalAddress = 0;
}
void SymbolTable::exitLocalContext()
{
    if(!this->addressContext) throw std::runtime_error("Already in global context.");
    this->addressContext = AddressContext::AC_GLOBAL;
}
size_t SymbolTable::getLocalStackSize()
{
   return abs(this->lastLocalAddress);
}
const std::vector<size_t> & SymbolTable::getIDList()
{
    return this->identifierListStack;
}