#ifndef _PARSER_H_
#define _PARSER_H_
#pragma GCC system_header
#include "def.h"
#include "boost/tokenizer.hpp"
namespace clustering
{
class Parser
{
public:
    bool readInFile(const std::string& reg_file);
private:
    void readArea(std::ifstream& infile);
    void readRegisters(std::ifstream& infile);
    int  countTokenSize(boost::tokenizer<boost::char_separator<char> >& tok);
};

}
#endif
