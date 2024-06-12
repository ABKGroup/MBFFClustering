#ifndef _ARGUMENT_PARSER_H_
#define _ARGUMENT_PARSER_H_

#pragma GCC system_header
#include <boost/program_options.hpp>

namespace po = boost::program_options;
bool parseArguments(int argc, char* argv[]);
void showConfigs();
void parseGeneric(po::options_description& generic);
void parseConfig(po::options_description& config);
void parseHidden(po::options_description& hidden);
void showConfig();
#endif
