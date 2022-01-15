#include "symbol.hpp"
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
void Symbol::setArrayBounds(std::tuple<size_t, size_t> bounds)
{
    this->arrayBounds = bounds;
}
bool Symbol::isInMemory()
{
    return (this->address != NO_ADDRESS) && (this->varType != VarTypes::VT_NOTYPE);
}
void Symbol::placeInMemory(address_t address)
{
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
bool Symbol::isArray()
{
    return (std::get<0>(this->arrayBounds) != 0) || (std::get<1>(this->arrayBounds) != 0);
}
void Symbol::setIsReference(bool ref)
{
    this->isReference = ref;
}
bool Symbol::getIsReference()
{
    return this->isReference;
}
void Symbol::setVarType(VarTypes vt)
{
    this->varType = vt;
}
std::tuple<size_t, size_t> Symbol::getArrayBounds()
{
    return this->arrayBounds;
}
FunctionTypes Symbol::getFuncType()
{
    return this->funcType;
}
void Symbol::setFuncType(FunctionTypes ft)
{
    this->funcType = ft;
}
void Symbol::setLocal(bool local)
{
    this->local = local;
}
bool Symbol::isLocal()
{
    return this->local;
}
void Symbol::setFuncArgs(std::vector<VarTypes> args) 
{
    this->funcArgs = args;
}
std::vector<VarTypes> &Symbol::getFuncArgs() 
{
    return this->funcArgs;
}
void Symbol::addFuncArg(VarTypes vt)
{
    this->funcArgs.push_back(vt);
}
VarTypes Symbol::getArgType(size_t index)
{
    if(index >= this->funcArgs.size()) {
        throw ParsingException(fmt::format("Too many arguments to call to {}.", this->getDescriptor()));
    }
    return this->funcArgs.at(index);
}
size_t Symbol::getArgCount() 
{
    return this->funcArgs.size();    
}
