#include "StableMatching.h"
#include "ParamMgr.h"
#include "Mgr.h"
namespace clustering
{
StableMatching::StableMatching()
{
    auto& m = getMgr();
    std::vector<PointWithID> points;
    points.reserve(m.getClusterSize());
    for (int id = 0; id < m.getClusterSize(); id++)
    {
        points.emplace_back(std::make_pair(Point(m.getCluster(id).getX(),
                        m.getCluster(id).getY()), id));
    }
    _freeCnt = m.getFFSize();
    _rtree.insert(points.begin(), points.end());
    _isMatched.resize(m.getFFSize(), false);
    _clusters.resize (m.getFFSize());
    _FFs.resize(m.getClusterSize());
    for (int i = 0; i < m.getFFSize(); i++)
        _clusters[i].reserve(capacity);
}
bool StableMatching::run()
{
    auto& m = getMgr();
    std::vector<FF_id> order(m.getFFSize());
    for (int id = 0; id < m.getFFSize(); id++) 
        order[id] = id;
    calcClusters(order);
    while (_freeCnt > 0)
    {
        match(order);
    }
    bool hasEmptyCluster = checkEmptyCluster();
    return hasEmptyCluster;
}
bool StableMatching::checkEmptyCluster()
{
    auto& m = getMgr();
    int total = 0;
    bool hasEmptyCluster = false;
    for (Cluster_id cid = 0; cid < (int)_FFs.size(); cid ++)
    {
        for (auto it = _FFs[cid].begin(); it != _FFs[cid].end(); it ++)
        {
            FF_id fid = it->second;
            m.getFF(fid).setClusterID(cid);
            m.getCluster(cid).addFF(fid);
        }
        total += (int)_FFs[cid].size();
        if (_FFs[cid].empty()) hasEmptyCluster = true;
    }
    assert(total == m.getFFSize());
    return hasEmptyCluster;
}
void StableMatching::calcClusters(std::vector<FF_id>& order)
{
    auto& m = getMgr();
    #pragma omp parallel for num_threads(getParamMgr().ThreadNum)
    for (FF_id id = 0; id < m.getFFSize(); id ++)
    {
        FF& nowFF = m.getFF (id);
        std::vector<PointWithID> resultClusters;
        resultClusters.reserve (capacity);
        _rtree.query (bgi::nearest (Point (nowFF.getOrigX(), nowFF.getOrigY()), capacity),
        std::back_inserter (resultClusters));

        BOOST_FOREACH (PointWithID const & c, resultClusters)
        {
            mDist dis = ManhattanDistance (nowFF.getOrigCoor(), m.getCluster (c.second).getCoor());
            if (dis < getParamMgr().MaxDisp) _clusters[id].emplace_back (dis, c.second);
        }
        std::sort (_clusters[id].begin(), _clusters[id].end(),
                   std::less<std::pair<mDist, Cluster_id> >());
    }
    checkFFHasCluster();
    std::sort (order.begin(), order.end(),
               [&] (const FF_id & id1, const FF_id & id2)
    {
        return _clusters[id1].size() < _clusters[id2].size();
    });
}
void StableMatching::checkFFHasCluster()
{
    auto& m = getMgr();
    for (FF_id id = 0; id < m.getFFSize(); id ++)
    {
        if (_clusters[id].empty())
        {
           Cluster newC(m.getClusterSize());
           std::list<std::pair<mDist, FF_id> > tmpls;
           _clusters[id].emplace_back(0, newC.getID()); 
           _FFs.push_back(tmpls);
           m.addCluster(newC);
        }
    }
}
void StableMatching::addFF(Cluster_id cid, FF_id fid, mDist dis)
{
    if (_FFs[cid].empty()) 
    {
        _FFs[cid].emplace_front(dis, fid);
    }
    else if (_FFs[cid].back().first < dis)
    {
        _FFs[cid].emplace_back(dis, fid);
    }
    else
    {
        auto it = _FFs[cid].begin();
        while (it != _FFs[cid].end())
        {
            if (it->first >= dis) 
            {
                _FFs[cid].emplace(it, dis, fid);
                break;
            }
            it++;
        }
    }
}
bool StableMatching::prefersThisFF(Cluster_id cid, mDist dis)
{
    return _FFs[cid].back().first > dis;
}
void StableMatching::match(std::vector<FF_id>& order)
{
    //auto& m = getMgr();
    for (int i = 0; i < (int)order.size(); i++)
    {
        FF_id fid = order[i];
        if (_isMatched[fid]) continue;
        for (int j = 0; j < (int)_clusters[fid].size(); j++)
        {
            mDist      dis = _clusters[fid][j].first;
            Cluster_id cid = _clusters[fid][j].second;
            //Cluster& c = m.getCluster(cid);
            if ((int)_FFs[cid].size() >= getParamMgr().MaxClusterSize)
            {
                if (prefersThisFF(cid, dis))
                {
                    _isMatched[_FFs[cid].back().second] = false;
                    _FFs[cid].pop_back();
                    _isMatched[fid] = true;
                    addFF(cid, fid, dis);
                }
            }
            else
            {
                addFF(cid, fid, dis);
                _isMatched[fid] = true;
                _freeCnt --;
                break;
            }
            
        }
    }
}
}
