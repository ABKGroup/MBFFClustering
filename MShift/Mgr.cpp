#include "Mgr.h"
#include "Parser.h"
#include "MeanShift.h"
#include "StableMatching.h"
#include <fstream>
#include <set>
#include <string>
namespace clustering
{
void Mgr::readInFile(const std::string& reg_file)
{
    Parser parser;
    if (!parser.readInFile(reg_file)) exit(-1);
}

FF_id Mgr::addFF(std::string& name, std::vector<double>& FF_info)
{
    FF_id ret = (int)_FFs.size();
    FF newFF(ret, name, std::make_pair(FF_info[0], FF_info[1]), 
            FF_info[2], FF_info[3], std::min(FF_info[2], FF_info[3]));
    _FFs.push_back(newFF);
    return ret;
}

void Mgr::reset_FFs_with_stars(std::vector<FF_id>& FFs_with_star, double norm)
{
    for (int i = 0; i < (int)FFs_with_star.size(); i++)
    {
        FF_id& id = FFs_with_star[i];
        _FFs[id].setMaxRise (norm);
        _FFs[id].setMaxFall (norm);
        _FFs[id].setSlack   (norm);
    }
}
void Mgr::printFFs()
{
    for (int i = 0; i < (int)_FFs.size(); i++)
    {
        _FFs[i].print();    
    }
}

void Mgr::doMeanShiftClustering()
{
    MeanShift ms;
    ms.run();
    doClustering(ms.getIterCnt());
}
Coor Mgr::getMedian(FF& nowFF, Cluster& c,
                    std::vector<PointWithID>& resultFFs,
                    std::vector<PointWithID>& toRemoveFFs)
{
    std::vector<double> median_x, median_y;
    BOOST_FOREACH (PointWithID const & p, resultFFs)
    {
        double dis = SquareEuclideanDistance (nowFF.getCoor(), p);
        if (dis < getParamMgr().SqrEpsilon)
        {
            median_x.push_back (_FFs[p.second].getOrigX());
            median_y.push_back (_FFs[p.second].getOrigY());
            toRemoveFFs.push_back (p);
            c.addFF (p.second);
        }
    }
    assert (!toRemoveFFs.empty()); //nowFF must be in it
    std::sort (median_x.begin(), median_x.end());
    std::sort (median_y.begin(), median_y.end());
    double x = median_x[(int) toRemoveFFs.size() / 2];
    double y = median_y[(int) toRemoveFFs.size() / 2];
    return std::make_pair(x, y);
}
void Mgr::doClustering(std::vector<std::pair<int, FF_id> >& iterCnt)
{
    std::vector<PointWithID> points;
    points.reserve(_FFs.size());
    for (int i = 0; i < (int)_FFs.size(); i++)
    {
        points.emplace_back (std::make_pair (Point (_FFs[i].getX(),_FFs[i].getY()), i));
    }
    bgi::rtree< PointWithID, bgi::quadratic<P_PER_NODE> > rtree;
    rtree.insert (points.begin(), points.end());
    std::vector<bool> isClustered (_FFs.size(), false);
    //for (FF_id id = 0; id < (int)_FFs.size(); id++)
    for (int index = 0; index < (int)iterCnt.size(); index ++)
    {
        FF_id id = iterCnt[index].second;
        if (isClustered[id]) {continue;}
        FF& nowFF = _FFs[id];
        Cluster c((int)_clusters.size());

        std::vector<PointWithID> resultFFs, toRemoveFFs;
        resultFFs.reserve(getParamMgr().MaxClusterSize);
        toRemoveFFs.reserve(getParamMgr().MaxClusterSize);
        rtree.query(bgi::nearest(Point(nowFF.getX(), nowFF.getY()), getParamMgr().MaxClusterSize), 
                           std::back_inserter(resultFFs));

        Coor clusterCoor = getMedian(nowFF, c, resultFFs, toRemoveFFs);
        c.setCoor (clusterCoor);
        for (int j = 0; j < (int)toRemoveFFs.size(); j++)
        {
            FF& toRemoveFF = _FFs[toRemoveFFs[j].second];
            isClustered[toRemoveFF.getID()] = true;
            toRemoveFF.setCoor(clusterCoor);
            toRemoveFF.setClusterID(c.getID());
        }
        rtree.remove (toRemoveFFs.begin(), toRemoveFFs.end());
        _clusters.push_back (c);
    }
}

void Mgr::writeFile(const std::string& out_file)
{
    std::fstream outfile(out_file, std::ios::out);
    outfile << "DIEAREA ( "
            << _origin.first << " " << _origin.second << " ) ( " 
            << _border.first << " " << _border.second << " )" << std::endl;
    outfile << std::setw(75) << std::left  << "name" 
            << std::setw(15) << std::right << "X" << std::setw(15) 
                                           << "Y" << std::setw(10) 
                                           << "LABEL" << std::endl;
    for (int i = 0; i < (int)_FFs.size(); i++)
    {
        outfile << std::setw(75) << std::left << _FFs[i].getName()
                << std::setw(15) << std::right << _FFs[i].getX() 
                << std::setw(15) << _FFs[i].getY() 
                << std::setw(10) << _FFs[i].getCID() << std::endl;
    } 
    outfile.close();
    
}
/*
void Mgr::writeFile(const std::string& out_file)
{
    std::fstream outfile(out_file, std::ios::out);
    outfile << "DIEAREA ( "
            << _origin.first << " " << _origin.second << " ) ( " 
            << _border.first << " " << _border.second << " )" << std::endl;
    outfile << "name " << "X " << "Y " << "LABEL" << std::endl;
    std::set<std::string> names;
    for (int i = 0; i < (int)_clusters.size(); i++)
    {
      
      for (int j = 0; j < (int)_clusters[i].getSize(); j++) {
        auto ff = getMgr().getFF(_clusters[i].getFF(j));
        if (names.count(ff.getName())) {
         continue;
        }
        names.insert(ff.getName());
        outfile << ff.getName()
                << " " << _clusters[i].getX() 
                << " " << _clusters[i].getY() 
                << " " << _clusters[i].getID() << std::endl;
      }
    } 
    outfile.close();
    
}
*/
void Mgr::doStableMatching()
{
    for (int i = 0; i < (int)_clusters.size(); i++) 
        _clusters[i].clearFFs();
    StableMatching sm;
    bool hasEmptyCluster = sm.run();
    if (hasEmptyCluster) organizeClusters();
}
void Mgr::organizeClusters()
{
    std::vector<Cluster> replace; replace.reserve(_clusters.size());
    for (int i = 0; i < (int)_clusters.size(); i++)
    {
        if (!_clusters[i].empty())
        {
            Cluster_id cid = (int)replace.size();
            replace.push_back(_clusters[i]);
            replace.back().setID(cid);
        }
    }
    _clusters = std::move(replace);
}
void Mgr::printClusterStats()
{
    using std::cout;
    using std::endl;
    int max_cluster_size = 0;
    int min_cluster_size = getParamMgr().MaxClusterSize;
    int counting = 0;
    int count80 = 0;
    double maxDisp = 0, avgDisp = 0, totDisp = 0;
    calcDisp(maxDisp, avgDisp, totDisp);
    for (int i = 0; i < (int)_clusters.size();i++)
    {
        max_cluster_size = std::max(max_cluster_size, _clusters[i].getSize());
        min_cluster_size = std::min(min_cluster_size, _clusters[i].getSize());
    
        if (_clusters[i].getSize() == 1) counting ++;
        if (_clusters[i].getSize() == getParamMgr().MaxClusterSize) count80 ++;
    }
    cout << "# clusters: " << _clusters.size() << endl;
    cout << "MAX cluster size: " <<max_cluster_size <<endl;
    cout << "MIN cluster size: " <<min_cluster_size << endl;
    cout << "clusters size is 1: " << counting << endl;
    cout << "clusters size is " << getParamMgr().MaxClusterSize << ": " << count80 << endl;
    cout << "total displacement: " << totDisp << endl;
    cout << "max displacement: " << maxDisp << endl;
    cout << "avg displacement: " << avgDisp << endl;
    cout << "power ratio: " << calcPowerRatio() << endl;
}
void Mgr::calcDisp(double& maxDisp, double& avgDisp, double& totDisp)
{
    maxDisp = 0;
    avgDisp = 0;
    totDisp = 0;
    for (int i = 0; i < (int)_FFs.size(); i++)
    {
        double disp = 0;
        disp += std::abs(_FFs[i].getX()-_FFs[i].getOrigX());
        disp += std::abs(_FFs[i].getY()-_FFs[i].getOrigY());

        maxDisp = std::max(maxDisp, disp);
        totDisp += disp;
    }
    avgDisp = totDisp / (double)_FFs.size();
}
double Mgr::calcPowerRatio()
{
    double ret = 0;
    for (int i = 0; i < (int)_clusters.size(); i++)
    {
        int size = _clusters[i].getSize();
        if      (size == 1)  ret += 1     * (double) size;
        else if (size <= 3)  ret += 0.86  * (double) size;
        else if (size <= 7)  ret += 0.79  * (double) size;
        else if (size <= 15) ret += 0.755 * (double) size;
        else if (size <= 31) ret += 0.738 * (double) size;
        else if (size <= 63) ret += 0.729 * (double) size;
        else if (size <= 80) ret += 0.724 * (double) size;
    }
    ret /= (double) _FFs.size();
    return ret;
}
void Mgr::calcFinalCoor()
{
    #pragma omp parallel for num_threads(getParamMgr().ThreadNum)
    for (int i = 0; i < (int)_clusters.size(); i++)
    {
        _clusters[i].calcAndSetCoor();
    }
}
}
