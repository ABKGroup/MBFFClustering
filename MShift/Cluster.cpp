#include "Cluster.h"
#include "Mgr.h"
namespace clustering
{
bool Cluster::isFull() const 
{
    return (int)_FFs.size() >= getParamMgr().MaxClusterSize;
}
void Cluster::setID(Cluster_id cid) 
{
    for (int i = 0; i < (int)_FFs.size(); i++)
    {
        getMgr().getFF(_FFs[i]).setClusterID(cid);
    }
    _id = cid;
}
void Cluster::calcAndSetCoor()
{
    auto& m = getMgr();
    std::vector<double> median_x, median_y;
    median_x.reserve(_FFs.size());
    median_y.reserve(_FFs.size());
    for (int i = 0; i < (int)_FFs.size(); i++)
    {
        auto& f = m.getFF(_FFs[i]);
        median_x.push_back(f.getOrigX());
        median_y.push_back(f.getOrigY());
    }
    std::sort (median_x.begin(), median_x.end());
    std::sort (median_y.begin(), median_y.end());
    double x = median_x[(int) _FFs.size() / 2];
    double y = median_y[(int) _FFs.size() / 2];
    for (int i = 0; i < (int)_FFs.size(); i++)
    {
        auto& f = m.getFF(_FFs[i]);
        f.setCoor(x,y);
    }
    _coor.first = x;
    _coor.second = y;
}
}
