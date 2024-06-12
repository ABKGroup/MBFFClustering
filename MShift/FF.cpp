#include "FF.h"
#include "Mgr.h"
#include <iomanip>
namespace clustering
{
void FF::print()
{
    std::cout << std::setw(50) << std::left << _name
              << std::setw(15) << std::right << _coor.first
              << std::setw(15) << std::right << _coor.second
              << std::setw(10) << std::right << _maxRise
              << std::setw(10) << std::right << _maxFall
              << std::endl;
}

void FF::sortNeighbors()
{
    std::sort(_neighbors.begin(), _neighbors.end(),
            [](const NeighborFF& ff1, const NeighborFF& ff2)
            {
                return ff1.second < ff2.second;
            });
}

void FF::setBandWidth()
{
    if (getNeighborSize() > getParamMgr().M) _h = _neighbors[getParamMgr().M].second;
    else _h = _neighbors.back().second;
    
    if (_h > getParamMgr().SqrMaxBandwidth) _h = getParamMgr().MaxBandwidth;
    else _h = std::sqrt(_h);
}

eDist FF::doShifting()
{
    double shift_x = 0;
    double shift_y = 0;
    double scale_factor = 0;
    for (int i = 0; i < (int)_neighbors.size();i++)
    {
        FF& n = getMgr().getFF(_neighbors[i].first);
        double h_i = n.getBandwidth();
        double weight = gaussian(_coor, n.getOrigCoor(), h_i);
        weight = weight / std::pow(h_i, 4);
        shift_x += n.getOrigX() * weight;
        shift_y += n.getOrigY() * weight;
        scale_factor += weight;
    }
    assert(std::isnormal(scale_factor));
    shift_x = shift_x/scale_factor;
    shift_y = shift_y/scale_factor;
    double ret = std::sqrt(std::pow(shift_x-getX(), 2)+
                           std::pow(shift_y-getY(), 2));
    setCoor(shift_x, shift_y);
    return ret; 
}   
}
