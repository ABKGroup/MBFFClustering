#include <iostream>
#include <string>
#include "Mgr.h"
#include "ArgumentParser.h"
#include "ParamMgr.h"
int main()
{
    auto& paramMgr = clustering::getParamMgr();
    auto& mgr = clustering::getMgr();
    mgr.readInFile(paramMgr.reg_file);
    std::cout << "------------ Effective MeanShift -----------" << std::endl;
    mgr.doMeanShiftClustering();
    std::cout << "-------------- Stable Matching -------------" << std::endl;
    mgr.doStableMatching();
    mgr.calcFinalCoor();
    std::cout << "---------------- Statistics ----------------" << std::endl;
    mgr.printClusterStats();
    std::cout << "--------------------------------------------" << std::endl;
    mgr.writeFile(paramMgr.out_file);
}
