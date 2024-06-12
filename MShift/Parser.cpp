#include "Parser.h"
#include "Mgr.h"
#include <fstream>
#include <stdlib.h>
#include <string.h>
#include <iomanip>
namespace clustering
{
bool Parser::readInFile(const std::string& reg_file)
{
    std::ifstream infile;
    infile.open(reg_file.c_str());
    if (!infile.good())
    {
        std::cout << "ERROR: failed opening file " << reg_file 
                  << std::endl;
        return false;
    }
    
    readArea(infile); 
    //Register Name X Y Max_Rise Max_fall
    std::string buffer;
    std::getline(infile, buffer);
    
    readRegisters(infile);
    infile.close();
    return true;
}
void Parser::readRegisters(std::ifstream& infile)
{
    std::string buffer;
    int line_cnt = 3; double norm = 0, slack = 0;
    std::vector<FF_id> FFs_with_star;
    while (std::getline(infile, buffer))
    {
        boost::char_separator<char> sep(" ");
        boost::tokenizer<boost::char_separator<char> > tok (buffer, sep);
        if (countTokenSize(tok) != 5) 
        {
            std::cout << "Something wrong with line " << line_cnt << "!" << std::endl;
            std::cout << "Exiting ..." << std::endl; 
            exit(-1);
        }
        bool has_star = false;
        auto iter = tok.begin();
        std::string name = (*(iter)).c_str();
        //x, y, maxRise, maxFall;
        std::vector<double> container(4, std::numeric_limits<double>::min());
        for (int i = 0; i < (int)container.size(); i++)
        {
            if (strcmp((*(++iter)).c_str(),"*") == 0) 
            {
                has_star = true;
                break;
            }
            else container[i] = std::atof((*(iter)).c_str());
        }
        if (!has_star) 
        {
            slack = std::min(container[2], container[3]);
            norm = std::max(norm, slack);
        }
        FF_id this_FF_id = getMgr().addFF(name, container);
        if (has_star) FFs_with_star.push_back(this_FF_id);
        line_cnt ++;
    }
    getMgr().reset_FFs_with_stars(FFs_with_star, norm);
}
void Parser::readArea(std::ifstream& infile)
{
    std::string buffer;
    std::getline (infile, buffer);

    boost::char_separator<char> sep(" ()");
    boost::tokenizer<boost::char_separator<char> > tok (buffer, sep);
    if (countTokenSize(tok) != 5) 
    {
        std::cout << "Something wrong with the first line!" << std::endl;
        std::cout << "Exiting ..." << std::endl; 
        exit(-1);
    }

    auto iter = tok.begin();
    double origin_x = std::atof((*(++iter)).c_str());
    double origin_y = std::atof((*(++iter)).c_str());
    double border_x = std::atof((*(++iter)).c_str());
    double border_y = std::atof((*(++iter)).c_str());
    getMgr().setOrigin(origin_x, origin_y);
    getMgr().setBorder(border_x, border_y);
}
int Parser::countTokenSize(boost::tokenizer<boost::char_separator<char> >& tok)
{
    int ret = 0;
    for (auto beg = tok.begin(); beg != tok.end(); ++beg) 
    {
        ret ++;
    }
    return ret;
}
}
