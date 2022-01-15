#include <parsingexception.hpp>
ParsingException::ParsingException(const std::string &message) noexcept :
    m_message(message)
{
}

const char *ParsingException::what() const noexcept
{
    return this->m_message.c_str();
}