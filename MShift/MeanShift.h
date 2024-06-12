#ifndef _MEAN_SHIFT_H_
#define _MEAN_SHIFT_H_
#include "def.h"
#include "BoostInclude.h"
namespace clustering
{
class MeanShift
{
public:
    MeanShift();
    void run();
    std::vector<std::pair<int, FF_id> >& getIterCnt() {return _iterCnt;}
public: //public for unit test
    void buildRtree  ();
    void initKNNs    ();
    void shiftFFs    ();
    void getKNN      (FF_id id);
private:
    bgi::rtree<PointWithID, bgi::quadratic<P_PER_NODE> > _rtree;
    std::vector<std::pair<int, FF_id> > _iterCnt;
};
}
#endif
