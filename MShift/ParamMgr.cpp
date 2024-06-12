#include "ParamMgr.h"
namespace clustering
{
ParamMgr::ParamMgr():
    reg_file("input.txt"),
    out_file("output.txt"),
    M (10),
    K (140), 
    MaxClusterSize(16),
    ThreadNum(20),
    Tol (0.0001), 
    Epsilon(0.5), 
    MaxDisp(3e+5), 
    MaxBandwidth(1e+5) 
{
    SqrEpsilon = Epsilon * Epsilon;
    SqrMaxDisp = MaxDisp * MaxDisp;
    SqrMaxBandwidth = MaxBandwidth * MaxBandwidth;
}



}
