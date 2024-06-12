#ifndef _FF_H_
#define _FF_H_
#include "def.h"
#include "ParamMgr.h"
namespace clustering
{

class FF
{
public:
    FF(FF_id id, std::string& name, Coor coor, 
       double maxRise, double maxFall, double slack):
        _id(id), _name(name), _coor(coor), 
        _maxRise(maxRise), _maxFall(maxFall), _slack(slack)
    {
        _cid = -1;
        _origCoor = coor;
        _h = 0;
        _isShifting = true;
    }
    FF_id  getID     ()const {return _id;}
    double getMaxRise()const {return _maxRise;}
    double getMaxFall()const {return _maxFall;}
    double getSlack  ()const {return _slack  ;}
    double getX      ()const {return _coor.first;}
    double getY      ()const {return _coor.second;}
    double getOrigX  ()const {return _origCoor.first;}
    double getOrigY  ()const {return _origCoor.second;} 
    bool   isShifting()const {return _isShifting;}
    double getBandwidth()const{return _h;}
    std::string& getName    () {return _name;}
    Coor&        getCoor    () {return _coor;} 
    Coor&        getOrigCoor() {return _origCoor;}
    Cluster_id   getCID     () {return _cid;}
    void setClusterID   (Cluster_id cid) {_cid = cid;}
    void setMaxRise     (double value)   {_maxRise = value;}
    void setMaxFall     (double value)   {_maxFall = value;}
    void setSlack       (double value)   {_slack   = value;}
    void setShifting    (bool b)         {_isShifting = b;}    
    void addNeighbor    (FF_id id, double dis) {_neighbors.emplace_back(id, dis);}
    void setCoor        (double x, double y)   {_coor.first = x; _coor.second = y;}
    void setCoor        (Coor& coor)           {_coor = coor;} 
    void sortNeighbors  ();
    void setBandWidth   ();
    int  getNeighborSize()const {return (int)_neighbors.size();}
    
    eDist       doShifting ();
    NeighborFF& getNeighbor(int i) {return _neighbors[i];}
    void print     ();
private:
    FF_id       _id;
    Cluster_id  _cid;
    std::string _name;
    Coor        _coor;
    Coor        _origCoor;
    double      _maxRise;
    double      _maxFall;
    double      _slack;
    double      _h;
    bool        _isShifting;
    std::vector<NeighborFF> _neighbors;
};


    
}
#endif
