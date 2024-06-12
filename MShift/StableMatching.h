#ifndef _STABLE_MATCHING_H_
#define _STABLE_MATCHING_H_
#include "def.h"
#include "BoostInclude.h"
#include <list>
namespace clustering
{
class StableMatching
{
    const int capacity = 1000;
public:
    StableMatching();
    bool run();
    void match(std::vector<FF_id>& order);
    void calcClusters(std::vector<FF_id>& order);
private:
    void addFF(Cluster_id cid, FF_id fid, mDist dis);
    bool prefersThisFF(Cluster_id cid, mDist dis);
    bool checkEmptyCluster();
    void checkFFHasCluster();
private:
    int _freeCnt;
    std::vector<bool>                                        _isMatched;
    std::vector<std::list<std::pair<mDist, FF_id> > >        _FFs;
    std::vector<std::vector<std::pair<mDist, Cluster_id> > > _clusters;
    RTree                                                    _rtree;
};
}
#endif
