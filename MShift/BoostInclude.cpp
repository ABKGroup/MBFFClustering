#include "BoostInclude.h"
namespace clustering
{
double SquareEuclideanDistance(const Coor& p1, const PointWithID& p2)
{
   return std::pow(p1.first  - bg::get<0>(p2.first), 2) +
          std::pow(p1.second - bg::get<1>(p2.first), 2); 
}
mDist ManhattanDistance(const Coor& p1, const PointWithID& p2)
{
    return std::abs((mDist)p1.first  - (mDist)bg::get<0>(p2.first)) +
           std::abs((mDist)p1.second - (mDist)bg::get<1>(p2.first));
}
}
