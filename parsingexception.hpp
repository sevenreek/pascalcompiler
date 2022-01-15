#include <string>

class ParsingException : public std::exception {
public: 
    ParsingException(const std::string &message) noexcept;
    virtual ~ParsingException() = default;
    virtual const char* what() const noexcept override;

private:
    int errorCode;
    std::string m_message;
};