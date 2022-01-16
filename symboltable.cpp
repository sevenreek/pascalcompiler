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
        case VarTypes::VT_NOTYPE:
            throw ParsingException(fmt::format("Tried obtaining size of <notype>"));
        break;
        default:
            throw ParsingException(fmt::format("Unknown VarType enum {}", t));
        break;
    }
    if(arraySize) memorySize*=arraySize;
    return memorySize;
}

std::string addressContextEnumToString(AddressContext ac) 
{
    switch(ac)
    {
        case AddressContext::AC_GLOBAL: return "global";
        case AddressContext::AC_FUNC: return "function";
        case AddressContext::AC_PROC: return "procedure";
    }
    return "<error-context>";
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
        throw ParsingException(fmt::format("Symbol {} is absent from the symbol table.", s));
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
        fmt::print(
            "Adding {} symbol '{}' at {}\n", 
            addressContextEnumToString(this->addressContext), 
            s, 
            this->symbols.size()
        );
        Symbol sym{s, SymbolTypes::ST_ID};
        sym.setLocal(this->addressContext);
        this->symbols.push_back(sym);
        return this->symbols.size()-1;
    }
}
size_t SymbolTable::insertSymbolIndex(std::string s)
{
    fmt::print(
        "Adding {} symbol '{}' at {}\n", 
        addressContextEnumToString(this->addressContext), 
        s, 
        this->symbols.size()
    );
    Symbol sym{s, SymbolTypes::ST_ID};
    sym.setLocal(this->addressContext);
    this->symbols.push_back(sym);
    return this->symbols.size()-1;
}
size_t SymbolTable::insertOrGetNumericalConstant(std::string s)
{
    size_t i = -1;
    if(this->tryGetSymbolIndex(s, i)) {
        return i;
        fmt::print("Returning numeric constant '{}' at {}\n", s, i);
    }
    else {
        fmt::print("Pushing numeric constant '{}' at {}\n",  s, this->symbols.size());
        Symbol sym{s, SymbolTypes::ST_NUM};
        sym.setLocal(this->addressContext);
        this->symbols.push_back(sym);
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
size_t SymbolTable::peekLabelIndex()
{   
    return this->labelStack.top();
}
size_t SymbolTable::getNewTemporaryVariable(VarTypes type, std::string descriptor)
{
    std::string name = fmt::format("$t{}", this->getNextGlobalTemporaryAndIncrement());
    address_t addr = this->getNextAddressAndIncrement(type);
    Symbol sym{name, SymbolTypes::ST_ID, type, addr};
    sym.setLocal(this->addressContext);
    this->symbols.push_back(sym);
    Symbol *ts = this->at(this->symbols.size()-1);
    if(descriptor.empty()) descriptor = name;
    ts->setDescriptor(descriptor);
    fmt::print(
        "Created new {} temporary {}({}) of type {} at {} @{}\n", 
        addressContextEnumToString(this->addressContext), 
        name, 
        ts->getDescriptor(), 
        varTypeEnumToString(type), 
        this->symbols.size()-1, 
        addr
    );
    return this->symbols.size()-1;
}
Symbol* SymbolTable::at(size_t index)
{
    return &this->symbols.at(index);
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
        throw ParsingException("Tried getting next argument address in global context.");
    }
    address_t retval = this->lastArgumentAddress;
    this->lastArgumentAddress += 4; // pointers are 4 bytes
    return retval;
}
size_t SymbolTable::contextualizeSymbol(size_t symbolIndex)
{
    Symbol* newSymbol = this->at(symbolIndex);
    fmt::print("\tContextualizing symbol {}.\n", newSymbol->getAttribute());
    if(newSymbol->isInMemory()) // variable was already placed in memory
    {
        if(newSymbol->isLocal() && this->getAddressContext()) { // trying to redeclare local?
            throw ParsingException(fmt::format("Local variable {} already declared.", newSymbol->getAttribute()));
        } else if(!newSymbol->isLocal() && !this->getAddressContext()) { // trying to declare global again
            throw ParsingException(fmt::format("Global variable {} already declared.", newSymbol->getAttribute()));
        } else if (!newSymbol->isLocal() && this->getAddressContext()) { // local scope shadowing global
            fmt::print("Variable {} shadowing global.\n", newSymbol->getAttribute());
            symbolIndex = this->insertSymbolIndex(newSymbol->getAttribute());
            newSymbol = this->at(symbolIndex);
            newSymbol->setLocal(true);
        }
    }
    this->contextualizedSymbolIndices.push_back(symbolIndex);
    return this->contextualizedSymbolIndices.size() - 1;
}
void SymbolTable::setNewContextVarType(VarTypes vartype) 
{
    for(size_t i = this->unsetContextTypePosition; i<this->contextualizedSymbolIndices.size(); i++)
    {
        size_t symIndex = this->contextualizedSymbolIndices.at(i);
        this->at(symIndex)->setVarType(vartype);
        size_t as = std::get<0>(this->arrayBounds);
        size_t ae = std::get<1>(this->arrayBounds);
        this->at(symIndex)->setArrayBounds({as,ae});
    }
    this->unsetContextTypePosition = this->contextualizedSymbolIndices.size();
}
void SymbolTable::placeContextInMemory(VarTypes vartype)
{

    for(size_t i = 0; i<this->contextualizedSymbolIndices.size(); i++) {
        size_t symIndex = this->contextualizedSymbolIndices[i];
        Symbol * sym = this->at(symIndex);
        sym->setVarType(vartype);
        size_t as = std::get<0>(this->arrayBounds);
        size_t ae = std::get<1>(this->arrayBounds);
        sym->setArrayBounds({as,ae});
        size_t arraySize = ((as==0)&&(ae==0))?0:(ae-as+1); // 0 if end and start are 0; 1 if they are both same value; end-start if they are different
        address_t addr = this->getNextAddressAndIncrement(sym->getVarType(), arraySize);
        if(arraySize) {
            fmt::print("\tPlacing array '{}[{}..{}]'({}) in memory @ {}.\n",
                sym->getDescriptor(),
                as, ae,
                varTypeEnumToString(vartype),
                addr
            );
        } else {
            fmt::print("\tPlacing symbol '{}'({}) in memory @ {}.\n",
                sym->getDescriptor(),
                varTypeEnumToString(vartype),
                addr
            );
        }
        sym->placeInMemory(addr);
    }
    this->contextualizedSymbolIndices.clear();
    this->unsetContextTypePosition = 0;
}
size_t SymbolTable::placeContextAsArguments(size_t functionIndex)
{
    for(size_t i = this->contextualizedSymbolIndices.size(); i-->0; ) {
        size_t symIndex = this->contextualizedSymbolIndices[i];
        Symbol * sym = this->at(symIndex);
        size_t as = std::get<0>(sym->getArrayBounds());
        size_t ae = std::get<1>(sym->getArrayBounds());
        size_t arraySize = ((as==0)&&(ae==0))?0:((ae-as)?(ae-as):1); // 0 if end and start are 0; 1 if they are both same value; end-start if they are different
        address_t addr = this->getNextArgumentAddress();
        if(arraySize) {
            fmt::print("\tPlacing array '{}[{}..{}]'({}) as argument @ {}.\n",
                sym->getDescriptor(),
                as, ae,
                varTypeEnumToString(sym->getVarType()),
                addr
            );
        } else {
            fmt::print("\tPlacing symbol '{}'({}) as argument @ {}.\n",
                sym->getDescriptor(),
                varTypeEnumToString(sym->getVarType()),
                addr
            );
        }
        sym->placeInMemory(addr);
        sym->setIsReference(true);
    }
    for(size_t i = 0; i<this->contextualizedSymbolIndices.size(); i++) {
        size_t symIndex = this->contextualizedSymbolIndices[i];
        Symbol * sym = this->at(symIndex);
        this->at(functionIndex)->addFuncArg(sym->getVarType());
    }
    size_t size = this->contextualizedSymbolIndices.size();
    this->contextualizedSymbolIndices.clear();
    this->unsetContextTypePosition = 0;
    return size;
}
void SymbolTable::enterLocalContext(size_t funcIndex)
{
    Symbol* f = this->at(funcIndex);
    if(this->addressContext) throw ParsingException("Already in procedure/function body.");
    if(f->getFuncType()==FunctionTypes::FP_FUNC) {
        this->addressContext = AddressContext::AC_FUNC;
        this->lastArgumentAddress = 12; // return value is BP+8
        this->activeFunctionContext = funcIndex;
    }
    else if(f->getFuncType()==FunctionTypes::FP_PROC){
        this->addressContext = AddressContext::AC_PROC;
        this->lastArgumentAddress = 8;
    }
    else {
        throw ParsingException(fmt::format("Tried entering local context with symbol {}", f->getDescriptor()));
    }
    this->lastLocalAddress = 0;
}
void SymbolTable::exitLocalContext()
{
    if(!this->addressContext) throw ParsingException("Already in global context.");
    this->addressContext = AddressContext::AC_GLOBAL;
    this->activeFunctionContext = -1;
    this->deleteLocals();
}
size_t SymbolTable::getLocalStackSize()
{
   return abs(this->lastLocalAddress);
}

AddressContext SymbolTable::getAddressContext() 
{
    return this->addressContext;
}
size_t SymbolTable::getActiveFunction()
{
    return this->activeFunctionContext;
}

void SymbolTable::pushToCallStack(size_t func)
{
    this->functionCallStack.push(func);
}
size_t SymbolTable::popFromCallStack()
{
    size_t ret = this->functionCallStack.top();
    this->functionCallStack.pop();
    return ret;
}
void SymbolTable::dumpContext()
{
    this->contextualizedSymbolIndices.clear();
}
void SymbolTable::deleteLocals()
{
    for(size_t i=this->symbols.size(); i-->0; ) 
    {
        if(this->symbols[i].isLocal())
            this->symbols.pop_back();
        else
            break;
    }
}