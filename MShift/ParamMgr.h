#ifndef _PARAM_MGR_H_
#define _PARAM_MGR_H_
#include <string>
#include <iostream>
namespace clustering
{
class ParamMgr
{

public:
    ParamMgr();
    std::string reg_file;
    std::string out_file;
    int M;
    int K;
    int MaxClusterSize;
    int ThreadNum;
    double Tol;
    double Epsilon;
    double SqrEpsilon;
    double MaxDisp;
    double SqrMaxDisp;
    double MaxBandwidth;
    double SqrMaxBandwidth;
public:
    static ParamMgr& getInstance()
    {
        static ParamMgr paramMgr;
        return paramMgr;
    }
};
inline ParamMgr& getParamMgr() {return ParamMgr::getInstance();}
}
#endif
