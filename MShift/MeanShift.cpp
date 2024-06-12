#include "MeanShift.h"
#include "Mgr.h"
#include "ParamMgr.h"
#include "FF.h"
namespace clustering
{
MeanShift::MeanShift()
{
    _iterCnt.resize(getMgr().getFFSize());
    for (int i = 0; i < (int)_iterCnt.size(); i++)
    {
        _iterCnt[i].second = i;
    }
}
void MeanShift::run()
{
    buildRtree();
    initKNNs();
    shiftFFs();
}
void MeanShift::buildRtree()
{
    auto& m = getMgr();
    std::vector<PointWithID> points;
    points.reserve(m.getFFSize());
    for (FF_id id = 0; id < m.getFFSize(); id++)
    {
        FF& f = m.getFF(id);
        points.emplace_back(std::make_pair(Point(f.getX(),f.getY()), id));
    }
    _rtree.insert(points.begin(), points.end());
}
void MeanShift::initKNNs()
{
    auto& m = getMgr();
    #pragma omp parallel for num_threads(getParamMgr().ThreadNum)
    for (FF_id id = 0; id < m.getFFSize(); id++)
    {
        FF& f = m.getFF(id);
        getKNN(id);
        if (f.getNeighborSize()==1)
        {
            f.setShifting(false);
        }
        else 
        {
            f.setBandWidth();
        }
    }
}
void MeanShift::getKNN(FF_id id)
{
    auto& m = getMgr();
    FF& f = m.getFF(id);
    std::vector<PointWithID> neighbors;
    neighbors.reserve(getParamMgr().K);
    _rtree.query(bgi::nearest(Point(f.getOrigX(), f.getOrigY()), getParamMgr().K), 
                              std::back_inserter(neighbors));
    BOOST_FOREACH(PointWithID const&p, neighbors)   
    {
        double dis = SquareEuclideanDistance(m.getFF(id).getOrigCoor(),
                                             m.getFF(p.second).getOrigCoor());
        if (dis < getParamMgr().SqrMaxDisp) f.addNeighbor(p.second, dis);
    }
    f.sortNeighbors();
}
void MeanShift::shiftFFs()
{
    auto& m = getMgr();
    #pragma omp parallel for num_threads(getParamMgr().ThreadNum)
    for (int i = 0; i < m.getFFSize(); i++)
    {
        FF& nowFF = m.getFF(i);
        if (!nowFF.isShifting()) 
        {
            _iterCnt[nowFF.getID()].first = 0;
            continue;
        }
        int iter = 0;
        while (++iter)
        {
            eDist dis = nowFF.doShifting();
            if (dis <= getParamMgr().Tol)
            {
                nowFF.setShifting (false);
                _iterCnt[nowFF.getID()].first = iter;
                break;
            }
        }
    }
    std::sort (_iterCnt.begin(), _iterCnt.end(), 
               std::less<std::pair<int, FF_id> >());
}
}
