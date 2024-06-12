#ifndef _MGR_H_
#define _MGR_H_
#include "def.h"
#include "FF.h"
#include "Cluster.h"
#include "BoostInclude.h"
#include "ParamMgr.h"
namespace clustering
{
class Mgr
{
public:
    Mgr():
        _origin(), 
        _border()
    {

    }
    void readInFile (const std::string& reg_file);
    void writeFile  (const std::string& out_file);
    void setOrigin  (double x, double y) {_origin = std::make_pair(x, y);}
    void setBorder  (double x, double y) {_border = std::make_pair(x, y);}
    void addCluster (Cluster& c)         {_clusters.push_back(c);}
    FF_id addFF     (std::string& name, std::vector<double>& FF_info);
    
    void reset_FFs_with_stars(std::vector<FF_id>& FFs_with_star, double norm);
    void printFFs();
    void printClusterStats();

    FF&      getFF         (FF_id id)      {return _FFs[id];}
    Cluster& getCluster    (Cluster_id id) {return _clusters[id];}
    int      getFFSize     () const {return (int)_FFs.size();}
    int      getClusterSize() const {return (int)_clusters.size();}
    
    void     doMeanShiftClustering();    
    void     doStableMatching();
    void     calcFinalCoor();
public:
    void doClustering(std::vector<std::pair<int, FF_id> >& iterCnt);
    Coor getMedian   (FF& nowFF, Cluster& c,
                      std::vector<PointWithID>& resultFFs,
                      std::vector<PointWithID>& toRemoveFFs);
    void calcDisp(double& maxDisp, double& avgDisp, double& totDisp);
    double calcPowerRatio();
    void   organizeClusters();
private:
    Coor _origin;
    Coor _border;
    std::vector<FF> _FFs;
    std::vector<Cluster> _clusters;
public:
    static Mgr& getInstance()
    {
        static Mgr m;
        return m;
    } 
};

inline Mgr& getMgr() {return Mgr::getInstance();}
}
#endif
