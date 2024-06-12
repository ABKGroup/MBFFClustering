#ifndef _CLUSTER_H_
#define _CLUSTER_H_
#include "def.h"
#include "ParamMgr.h"
namespace clustering
{

class Cluster
{
public:
    Cluster (Cluster_id id) : _id(id) {}
    Cluster_id  getID()      const   {return _id;}
    Coor&       getCoor()            {return _coor;}
    double      getX()       const   {return _coor.first;}
    double      getY()       const   {return _coor.second;}
    int         getFFSize()  const   {return (int)_FFs.size();}
    FF_id       getFF(int i) const   {return _FFs[i];}
    int         getSize()    const   {return (int)_FFs.size();}
    
    bool isFull ()           const; 
    bool empty  ()           const   {return _FFs.empty();}
    void addFF  (FF_id id)   {_FFs.push_back(id);}
    void setCoor(Coor& coor) {_coor = coor;}
    void clearFFs()          {_FFs.clear();}
    void setID   (Cluster_id cid);
    void calcAndSetCoor();
private:
    Cluster_id _id;
    Coor _coor;
    std::vector<FF_id> _FFs;
};


}
#endif
